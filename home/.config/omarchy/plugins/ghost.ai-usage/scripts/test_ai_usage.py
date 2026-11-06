#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path
from unittest import mock

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


class OmarchyProviderTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.dir = Path(self.tmp.name)

    def write(self, name: str, record: object) -> None:
        (self.dir / f"{name}.json").write_text(json.dumps(record))

    def by_id(self) -> dict[str, dict]:
        return {p["id"]: p for p in USAGE.load_omarchy_providers(self.dir)}

    def test_reads_any_record_except_providers_collected_here(self) -> None:
        self.write("cursor", {"id": "cursor", "name": "Cursor", "tierLabel": "Premium", "ready": True})
        self.write("brand-new", {"id": "brand-new", "name": "Brand New", "totalPrompts": 3})
        for own in ("claude", "codex", "grok", "opencode", "openrouter"):
            self.write(own, {"id": own, "name": own, "totalPrompts": 9})

        self.assertEqual(sorted(self.by_id()), ["brand-new", "cursor"])

    def test_keeps_limits_balance_and_token_stats(self) -> None:
        self.write("cursor", {
            "id": "cursor",
            "name": "Cursor",
            "tierLabel": "Premium",
            "ready": True,
            "limits": [{"label": "Included total", "title": "Weekly", "percent": 0.4, "resetsAt": "2026-11-10T09:32:46+00:00"}],
            "balance": {"remaining": 5, "funded": 20, "spent": 15, "currency": "USD", "estimated": True},
            "recentDays": [{"date": "2026-11-05", "messageCount": 12}],
            "modelUsage": {"m": {"inputTokens": 1, "outputTokens": 2, "cacheReadInputTokens": 3, "cacheCreationInputTokens": 4}},
        })

        record = self.by_id()["cursor"]

        self.assertEqual(record["source"], "omarchy")
        self.assertEqual(record["limits"][0]["title"], "Weekly")
        self.assertEqual(record["limits"][0]["percent"], 0.4)
        self.assertEqual(record["balance"]["remaining"], 5.0)
        self.assertTrue(record["balance"]["estimated"])
        self.assertEqual(record["recentDays"], [{"date": "2026-11-05", "messageCount": 12}])
        self.assertEqual(record["modelUsage"]["m"]["cacheCreationInputTokens"], 4)

    def test_default_view_follows_what_the_record_has(self) -> None:
        empty = USAGE.omarchy_default_view({"ready": False, "tierLabel": "Pro"})
        signed_in = USAGE.omarchy_default_view({"ready": True, "tierLabel": "Pro"})
        history = USAGE.omarchy_default_view({"totalPrompts": 1})
        limits = USAGE.omarchy_default_view({"limits": [{"percent": 0.1}]})
        prepaid = USAGE.omarchy_default_view({"balance": {"remaining": 1.0}})

        self.assertEqual(empty, "hidden")
        self.assertEqual(signed_in, "subs")
        self.assertEqual(history, "subs")
        self.assertEqual(limits, "subs")
        self.assertEqual(prepaid, "apis")

    def test_bad_input_is_skipped_or_dropped_without_failing(self) -> None:
        (self.dir / "broken.json").write_text("{not json")
        (self.dir / "huge.json").write_text(json.dumps({"id": "huge", "name": "x" * USAGE.OMARCHY_RECORD_MAX_BYTES}))
        self.write("list", ["not", "a", "record"])
        self.write("badid", {"id": "../../etc", "name": "Bad"})
        self.write("odd", {
            "id": "odd",
            "name": "n" * 500,
            "limits": [{"percent": "lots"}, {"percent": -1}, "nope", {"percent": 0.5}],
            "balance": {"remaining": -3},
            "recentDays": "nope",
            "modelUsage": {"m": "nope"},
            "totalPrompts": "many",
        })

        found = self.by_id()

        self.assertEqual(sorted(found), ["odd"])
        odd = found["odd"]
        self.assertLessEqual(len(odd["name"]), USAGE.OMARCHY_TEXT_MAX)
        self.assertEqual([limit["percent"] for limit in odd["limits"]], [0.5])
        self.assertIsNone(odd["balance"])
        self.assertEqual(odd["recentDays"], [])
        self.assertEqual(odd["modelUsage"], {})
        self.assertEqual(odd["totalPrompts"], 0)

    def test_missing_directory_means_no_extra_providers(self) -> None:
        self.assertEqual(USAGE.load_omarchy_providers(self.dir / "missing"), [])

    def test_providers_with_something_to_show_sort_first(self) -> None:
        self.write("aaa", {"id": "aaa", "name": "Aaa"})
        self.write("zzz", {"id": "zzz", "name": "Zzz", "totalPrompts": 1})

        order = [p["id"] for p in USAGE.load_omarchy_providers(self.dir)]

        self.assertEqual(order, ["zzz", "aaa"])

    def test_assemble_adds_extras_to_catalog_and_their_view_only(self) -> None:
        sub = USAGE.provider_record("codex", "Codex")
        api = USAGE.provider_record("openrouter", "OpenRouter")
        shown = dict(USAGE.provider_record("cursor", "Cursor", limits=[{"percent": 0.1}]), source="omarchy", defaultView="subs")
        prepaid = dict(USAGE.provider_record("deepseek", "DeepSeek", balance={"remaining": 1.0}), source="omarchy", defaultView="apis")
        empty = dict(USAGE.provider_record("kimi", "Kimi"), source="omarchy", defaultView="hidden")

        snapshot = USAGE.assemble_snapshot([sub], [api], [shown, prepaid, empty])

        catalog = {row["id"]: row["defaultView"] for row in snapshot["catalog"]}
        self.assertEqual(catalog["cursor"], "subs")
        self.assertEqual(catalog["deepseek"], "apis")
        self.assertEqual(catalog["kimi"], "hidden")
        self.assertEqual(catalog["codex"], "subs")
        self.assertEqual([p["id"] for p in snapshot["views"]["subs"]], ["codex", "cursor"])
        self.assertEqual([p["id"] for p in snapshot["views"]["apis"]], ["openrouter", "deepseek"])
        self.assertIn("kimi", [p["id"] for p in snapshot["providers"]])


class CerebrasTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.requests: list[tuple[str, dict[str, str]]] = []
        self.answer = (200, {"data": []}, {})

        def fake_http(url: str, headers: dict[str, str], **_kwargs: object) -> tuple[int, object, dict[str, str]]:
            self.requests.append((url, headers))
            return self.answer

        for name, value in (("http_json", fake_http), ("home", lambda: self.home), ("secret", lambda *_args: self.key)):
            patcher = mock.patch.object(USAGE, name, value)
            patcher.start()
            self.addCleanup(patcher.stop)
        self.key = "csk-test"

    def test_missing_key_says_where_to_put_one_and_makes_no_request(self) -> None:
        self.key = ""

        status, help_text = USAGE.fetch_cerebras()

        self.assertEqual(status, "Cerebras key missing")
        self.assertIn("cerebrasApiKey", help_text)
        self.assertEqual(self.requests, [])

    def test_valid_key_has_no_status(self) -> None:
        self.assertEqual(USAGE.fetch_cerebras(), ("", ""))
        url, headers = self.requests[0]
        self.assertEqual(url, "https://api.cerebras.ai/v1/models")
        self.assertEqual(headers["Authorization"], "Bearer csk-test")

    def test_rejected_key_is_reported(self) -> None:
        self.answer = (401, None, {})

        status, help_text = USAGE.fetch_cerebras()

        self.assertEqual(status, "Cerebras key rejected")
        self.assertIn("cloud.cerebras.ai", help_text)

    def test_outage_says_history_is_unaffected(self) -> None:
        self.answer = (0, None, {})

        status, help_text = USAGE.fetch_cerebras()

        self.assertEqual(status, "Cerebras unavailable")
        self.assertIn("history", help_text)

    def test_reads_key_opencode_saved(self) -> None:
        self.key = ""
        auth = self.home / ".local" / "share" / "opencode" / "auth.json"
        auth.parent.mkdir(parents=True)
        auth.write_text(json.dumps({"cerebras": {"type": "api", "key": "csk-opencode"}}))

        USAGE.fetch_cerebras()

        self.assertEqual(self.requests[0][1]["Authorization"], "Bearer csk-opencode")

    def test_opencode_sessions_on_cerebras_get_their_own_bucket(self) -> None:
        db = self.home / "opencode.db"
        write_session_db(db, old=[("s1", json.dumps({"providerID": "cerebras", "id": "gpt-oss-120b"}), 1_790_000_000_000, 50)], new=None)

        buckets = USAGE.scan_opencode_db(db)

        self.assertEqual(buckets["cerebras"].models["gpt-oss-120b"]["inputTokens"], 50)

    def test_omarchy_record_never_duplicates_cerebras(self) -> None:
        self.assertIn("cerebras", USAGE.OMARCHY_COLLECTED_HERE)


class ApiStyleDefaultViewTests(unittest.TestCase):
    def test_pay_per_token_providers_start_in_apis_once_they_have_data(self) -> None:
        for provider in ("fireworks", "deepseek"):
            self.assertEqual(USAGE.omarchy_default_view({"id": provider, "totalPrompts": 1}), "apis")
            self.assertEqual(USAGE.omarchy_default_view({"id": provider}), "hidden")


if __name__ == "__main__":
    raise SystemExit(unittest.main())
