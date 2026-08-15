#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
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


if __name__ == "__main__":
    raise SystemExit(unittest.main())
