#!/usr/bin/env python3
"""Relay a Herdr direct attachment with popup detach shortcuts."""

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
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

DETACH = b"\x02q"
# Seconds to wait before forwarding an incomplete escape sequence.
ESCAPE_TIMEOUT = 0.01
HOST_CHECK_INTERVAL = 0.2
MAX_LOG_BYTES = 256 * 1024
LOG_PATH = Path(
    os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))
) / "herdr/attach-proxy.log"
# Legacy and Kitty keyboard protocol encodings for Alt+d.
DETACH_SEQUENCES = (
    b"\x1bd",
    b"\x1b[100;3u",
    b"\x1b[100;3:1u",
)


class DetachTranslator:
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
                (sequence for sequence in DETACH_SEQUENCES if self.pending.startswith(sequence)),
                None,
            )
            if match is not None:
                del self.pending[: len(match)]
                output.extend(DETACH)
                self.pending_since = time.monotonic() if self.pending else None
                continue

            is_prefix = any(sequence.startswith(self.pending) for sequence in DETACH_SEQUENCES)
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


def termination_action(signum: int) -> str:
    return "detach" if signum == signal.SIGHUP else "forward"


def signal_name(signum: int) -> str:
    try:
        return signal.Signals(signum).name.lower()
    except ValueError:
        return str(signum)


def log_event(event: str, **fields: object) -> None:
    try:
        LOG_PATH.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        payload = {
            "timestamp": datetime.now(UTC).isoformat(),
            "event": event,
            **fields,
        }
        fd = os.open(
            LOG_PATH,
            os.O_WRONLY | os.O_CREAT | os.O_APPEND | os.O_CLOEXEC,
            0o600,
        )
        try:
            os.fchmod(fd, 0o600)
            if os.fstat(fd).st_size >= MAX_LOG_BYTES:
                os.ftruncate(fd, 0)
            os.write(fd, (json.dumps(payload, separators=(",", ":")) + "\n").encode())
        finally:
            os.close(fd)
    except OSError:
        pass


def relay(command: Sequence[str], host_alive: Callable[[], bool]) -> tuple[int, bool]:
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
    log_event("attach_started", proxy_pid=os.getpid(), child_pid=child_pid)

    child_status: int | None = None
    resize_pending = True
    terminate_signal: int | None = None
    detach_reason: str | None = None
    stdin_open = True
    stdout_open = True
    wakeup_read_fd, wakeup_write_fd = os.pipe2(os.O_NONBLOCK | os.O_CLOEXEC)

    def request_resize(_signum: int, _frame: object) -> None:
        nonlocal resize_pending
        resize_pending = True

    def request_termination(signum: int, _frame: object) -> None:
        nonlocal detach_reason, terminate_signal
        if termination_action(signum) == "detach":
            detach_reason = signal_name(signum)
        else:
            terminate_signal = signum

    previous_wakeup_fd = signal.set_wakeup_fd(wakeup_write_fd)
    previous_handlers = {
        signal.SIGWINCH: signal.signal(signal.SIGWINCH, request_resize),
        signal.SIGHUP: signal.signal(signal.SIGHUP, request_termination),
        signal.SIGTERM: signal.signal(signal.SIGTERM, request_termination),
    }
    translator = DetachTranslator()
    agent_detach_sent = False
    host_gone = False
    monitor_stop = threading.Event()

    def monitor_host() -> None:
        nonlocal host_gone
        while not monitor_stop.wait(HOST_CHECK_INTERVAL):
            try:
                alive = host_alive()
            except (OSError, RuntimeError, subprocess.SubprocessError):
                continue
            if alive:
                continue
            host_gone = True
            log_event("host_process_gone", proxy_pid=os.getpid(), child_pid=child_pid)
            try:
                os.write(wakeup_write_fd, b"\0")
            except OSError:
                pass
            return

    monitor = threading.Thread(target=monitor_host, daemon=True)
    monitor.start()

    try:
        tty.setraw(stdin_fd, termios.TCSANOW)
        while child_status is None:
            if resize_pending:
                copy_window_size(stdin_fd, master_fd)
                os.kill(child_pid, signal.SIGWINCH)
                resize_pending = False

            if terminate_signal is not None:
                log_event(
                    "signal_forwarded",
                    proxy_pid=os.getpid(),
                    child_pid=child_pid,
                    signal=signal_name(terminate_signal),
                )
                os.kill(child_pid, terminate_signal)
                terminate_signal = None

            if host_gone:
                detach_reason = detach_reason or "host_process_gone"

            if detach_reason is not None and not agent_detach_sent:
                write_all(master_fd, DETACH)
                agent_detach_sent = True
                log_event(
                    "detach_sent",
                    proxy_pid=os.getpid(),
                    child_pid=child_pid,
                    reason=detach_reason,
                )

            now = time.monotonic()
            escape_timeout = translator.timeout(now)
            read_fds = [master_fd, wakeup_read_fd]
            if stdin_open:
                read_fds.append(stdin_fd)
            readable, _, _ = select.select(read_fds, [], [], escape_timeout)

            if wakeup_read_fd in readable:
                try:
                    os.read(wakeup_read_fd, 4096)
                except BlockingIOError:
                    pass

            if stdin_fd in readable:
                try:
                    data = os.read(stdin_fd, 4096)
                except OSError as error:
                    if error.errno not in (errno.EIO, errno.EBADF):
                        raise
                    data = b""
                if not data:
                    buffered = translator.flush()
                    if buffered:
                        write_all(master_fd, buffered)
                    stdin_open = False
                    detach_reason = detach_reason or "stdin_eof"
                else:
                    translated = translator.feed(data, time.monotonic())
                    if translated:
                        write_all(master_fd, translated)

            expired = translator.flush_expired(time.monotonic())
            if expired:
                write_all(master_fd, expired)

            if master_fd in readable:
                try:
                    output = os.read(master_fd, 65536)
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
                    output = b""
                if output:
                    try:
                        if stdout_open:
                            write_all(stdout_fd, output)
                    except OSError as error:
                        if error.errno not in (errno.EIO, errno.EBADF, errno.EPIPE):
                            raise
                        stdout_open = False
                        detach_reason = detach_reason or "stdout_closed"

            waited_pid, status = os.waitpid(child_pid, os.WNOHANG)
            if waited_pid == child_pid:
                child_status = status
                log_event(
                    "attach_exited",
                    proxy_pid=os.getpid(),
                    child_pid=child_pid,
                    exit_code=exit_code(status),
                    signal=(
                        signal_name(os.WTERMSIG(status))
                        if os.WIFSIGNALED(status)
                        else None
                    ),
                )
    finally:
        monitor_stop.set()
        try:
            termios.tcsetattr(stdin_fd, termios.TCSADRAIN, original_attrs)
        except (OSError, termios.error):
            pass
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
            log_event(
                "attach_reaped",
                proxy_pid=os.getpid(),
                child_pid=child_pid,
                exit_code=exit_code(child_status),
                signal=(
                    signal_name(os.WTERMSIG(child_status))
                    if os.WIFSIGNALED(child_status)
                    else None
                ),
            )

    return exit_code(child_status), host_gone


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


def pane_foreground_pgid(herdr: str, pane_id: str) -> int:
    result = subprocess.run(
        (herdr, "pane", "process-info", "--pane", pane_id),
        capture_output=True,
        check=False,
        text=True,
        timeout=0.5,
    )
    payload = result.stdout if result.stdout.strip() else result.stderr
    try:
        response = json.loads(payload)
    except json.JSONDecodeError as error:
        raise RuntimeError("herdr process lookup returned invalid JSON") from error
    process_info = response.get("result", {}).get("process_info")
    pgid = process_info.get("foreground_process_group_id") if isinstance(process_info, dict) else None
    if result.returncode != 0 or not isinstance(pgid, int):
        raise RuntimeError("herdr process lookup omitted foreground process group")
    return pgid


def close_tab(herdr: str, tab_id: str) -> None:
    result = subprocess.run(
        (herdr, "tab", "close", tab_id),
        capture_output=True,
        check=False,
        text=True,
        timeout=2,
    )
    if result.returncode != 0:
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

    pane_id = initial_info.get("pane_id")
    tab_id = initial_info.get("tab_id")
    if (
        not isinstance(pane_id, str)
        or not pane_id
        or not isinstance(tab_id, str)
        or not tab_id
    ):
        print("herdr-attach-proxy: agent lookup omitted pane or tab ID", file=sys.stderr)
        return 1

    try:
        host_pgid = pane_foreground_pgid(args.herdr, pane_id)
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"herdr-attach-proxy: process lookup failed: {error}", file=sys.stderr)
        return 1

    def host_alive() -> bool:
        return pane_foreground_pgid(args.herdr, pane_id) == host_pgid

    code, observed_host_exit = relay(
        (args.herdr, "agent", "attach", args.target, "--takeover"),
        host_alive,
    )
    try:
        host_exited = observed_host_exit or not host_alive()
    except (OSError, RuntimeError, subprocess.SubprocessError):
        host_exited = observed_host_exit
    if host_exited:
        close_tab(args.herdr, tab_id)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
