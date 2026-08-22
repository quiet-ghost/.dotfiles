#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

MODULE = Path(__file__).with_name("ai_usage.py")
SPEC = importlib.util.spec_from_file_location("ai_usage", MODULE)
USAGE = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(USAGE)


def write_session_db(path: Path, *, old: list[tuple[str, str, int, int]], new: list[tuple[str, str, int, int]] | None) -> None:
    conn = sqlite3.connect(path)
    conn.execute(
        """
        CREATE TABLE session (
            id TEXT PRIMARY KEY,
            model TEXT,
            time_created INTEGER,
            tokens_input INTEGER,
            tokens_output INTEGER,
            tokens_reasoning INTEGER,
            tokens_cache_read INTEGER,
            tokens_cache_write INTEGER
        )
        """
    )
    conn.executemany(
        "INSERT INTO session VALUES (?, ?, ?, ?, 0, 0, 0, 0)",
        old,
    )
    if new is not None:
        conn.execute(
            """
            CREATE TABLE session_v2 (
                id TEXT PRIMARY KEY,
                model TEXT,
                time_created INTEGER,
                tokens_input INTEGER,
                tokens_output INTEGER,
                tokens_reasoning INTEGER,
                tokens_cache_read INTEGER,
                tokens_cache_write INTEGER
            )
            """
        )
        conn.executemany(
            "INSERT INTO session_v2 VALUES (?, ?, ?, ?, 0, 0, 0, 0)",
            new,
        )
    conn.commit()
    conn.close()


class BucketTests(unittest.TestCase):
    def test_today_and_model_totals(self) -> None:
        bucket = USAGE.Bucket()
        day = USAGE.date_str(USAGE.today())
        bucket.add(day, "s1", "gpt-5.6-sol", 100, 20, 10, 0)
        bucket.add(day, "s1", "gpt-5.6-sol", 50, 5, 0, 0)
        snap = bucket.snapshot()
        self.assertEqual(snap["todaySessions"], 1)
        self.assertEqual(snap["todayPrompts"], 2)
        self.assertEqual(snap["todayTotalTokens"], 185)
        self.assertEqual(snap["modelUsage"]["gpt-5.6-sol"]["inputTokens"], 150)

    def test_parse_model_json(self) -> None:
        provider, model = USAGE.parse_model(
            '{"id":"grok-4.5","providerID":"xai","variant":"high"}'
        )
        self.assertEqual(provider, "xai")
        self.assertEqual(model, "grok-4.5")


class OpencodeDbTests(unittest.TestCase):
    def test_prefers_session_v2_over_legacy_session(self) -> None:
        day = USAGE.date_str(USAGE.today())
        created = int(USAGE.now_local().timestamp() * 1000)
        with tempfile.TemporaryDirectory() as tmp:
            db = Path(tmp) / "opencode.db"
            write_session_db(
                db,
                old=[("ses_old", '{"id":"grok-old","providerID":"xai"}', created, 10)],
                new=[("ses_new", '{"id":"grok-4.6","providerID":"xai"}', created, 250)],
            )
            buckets = USAGE.scan_opencode_db(db)
        snap = buckets["xai"].snapshot()
        self.assertEqual(snap["todayTotalTokens"], 250)
        self.assertEqual(snap["todaySessions"], 1)
        self.assertIn("grok-4.6", snap["modelUsage"])
        self.assertNotIn("grok-old", snap["modelUsage"])

    def test_falls_back_to_legacy_session_when_v2_missing(self) -> None:
        created = int(USAGE.now_local().timestamp() * 1000)
        with tempfile.TemporaryDirectory() as tmp:
            db = Path(tmp) / "opencode.db"
            write_session_db(
                db,
                old=[("ses_old", '{"id":"grok-old","providerID":"xai"}', created, 10)],
                new=None,
            )
            buckets = USAGE.scan_opencode_db(db)
        self.assertEqual(buckets["xai"].snapshot()["todayTotalTokens"], 10)


class TokenAndBackoffTests(unittest.TestCase):
    def test_jwt_exp_and_freshness(self) -> None:
        import base64
        import time

        def token_for(exp: int) -> str:
            payload = base64.urlsafe_b64encode(json.dumps({"exp": exp}).encode()).rstrip(b"=").decode()
            return f"aaa.{payload}.sig"

        now = int(time.time())
        self.assertTrue(USAGE.token_fresh(token_for(now + 3600)))
        self.assertFalse(USAGE.token_fresh(token_for(now - 10)))
        self.assertFalse(USAGE.token_fresh("not-a-jwt", expires_at_ms=(now - 10) * 1000))
        self.assertTrue(USAGE.token_fresh("not-a-jwt", expires_at_ms=(now + 3600) * 1000))

    def test_parse_retry_after_seconds_and_http_date(self) -> None:
        self.assertEqual(USAGE.parse_retry_after({"Retry-After": "661"}), 661)
        self.assertEqual(USAGE.parse_retry_after({}, 90), 90)
        future = USAGE.dt.datetime.now(USAGE.dt.timezone.utc) + USAGE.dt.timedelta(minutes=5)
        delay = USAGE.parse_retry_after({"Retry-After": USAGE.email.utils.format_datetime(future)})
        self.assertGreaterEqual(delay, 290)
        self.assertLessEqual(delay, 300)


class OAuthRefreshTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        USAGE.CACHE_ROOT = root / "cache"
        self.home = root / "home"
        self.home.mkdir()
        (self.home / ".codex").mkdir()
        (self.home / ".claude").mkdir()
        self.orig_home = USAGE.home
        USAGE.home = lambda: self.home
        USAGE.FORCE_REFRESH = False
        self.calls: list[str] = []
        self.orig_http = USAGE.http_json

    def tearDown(self) -> None:
        USAGE.home = self.orig_home
        USAGE.http_json = self.orig_http
        USAGE.CACHE_ROOT = None
        USAGE.FORCE_REFRESH = False
        self.tmp.cleanup()

    def test_codex_refreshes_expired_token_and_caches_limits(self) -> None:
        import base64
        import time

        expired = "aaa." + base64.urlsafe_b64encode(
            json.dumps({"exp": int(time.time()) - 10}).encode()
        ).rstrip(b"=").decode() + ".sig"
        fresh = "aaa." + base64.urlsafe_b64encode(
            json.dumps({"exp": int(time.time()) + 3600}).encode()
        ).rstrip(b"=").decode() + ".sig"
        auth_path = self.home / ".codex" / "auth.json"
        auth_path.write_text(
            json.dumps(
                {
                    "tokens": {
                        "access_token": expired,
                        "refresh_token": "old-refresh",
                        "account_id": "acct",
                    }
                }
            )
        )

        def fake_http(url: str, headers: dict, timeout: int = 20, data=None, method=None):
            self.calls.append(url)
            if url.endswith("/oauth/token"):
                return 200, {"access_token": fresh, "refresh_token": "new-refresh"}, {}
            return (
                200,
                {
                    "plan_type": "plus",
                    "rate_limit": {
                        "primary_window": {
                            "used_percent": 12,
                            "reset_at": int(time.time()) + 1800,
                            "limit_window_seconds": 18000,
                        }
                    },
                },
                {},
            )

        USAGE.http_json = fake_http
        limits, tier, status, help_text = USAGE.fetch_codex_limits()
        saved = json.loads(auth_path.read_text())
        self.assertEqual(status, "")
        self.assertEqual(help_text, "")
        self.assertEqual(tier, "plus")
        self.assertEqual(limits[0]["title"], "Session")
        self.assertEqual(saved["tokens"]["access_token"], fresh)
        self.assertEqual(saved["tokens"]["refresh_token"], "new-refresh")
        self.assertTrue(any(url.endswith("/oauth/token") for url in self.calls))

    def test_claude_reuses_open_windows_on_429(self) -> None:
        future = (USAGE.dt.datetime.now(USAGE.dt.timezone.utc) + USAGE.dt.timedelta(hours=2)).isoformat()
        USAGE.store_claude_probe_cache(
            [USAGE.limit_entry("Weekly", 0.4, future)],
            "Pro",
        )
        creds = self.home / ".claude" / ".credentials.json"
        creds.write_text(
            json.dumps(
                {
                    "claudeAiOauth": {
                        "accessToken": "sk-ant-oat01-test",
                        "refreshToken": "refresh",
                        "expiresAt": int((USAGE.time.time() + 3600) * 1000),
                        "subscriptionType": "pro",
                    }
                }
            )
        )

        def fake_http(url: str, headers: dict, timeout: int = 20, data=None, method=None):
            self.calls.append(url)
            return 429, {"error": {"type": "rate_limit_error"}}, {"Retry-After": "90"}

        USAGE.FORCE_REFRESH = True
        USAGE.http_json = fake_http
        limits, tier, status, help_text = USAGE.fetch_claude_limits()
        self.assertEqual(limits[0]["title"], "Weekly")
        self.assertEqual(tier, "Pro")
        self.assertEqual(status, "")
        self.assertEqual(help_text, "")
        self.assertEqual(self.calls, [USAGE.CLAUDE_USAGE_ENDPOINT])

    def test_claude_skips_probe_inside_reuse_window(self) -> None:
        USAGE.store_claude_probe_cache(
            [USAGE.limit_entry("Session", 0.2, "")],
            "Pro",
        )
        creds = self.home / ".claude" / ".credentials.json"
        creds.write_text(
            json.dumps(
                {
                    "claudeAiOauth": {
                        "accessToken": "sk-ant-oat01-test",
                        "expiresAt": int((USAGE.time.time() + 3600) * 1000),
                        "subscriptionType": "pro",
                    }
                }
            )
        )
        USAGE.http_json = lambda *args, **kwargs: self.calls.append("hit") or (500, None, {})
        limits, tier, status, help_text = USAGE.fetch_claude_limits()
        self.assertEqual(limits[0]["title"], "Session")
        self.assertEqual(status, "")
        self.assertEqual(help_text, "")
        self.assertEqual(self.calls, [])


if __name__ == "__main__":
    raise SystemExit(unittest.main())
