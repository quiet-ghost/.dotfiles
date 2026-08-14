#!/usr/bin/env python3
from __future__ import annotations

import base64
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import threading
import unittest


MODULE_PATH = Path(__file__).with_name("opencode_service.py")
SPEC = importlib.util.spec_from_file_location("opencode_service", MODULE_PATH)
SERVICE = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(SERVICE)


class ApiHandler(BaseHTTPRequestHandler):
    password = "test-secret"
    health_status = 200
    health_pid = 4242
    health_version = "2.0-test"
    sessions_status = 200
    sessions = {"ses_one": {"type": "running"}, "ses_two": {"type": "running"}}

    def do_GET(self) -> None:
        expected = "Basic " + base64.b64encode(f"opencode:{self.password}".encode()).decode()
        if self.headers.get("Authorization") != expected:
            self.send_response(401)
            self.end_headers()
            return
        if self.path == "/api/health":
            self.respond(
                self.health_status,
                {"healthy": True, "version": self.health_version, "pid": self.health_pid},
            )
            return
        if self.path == "/api/session/active":
            self.respond(self.sessions_status, {"data": self.sessions})
            return
        self.send_response(404)
        self.end_headers()

    def respond(self, status: int, body: object) -> None:
        encoded = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def log_message(self, format: str, *args: object) -> None:
        return


class ServiceSnapshotTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.registration = Path(self.temp.name) / "service.json"
        ApiHandler.health_status = 200
        ApiHandler.health_pid = 4242
        ApiHandler.health_version = "2.0-test"
        ApiHandler.sessions_status = 200
        ApiHandler.sessions = {
            "ses_one": {"type": "running"},
            "ses_two": {"type": "running"},
        }
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), ApiHandler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def tearDown(self) -> None:
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=2)
        self.temp.cleanup()

    def write_registration(self, **overrides: object) -> None:
        value: dict[str, object] = {
            "id": "instance-test",
            "version": "2.0-test",
            "url": f"http://127.0.0.1:{self.server.server_port}",
            "pid": 4242,
            "password": ApiHandler.password,
        }
        value.update(overrides)
        self.registration.write_text(json.dumps(value), encoding="utf-8")

    def test_missing_registration_is_stopped_without_failure(self) -> None:
        snapshot = SERVICE.build_snapshot(self.registration)
        self.assertEqual(snapshot["state"], "stopped")
        self.assertIsNone(snapshot["failure"])

    def test_matching_health_reports_ready_and_active_sessions(self) -> None:
        self.write_registration()
        snapshot = SERVICE.build_snapshot(self.registration)
        serialized = json.dumps(snapshot)
        self.assertEqual(snapshot["state"], "ready")
        self.assertEqual(snapshot["activeSessions"], 2)
        self.assertTrue(snapshot["identity"]["matches"])
        self.assertNotIn(ApiHandler.password, serialized)
        self.assertNotIn("instance-test", serialized)

    def test_health_identity_mismatch_is_stale(self) -> None:
        self.write_registration(pid=9001)
        snapshot = SERVICE.build_snapshot(self.registration)
        self.assertEqual(snapshot["state"], "stale")
        self.assertEqual(snapshot["failure"]["tag"], "health_mismatch")

    def test_503_is_transitioning(self) -> None:
        self.write_registration()
        ApiHandler.health_status = 503
        snapshot = SERVICE.build_snapshot(self.registration)
        self.assertEqual(snapshot["state"], "transitioning")
        self.assertEqual(snapshot["failure"]["tag"], "service_transitioning")

    def test_auth_rejection_is_invalid(self) -> None:
        self.write_registration(password="wrong-secret")
        snapshot = SERVICE.build_snapshot(self.registration)
        self.assertEqual(snapshot["state"], "invalid")
        self.assertEqual(snapshot["failure"]["tag"], "auth_rejected")

    def test_non_local_endpoint_is_rejected_before_authentication(self) -> None:
        self.write_registration(url="http://192.0.2.1:4096")
        snapshot = SERVICE.build_snapshot(self.registration)
        self.assertEqual(snapshot["state"], "invalid")
        self.assertEqual(snapshot["failure"]["tag"], "registration_invalid")

    def test_session_failure_keeps_service_ready(self) -> None:
        self.write_registration()
        ApiHandler.sessions_status = 500
        snapshot = SERVICE.build_snapshot(self.registration)
        self.assertEqual(snapshot["state"], "ready")
        self.assertIsNone(snapshot["activeSessions"])
        self.assertEqual(snapshot["failure"]["tag"], "sessions_unavailable")

    def test_action_uses_managed_cli_and_sanitizes_failure_output(self) -> None:
        binary = Path(self.temp.name) / "opencode2"
        record = Path(self.temp.name) / "record.json"
        binary.write_text(
            "#!/bin/sh\n"
            "printf '{\"args\":\"%s %s\",\"config\":\"%s\"}' \"$1\" \"$2\" \"$OPENCODE_CONFIG_DIR\" > \"$ACTION_RECORD\"\n"
            "printf 'private-output' >&2\n"
            "exit \"${ACTION_EXIT:-0}\"\n",
            encoding="utf-8",
        )
        binary.chmod(0o700)
        previous_record = os.environ.get("ACTION_RECORD")
        previous_exit = os.environ.get("ACTION_EXIT")
        os.environ["ACTION_RECORD"] = str(record)
        try:
            result = SERVICE.run_action("restart", binary, Path("/test/config"))
            invocation = json.loads(record.read_text(encoding="utf-8"))
            self.assertTrue(result["accepted"])
            self.assertEqual(invocation, {"args": "service restart", "config": "/test/config"})

            os.environ["ACTION_EXIT"] = "1"
            result = SERVICE.run_action("stop", binary, Path("/test/config"))
            self.assertFalse(result["accepted"])
            self.assertNotIn("private-output", json.dumps(result))
        finally:
            if previous_record is None:
                os.environ.pop("ACTION_RECORD", None)
            else:
                os.environ["ACTION_RECORD"] = previous_record
            if previous_exit is None:
                os.environ.pop("ACTION_EXIT", None)
            else:
                os.environ["ACTION_EXIT"] = previous_exit


if __name__ == "__main__":
    raise SystemExit(unittest.main())
