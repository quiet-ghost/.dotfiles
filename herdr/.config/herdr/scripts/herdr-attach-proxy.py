#!/usr/bin/env python3
"""Relay a Herdr direct attachment, translating Alt+d into detach."""

from __future__ import annotations

import argparse
import errno
import fcntl
import json
import os
import pty
import select
import signal
import subprocess
import sys
import termios
import threading
import time
import tty
from collections.abc import Callable, Sequence
from typing import Any

DETACH = b"\x02q"
# Seconds to wait before forwarding an incomplete escape sequence.
ESCAPE_TIMEOUT = 0.01
AGENT_CHECK_INTERVAL = 0.4
# Legacy and Kitty keyboard protocol encodings for Alt+d.
ALT_D_SEQUENCES = (
    b"\x1bd",
    b"\x1b[100;3u",
    b"\x1b[100;3:1u",
)


class AltDTranslator:
    def __init__(self) -> None:
        self.pending = bytearray()
        self.pending_since: float | None = None

    def feed(self, data: bytes, now: float) -> bytes:
        self.pending.extend(data)
        if self.pending and self.pending_since is None:
            self.pending_since = now
        return self._drain(force=False)

    def flush_expired(self, now: float) -> bytes:
        if self.pending_since is None or now - self.pending_since < ESCAPE_TIMEOUT:
            return b""
        return self._drain(force=True)

    def flush(self) -> bytes:
        return self._drain(force=True)

    def timeout(self, now: float) -> float | None:
        if self.pending_since is None:
            return None
        return max(0.0, ESCAPE_TIMEOUT - (now - self.pending_since))

    def _drain(self, *, force: bool) -> bytes:
        output = bytearray()
        while self.pending:
            match = next(
                (sequence for sequence in ALT_D_SEQUENCES if self.pending.startswith(sequence)),
                None,
            )
            if match is not None:
                del self.pending[: len(match)]
                output.extend(DETACH)
                self.pending_since = time.monotonic() if self.pending else None
                continue

            is_prefix = any(sequence.startswith(self.pending) for sequence in ALT_D_SEQUENCES)
            if is_prefix and not force:
                break

            output.append(self.pending.pop(0))
            self.pending_since = time.monotonic() if self.pending else None

        return bytes(output)


def write_all(fd: int, data: bytes) -> None:
    while data:
        written = os.write(fd, data)
        data = data[written:]


def copy_window_size(source_fd: int, target_fd: int) -> None:
    size = fcntl.ioctl(source_fd, termios.TIOCGWINSZ, b"\0" * 8)
    fcntl.ioctl(target_fd, termios.TIOCSWINSZ, size)


def exit_code(status: int) -> int:
    if os.WIFEXITED(status):
        return os.WEXITSTATUS(status)
    if os.WIFSIGNALED(status):
        return 128 + os.WTERMSIG(status)
    return 1


def relay(command: Sequence[str], agent_alive: Callable[[], bool]) -> tuple[int, bool]:
    """Run command in a PTY and relay its terminal stream."""
    stdin_fd = sys.stdin.fileno()
    stdout_fd = sys.stdout.fileno()
    if not os.isatty(stdin_fd) or not os.isatty(stdout_fd):
        print("herdr-attach-proxy: stdin and stdout must be terminals", file=sys.stderr)
        return 2

    original_attrs = termios.tcgetattr(stdin_fd)
    child_pid, master_fd = pty.fork()
    if child_pid == 0:
        os.execvp(command[0], list(command))

    child_status: int | None = None
    resize_pending = True
    terminate_signal: int | None = None
    wakeup_read_fd, wakeup_write_fd = os.pipe2(os.O_NONBLOCK | os.O_CLOEXEC)

    def request_resize(_signum: int, _frame: object) -> None:
        nonlocal resize_pending
        resize_pending = True

    def request_termination(signum: int, _frame: object) -> None:
        nonlocal terminate_signal
        terminate_signal = signum

    previous_wakeup_fd = signal.set_wakeup_fd(wakeup_write_fd)
    previous_handlers = {
        signal.SIGWINCH: signal.signal(signal.SIGWINCH, request_resize),
        signal.SIGHUP: signal.signal(signal.SIGHUP, request_termination),
        signal.SIGTERM: signal.signal(signal.SIGTERM, request_termination),
    }
    translator = AltDTranslator()
    agent_detach_sent = False
    agent_gone = False
    monitor_stop = threading.Event()

    def monitor_agent() -> None:
        nonlocal agent_gone
        while not monitor_stop.wait(AGENT_CHECK_INTERVAL):
            try:
                alive = agent_alive()
            except (OSError, RuntimeError, subprocess.SubprocessError):
                continue
            if alive:
                continue
            agent_gone = True
            try:
                os.write(wakeup_write_fd, b"\0")
            except OSError:
                pass
            return

    monitor = threading.Thread(target=monitor_agent, daemon=True)
    monitor.start()

    try:
        tty.setraw(stdin_fd, termios.TCSANOW)
        while child_status is None:
            if resize_pending:
                copy_window_size(stdin_fd, master_fd)
                os.kill(child_pid, signal.SIGWINCH)
                resize_pending = False

            if terminate_signal is not None:
                os.kill(child_pid, terminate_signal)
                terminate_signal = None

            now = time.monotonic()
            escape_timeout = translator.timeout(now)
            readable, _, _ = select.select(
                [stdin_fd, master_fd, wakeup_read_fd], [], [], escape_timeout
            )

            if wakeup_read_fd in readable:
                try:
                    os.read(wakeup_read_fd, 4096)
                except BlockingIOError:
                    pass

            if stdin_fd in readable:
                data = os.read(stdin_fd, 4096)
                if not data:
                    buffered = translator.flush()
                    if buffered:
                        write_all(master_fd, buffered)
                else:
                    translated = translator.feed(data, time.monotonic())
                    if translated:
                        write_all(master_fd, translated)

            expired = translator.flush_expired(time.monotonic())
            if expired:
                write_all(master_fd, expired)

            if agent_gone and not agent_detach_sent:
                write_all(master_fd, DETACH)
                agent_detach_sent = True

            if master_fd in readable:
                try:
                    output = os.read(master_fd, 65536)
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
                    output = b""
                if output:
                    write_all(stdout_fd, output)

            waited_pid, status = os.waitpid(child_pid, os.WNOHANG)
            if waited_pid == child_pid:
                child_status = status
    finally:
        monitor_stop.set()
        termios.tcsetattr(stdin_fd, termios.TCSADRAIN, original_attrs)
        monitor.join(timeout=0.75)
        for signum, handler in previous_handlers.items():
            signal.signal(signum, handler)
        signal.set_wakeup_fd(previous_wakeup_fd)
        os.close(wakeup_read_fd)
        os.close(wakeup_write_fd)
        os.close(master_fd)

        if child_status is None:
            try:
                os.kill(child_pid, signal.SIGHUP)
            except ProcessLookupError:
                pass
            _, child_status = os.waitpid(child_pid, 0)

    return exit_code(child_status), agent_gone


def agent_info(herdr: str, target: str) -> dict[str, Any] | None:
    result = subprocess.run(
        (herdr, "agent", "get", target),
        capture_output=True,
        check=False,
        text=True,
        timeout=0.5,
    )
    payload = result.stdout if result.stdout.strip() else result.stderr
    try:
        response = json.loads(payload)
    except json.JSONDecodeError as error:
        raise RuntimeError("herdr agent lookup returned invalid JSON") from error

    if not isinstance(response, dict):
        raise RuntimeError("herdr agent lookup returned invalid data")

    if result.returncode == 0:
        response_result = response.get("result")
        if not isinstance(response_result, dict):
            raise RuntimeError("herdr agent lookup omitted result data")
        info = response_result.get("agent")
        if isinstance(info, dict):
            return info
        raise RuntimeError("herdr agent lookup omitted agent data")

    response_error = response.get("error")
    if not isinstance(response_error, dict):
        raise RuntimeError("herdr agent lookup omitted error data")
    if response_error.get("code") == "agent_not_found":
        return None
    raise RuntimeError(response_error.get("message", "herdr agent lookup failed"))


def tab_has_agent(herdr: str, tab_id: str) -> bool:
    try:
        result = subprocess.run(
            (herdr, "agent", "list"),
            capture_output=True,
            check=False,
            text=True,
            timeout=2,
        )
        response = json.loads(result.stdout)
        if not isinstance(response, dict):
            return True
        response_result = response.get("result")
        if not isinstance(response_result, dict):
            return True
        agents = response_result.get("agents", [])
        return result.returncode != 0 or not isinstance(agents, list) or any(
            isinstance(agent, dict) and agent.get("tab_id") == tab_id
            for agent in agents
        )
    except (OSError, json.JSONDecodeError, subprocess.SubprocessError):
        return True


def close_tab(herdr: str, tab_id: str) -> None:
    try:
        result = subprocess.run(
            (herdr, "tab", "close", tab_id),
            capture_output=True,
            check=False,
            text=True,
            timeout=2,
        )
    except (OSError, subprocess.SubprocessError):
        result = None
    if result is None or result.returncode != 0:
        print(
            f"herdr-attach-proxy: agent exited, but tab {tab_id} could not close",
            file=sys.stderr,
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Attach to a Herdr agent; Alt+d detaches the viewer."
    )
    parser.add_argument("target", help="Herdr agent name or pane target")
    parser.add_argument("--herdr", default=os.environ.get("HERDR_BIN_PATH", "herdr"))
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        initial_info = agent_info(args.herdr, args.target)
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"herdr-attach-proxy: agent lookup failed: {error}", file=sys.stderr)
        return 1
    if initial_info is None:
        print(f"herdr-attach-proxy: agent not found: {args.target}", file=sys.stderr)
        return 1

    tab_id = initial_info.get("tab_id")
    if not isinstance(tab_id, str) or not tab_id:
        print("herdr-attach-proxy: agent lookup omitted tab ID", file=sys.stderr)
        return 1

    def is_agent_alive() -> bool:
        return agent_info(args.herdr, args.target) is not None

    code, observed_agent_exit = relay(
        (args.herdr, "agent", "attach", args.target, "--takeover"),
        is_agent_alive,
    )

    try:
        exited = observed_agent_exit or agent_info(args.herdr, args.target) is None
    except (OSError, RuntimeError, subprocess.SubprocessError):
        exited = observed_agent_exit
    if exited and not tab_has_agent(args.herdr, tab_id):
        close_tab(args.herdr, tab_id)

    return code


if __name__ == "__main__":
    raise SystemExit(main())
