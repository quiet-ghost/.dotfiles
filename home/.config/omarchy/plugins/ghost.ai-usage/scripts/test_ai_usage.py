#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
from pathlib import Path
import unittest

MODULE = Path(__file__).with_name("ai_usage.py")
SPEC = importlib.util.spec_from_file_location("ai_usage", MODULE)
USAGE = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(USAGE)


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


if __name__ == "__main__":
    raise SystemExit(unittest.main())
