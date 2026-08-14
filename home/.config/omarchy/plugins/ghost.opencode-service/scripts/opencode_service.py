#!/usr/bin/env python3
"""Probe and control the local OpenCode 2 managed service."""

from __future__ import annotations

import argparse
import base64
import datetime as dt
import ipaddress
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import time
from typing import Any
import urllib.error
import urllib.parse
import urllib.request


SCHEMA_VERSION = 1
MAX_RESPONSE_BYTES = 64 * 1024
HTTP_TIMEOUT_SECONDS = 2.5
ACTION_TIMEOUT_SECONDS = 30


def now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat()


def failure(tag: str, message: str, recovery: str) -> dict[str, str]:
    return {"tag": tag, "message": message, "recovery": recovery}


def stopped_snapshot(checked_at: str) -> dict[str, Any]:
    return {
        "schemaVersion": SCHEMA_VERSION,
        "state": "stopped",
        "endpoint": None,
        "identity": None,
        "activeSessions": None,
        "latencyMs": None,
        "checkedAt": checked_at,
        "successfulAt": None,
        "failure": None,
    }


def invalid_snapshot(checked_at: str, problem: dict[str, str]) -> dict[str, Any]:
    value = stopped_snapshot(checked_at)
    value["state"] = "invalid"
    value["failure"] = problem
    return value


def parse_registration(path: Path) -> tuple[dict[str, Any] | None, dict[str, str] | None]:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return None, None
    except (OSError, json.JSONDecodeError):
        return None, failure(
            "registration_invalid",
            "OpenCode service registration could not be read.",
            "Run `opencode2 service restart` from a terminal.",
        )

    if not isinstance(raw, dict):
        return None, failure(
            "registration_invalid",
            "OpenCode service registration has an invalid shape.",
            "Run `opencode2 service restart` from a terminal.",
        )
    url = raw.get("url")
    pid = raw.get("pid")
    version = raw.get("version", "")
    password = raw.get("password", "")
    if (
        not isinstance(url, str)
        or not isinstance(pid, int)
        or isinstance(pid, bool)
        or pid <= 0
        or not isinstance(version, str)
        or not isinstance(password, str)
    ):
        return None, failure(
            "registration_invalid",
            "OpenCode service registration is missing required fields.",
            "Run `opencode2 service restart` from a terminal.",
        )

    parsed = urllib.parse.urlsplit(url)
    try:
        port = parsed.port
    except ValueError:
        port = None
    if parsed.scheme != "http" or not parsed.hostname or port is None or parsed.path not in {"", "/"}:
        return None, failure(
            "registration_invalid",
            "OpenCode registered an unsupported service URL.",
            "Check `opencode2 service get`, then restart the service.",
        )
    return {
        "url": url.rstrip("/"),
        "pid": pid,
        "version": version,
        "password": password,
        "host": parsed.hostname,
        "port": port,
    }, None


def exposure_for(host: str) -> str:
    if host.lower() == "localhost":
        return "loopback"
    try:
        address = ipaddress.ip_address(host)
    except ValueError:
        return "unknown"
    if address.is_loopback:
        return "loopback"
    if address.is_private:
        return "private"
    return "non-loopback"


def local_addresses() -> set[ipaddress.IPv4Address | ipaddress.IPv6Address]:
    addresses: set[ipaddress.IPv4Address | ipaddress.IPv6Address] = {
        ipaddress.ip_address("127.0.0.1"),
        ipaddress.ip_address("::1"),
    }
    try:
        result = subprocess.run(
            ["ip", "-j", "address", "show"],
            capture_output=True,
            text=True,
            timeout=2,
            check=False,
        )
        rows = json.loads(result.stdout) if result.returncode == 0 else []
    except (OSError, subprocess.TimeoutExpired, json.JSONDecodeError):
        return addresses
    if not isinstance(rows, list):
        return addresses
    for row in rows:
        entries = row.get("addr_info") if isinstance(row, dict) else None
        if not isinstance(entries, list):
            continue
        for entry in entries:
            value = entry.get("local") if isinstance(entry, dict) else None
            if not isinstance(value, str):
                continue
            try:
                addresses.add(ipaddress.ip_address(value.split("%", 1)[0]))
            except ValueError:
                continue
    return addresses


def endpoint_is_local(host: str) -> bool:
    try:
        resolved = {
            ipaddress.ip_address(item[4][0].split("%", 1)[0])
            for item in socket.getaddrinfo(host, None, type=socket.SOCK_STREAM)
        }
    except (OSError, ValueError):
        return False
    return bool(resolved) and resolved.issubset(local_addresses())


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(
        self,
        req: urllib.request.Request,
        fp: Any,
        code: int,
        msg: str,
        headers: Any,
        newurl: str,
    ) -> None:
        return None


def request_json(registration: dict[str, Any], path: str) -> tuple[int | None, Any, int, str | None]:
    token = base64.b64encode(f"opencode:{registration['password']}".encode()).decode()
    request = urllib.request.Request(
        registration["url"] + path,
        headers={"Authorization": "Basic " + token, "Accept": "application/json"},
    )
    started = time.monotonic()
    opener = urllib.request.build_opener(NoRedirect)
    try:
        with opener.open(request, timeout=HTTP_TIMEOUT_SECONDS) as response:
            body = response.read(MAX_RESPONSE_BYTES + 1)
            status = response.status
    except urllib.error.HTTPError as error:
        with error:
            body = error.read(MAX_RESPONSE_BYTES + 1)
            status = error.code
    except (urllib.error.URLError, TimeoutError, OSError):
        elapsed = max(0, round((time.monotonic() - started) * 1000))
        return None, None, elapsed, "unreachable"
    elapsed = max(0, round((time.monotonic() - started) * 1000))
    if len(body) > MAX_RESPONSE_BYTES:
        return status, None, elapsed, "oversized"
    try:
        return status, json.loads(body), elapsed, None
    except (UnicodeDecodeError, json.JSONDecodeError):
        return status, None, elapsed, "invalid_json"


def identity_view(registration: dict[str, Any], health: Any) -> dict[str, Any]:
    health_pid = health.get("pid") if isinstance(health, dict) else None
    health_version = health.get("version") if isinstance(health, dict) else None
    pid_matches = isinstance(health_pid, int) and not isinstance(health_pid, bool) and health_pid == registration["pid"]
    version_matches = isinstance(health_version, str) and (
        registration["version"] == "" or health_version == registration["version"]
    )
    return {
        "registeredPid": registration["pid"],
        "healthPid": health_pid if isinstance(health_pid, int) and not isinstance(health_pid, bool) else None,
        "registeredVersion": registration["version"],
        "healthVersion": health_version if isinstance(health_version, str) else None,
        "matches": pid_matches and version_matches,
    }


def build_snapshot(registration_path: Path) -> dict[str, Any]:
    checked_at = now_iso()
    registration, registration_error = parse_registration(registration_path)
    if registration_error is not None:
        return invalid_snapshot(checked_at, registration_error)
    if registration is None:
        return stopped_snapshot(checked_at)

    endpoint = {
        "host": registration["host"],
        "port": registration["port"],
        "exposure": exposure_for(registration["host"]),
    }
    if not endpoint_is_local(registration["host"]):
        value = invalid_snapshot(
            checked_at,
            failure(
                "registration_invalid",
                "OpenCode registered an address that is not local to this machine.",
                "Check `opencode2 service get`; do not send service credentials to a remote host.",
            ),
        )
        value["endpoint"] = endpoint
        return value
    status, health, latency_ms, request_error = request_json(registration, "/api/health")
    identity = identity_view(registration, health)
    base: dict[str, Any] = {
        "schemaVersion": SCHEMA_VERSION,
        "state": "invalid",
        "endpoint": endpoint,
        "identity": identity,
        "activeSessions": None,
        "latencyMs": latency_ms,
        "checkedAt": checked_at,
        "successfulAt": None,
        "failure": None,
    }

    if request_error == "unreachable":
        base["state"] = "unreachable"
        base["failure"] = failure(
            "health_unreachable",
            "The registered OpenCode service did not answer.",
            "Retry, then restart the service if it remains unreachable.",
        )
        return base
    if status == 401:
        base["failure"] = failure(
            "auth_rejected",
            "OpenCode rejected the registered service credentials.",
            "Run `opencode2 service restart` to refresh registration.",
        )
        return base
    if request_error is not None or not isinstance(health, dict):
        base["failure"] = failure(
            "response_invalid",
            "OpenCode returned an invalid health response.",
            "Check the installed OpenCode version and restart the service.",
        )
        return base
    if status == 503:
        base["state"] = "transitioning"
        base["failure"] = failure(
            "service_transitioning",
            "OpenCode is starting or stopping.",
            "Wait a moment; restart only if this state persists.",
        )
        return base
    if status == 500:
        base["state"] = "failed"
        base["failure"] = failure(
            "service_failed",
            "OpenCode failed during service startup.",
            "Open the service log, then restart after reviewing the failure.",
        )
        return base
    if status != 200:
        base["failure"] = failure(
            "response_invalid",
            "OpenCode returned an unexpected health status.",
            "Open the service log and verify the installed OpenCode version.",
        )
        return base
    if health.get("healthy") is not True or not identity["matches"]:
        base["state"] = "stale"
        base["failure"] = failure(
            "health_mismatch",
            "Service health does not match the current registration.",
            "Use `opencode2 service restart`; do not remove registration manually.",
        )
        return base

    base["state"] = "ready"
    base["successfulAt"] = checked_at
    session_status, session_body, _, session_error = request_json(registration, "/api/session/active")
    session_data = session_body.get("data") if isinstance(session_body, dict) else None
    if session_status != 200 or session_error is not None or not isinstance(session_data, dict):
        base["failure"] = failure(
            "sessions_unavailable",
            "Service is ready, but active sessions could not be read.",
            "Refresh; check the service log if session status remains unavailable.",
        )
        return base
    if not all(isinstance(value, dict) and value.get("type") == "running" for value in session_data.values()):
        base["failure"] = failure(
            "sessions_unavailable",
            "Service is ready, but active session data has changed shape.",
            "Check for an OpenCode update and refresh the widget.",
        )
        return base
    base["activeSessions"] = len(session_data)
    return base


def run_action(action: str, binary: Path, config_dir: Path) -> dict[str, Any]:
    env = os.environ.copy()
    env["OPENCODE_CONFIG_DIR"] = str(config_dir)
    try:
        result = subprocess.run(
            [str(binary), "service", action],
            capture_output=True,
            text=True,
            timeout=ACTION_TIMEOUT_SECONDS,
            check=False,
            env=env,
        )
    except subprocess.TimeoutExpired:
        return {
            "schemaVersion": SCHEMA_VERSION,
            "action": action,
            "accepted": False,
            "message": "OpenCode service action timed out.",
            "failure": failure(
                "action_timeout",
                "OpenCode did not finish the service action in time.",
                "Check the service log before trying again.",
            ),
        }
    except OSError:
        return {
            "schemaVersion": SCHEMA_VERSION,
            "action": action,
            "accepted": False,
            "message": "OpenCode service action could not start.",
            "failure": failure(
                "action_failed",
                "The OpenCode executable could not be launched.",
                "Verify `~/.opencode/bin/opencode2` is installed.",
            ),
        }
    if result.returncode != 0:
        return {
            "schemaVersion": SCHEMA_VERSION,
            "action": action,
            "accepted": False,
            "message": f"OpenCode service {action} failed.",
            "failure": failure(
                "action_failed",
                f"OpenCode could not {action} the managed service.",
                "Open the service log and retry from a terminal.",
            ),
        }
    return {
        "schemaVersion": SCHEMA_VERSION,
        "action": action,
        "accepted": True,
        "message": f"OpenCode service {action} completed.",
        "failure": None,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("snapshot", "start", "stop", "restart"))
    args = parser.parse_args()
    registration_path = Path(
        os.environ.get(
            "OPENCODE_SERVICE_REGISTRATION",
            str(Path.home() / ".local" / "state" / "opencode" / "service.json"),
        )
    )
    if args.command == "snapshot":
        value = build_snapshot(registration_path)
        print(json.dumps(value, separators=(",", ":")))
        return 0

    binary = Path(os.environ.get("OPENCODE2_BINARY", str(Path.home() / ".opencode" / "bin" / "opencode2")))
    config_dir = Path(os.environ.get("OPENCODE_CONFIG_DIR", str(Path.home() / ".config" / "opencode" / "v2")))
    value = run_action(args.command, binary, config_dir)
    print(json.dumps(value, separators=(",", ":")))
    return 0 if value["accepted"] else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BrokenPipeError:
        raise SystemExit(0)
