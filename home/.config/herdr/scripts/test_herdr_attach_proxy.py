from __future__ import annotations

import importlib.util
import os
import pty
import select
import signal
import sys
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("herdr-attach-proxy.py")
SPEC = importlib.util.spec_from_file_location("herdr_attach_proxy", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"cannot load {MODULE_PATH}")
proxy = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(proxy)


def wait_for_pid(pid: int, timeout: float = 3.0) -> int:
    deadline = proxy.time.monotonic() + timeout
    while proxy.time.monotonic() < deadline:
        waited_pid, status = os.waitpid(pid, os.WNOHANG)
        if waited_pid == pid:
            return status
        proxy.time.sleep(0.01)
    os.kill(pid, signal.SIGKILL)
    os.waitpid(pid, 0)
    raise AssertionError(f"process {pid} did not exit")


def start_relay(result_path: Path, mode: str) -> tuple[int, int]:
    master_fd, slave_fd = pty.openpty()
    child_code = """
import os
import signal
import sys
import tty

result_path, mode = sys.argv[1:]
tty.setraw(0)
if mode == "term":
    def handle_term(signum, frame):
        with open(result_path, "w") as result:
            result.write(signal.Signals(signum).name)
        raise SystemExit(0)
    signal.signal(signal.SIGTERM, handle_term)
os.write(1, b"R")
if mode != "term":
    with open(result_path, "wb") as result:
        result.write(os.read(0, 2))
else:
    signal.pause()
"""
    pid = os.fork()
    if pid == 0:
        os.close(master_fd)
        os.dup2(slave_fd, sys.stdin.fileno())
        os.dup2(slave_fd, sys.stdout.fileno())
        if slave_fd > sys.stdout.fileno():
            os.close(slave_fd)
        code, _ = proxy.relay(
            (sys.executable, "-c", child_code, str(result_path), mode),
            lambda: True,
        )
        os._exit(code)

    os.close(slave_fd)
    readable, _, _ = select.select([master_fd], [], [], 2.0)
    if not readable or os.read(master_fd, 1) != b"R":
        os.kill(pid, signal.SIGKILL)
        os.waitpid(pid, 0)
        os.close(master_fd)
        raise AssertionError("relay child did not become ready")
    return pid, master_fd


def run_proxy_with_fake_herdr(input_bytes: bytes) -> list[str]:
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        command_log = root / "commands"
        host_gone = root / "host-gone"
        fake_herdr = root / "herdr"
        fake_herdr.write_text(
            """#!/usr/bin/env python3
import json
import os
import pathlib
import sys
import tty

args = sys.argv[1:]
with open(os.environ["FAKE_HERDR_LOG"], "a") as log:
    log.write(" ".join(args) + "\\n")
host_gone = pathlib.Path(os.environ["FAKE_HOST_GONE"])
if args[:2] == ["agent", "get"]:
    print(json.dumps({"result": {"agent": {"pane_id": "pane-1", "tab_id": "tab-1"}}}))
elif args[:2] == ["pane", "process-info"]:
    pgid = 200 if host_gone.exists() else 100
    print(json.dumps({"result": {"process_info": {"foreground_process_group_id": pgid}}}))
elif args[:2] == ["agent", "attach"]:
    tty.setraw(0)
    os.write(1, b"R")
    data = os.read(0, 2)
    if data == b"\\x03":
        host_gone.touch()
        os.read(0, 2)
elif args[:2] == ["tab", "close"]:
    pass
else:
    raise SystemExit(2)
"""
        )
        fake_herdr.chmod(0o700)

        pid, master_fd = pty.fork()
        if pid == 0:
            os.environ["FAKE_HERDR_LOG"] = str(command_log)
            os.environ["FAKE_HOST_GONE"] = str(host_gone)
            os.execv(
                sys.executable,
                (
                    sys.executable,
                    str(MODULE_PATH),
                    "test-agent",
                    "--herdr",
                    str(fake_herdr),
                ),
            )

        try:
            readable, _, _ = select.select([master_fd], [], [], 2.0)
            if not readable or os.read(master_fd, 1) != b"R":
                raise AssertionError("proxy did not become ready")
            os.write(master_fd, input_bytes)
            if proxy.exit_code(wait_for_pid(pid)) != 0:
                raise AssertionError("proxy did not exit cleanly")
        finally:
            os.close(master_fd)

        return command_log.read_text().splitlines()


class DetachTranslatorTest(unittest.TestCase):
    def test_legacy_sequence_across_reads(self) -> None:
        translator = proxy.DetachTranslator()

        self.assertEqual(translator.feed(b"\x1b", 1.0), b"")
        self.assertEqual(translator.feed(b"d", 1.001), proxy.DETACH)

    def test_kitty_sequences(self) -> None:
        for sequence in (b"\x1b[100;3u", b"\x1b[100;3:1u"):
            with self.subTest(sequence=sequence):
                translator = proxy.DetachTranslator()
                self.assertEqual(translator.feed(sequence, 1.0), proxy.DETACH)

    def test_standalone_escape_expires(self) -> None:
        translator = proxy.DetachTranslator()
        translator.feed(b"\x1b", 1.0)

        self.assertEqual(
            translator.flush_expired(1.0 + proxy.ESCAPE_TIMEOUT),
            b"\x1b",
        )

    def test_legacy_ctrl_c_passes_through(self) -> None:
        translator = proxy.DetachTranslator()

        self.assertEqual(translator.feed(b"\x03", 1.0), b"\x03")

    def test_kitty_ctrl_c_passes_through(self) -> None:
        for sequence in (b"\x1b[99;5u", b"\x1b[99;5:1u"):
            with self.subTest(sequence=sequence):
                translator = proxy.DetachTranslator()
                self.assertEqual(translator.feed(sequence, 1.0), sequence)

    def test_unrelated_input_passes_through(self) -> None:
        translator = proxy.DetachTranslator()

        self.assertEqual(translator.feed(b"hello\n", 1.0), b"hello\n")


class LifecyclePolicyTest(unittest.TestCase):
    def test_hangup_detaches_but_termination_forwards(self) -> None:
        self.assertEqual(proxy.termination_action(signal.SIGHUP), "detach")
        self.assertEqual(proxy.termination_action(signal.SIGTERM), "forward")

    def test_unnamed_signal_uses_its_number(self) -> None:
        realtime_signal = signal.SIGRTMIN + 1

        self.assertEqual(proxy.signal_name(realtime_signal), str(realtime_signal))

    def test_ctrl_c_closes_tab_after_tui_exit(self) -> None:
        commands = run_proxy_with_fake_herdr(b"\x03")

        self.assertEqual(commands.count("agent get test-agent"), 1)
        self.assertIn("agent attach test-agent --takeover", commands)
        self.assertEqual(commands[-1], "tab close tab-1")

    def test_alt_d_detaches_without_closing_tab(self) -> None:
        commands = run_proxy_with_fake_herdr(b"\x1bd")

        self.assertIn("agent attach test-agent --takeover", commands)
        self.assertNotIn("tab close tab-1", commands)

    def test_log_is_private_and_bounded(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            original_path = proxy.LOG_PATH
            proxy.LOG_PATH = Path(directory) / "herdr/attach-proxy.log"
            try:
                proxy.log_event("test", proxy_pid=1, child_pid=2)
                self.assertEqual(proxy.LOG_PATH.stat().st_mode & 0o777, 0o600)

                proxy.LOG_PATH.write_bytes(b"x" * proxy.MAX_LOG_BYTES)
                proxy.log_event("rotated", proxy_pid=1, child_pid=2)
                self.assertLess(proxy.LOG_PATH.stat().st_size, proxy.MAX_LOG_BYTES)
            finally:
                proxy.LOG_PATH = original_path

    def test_hangup_sends_clean_detach(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            result_path = Path(directory) / "result"
            pid, master_fd = start_relay(result_path, "read")
            try:
                os.kill(pid, signal.SIGHUP)
                self.assertEqual(proxy.exit_code(wait_for_pid(pid)), 0)
                self.assertEqual(result_path.read_bytes(), proxy.DETACH)
            finally:
                os.close(master_fd)

    def test_stdin_eof_sends_clean_detach(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            result_path = Path(directory) / "result"
            pid, master_fd = start_relay(result_path, "read")
            os.close(master_fd)

            self.assertEqual(proxy.exit_code(wait_for_pid(pid)), 0)
            self.assertEqual(result_path.read_bytes(), proxy.DETACH)

    def test_sigterm_is_forwarded(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            result_path = Path(directory) / "result"
            pid, master_fd = start_relay(result_path, "term")
            try:
                os.kill(pid, signal.SIGTERM)
                self.assertEqual(proxy.exit_code(wait_for_pid(pid)), 0)
                self.assertEqual(result_path.read_text(), "SIGTERM")
            finally:
                os.close(master_fd)


if __name__ == "__main__":
    unittest.main()
