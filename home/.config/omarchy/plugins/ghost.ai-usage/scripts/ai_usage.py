#!/usr/bin/env python3
"""Collect subscription quotas and API spend into one display-ready snapshot."""

from __future__ import annotations

import argparse
import concurrent.futures
import datetime as dt
import json
import os
import sqlite3
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

SEC_MS_THRESHOLD = 10_000_000_000
BROWSER_UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36"
)


def home() -> Path:
    return Path.home()


def expand(path: str) -> Path:
    return Path(os.path.expandvars(os.path.expanduser(path))).resolve()


def now_local() -> dt.datetime:
    return dt.datetime.now().astimezone()


def today() -> dt.date:
    return now_local().date()


def date_str(value: dt.date) -> str:
    return value.strftime("%Y-%m-%d")


def recent_dates() -> list[str]:
    start = today()
    return [date_str(start - dt.timedelta(days=offset)) for offset in range(6, -1, -1)]


def iso_now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat()


def number(value: Any) -> int:
    try:
        return max(0, int(value or 0))
    except (TypeError, ValueError):
        return 0


def money(value: Any) -> float:
    try:
        amount = float(value or 0)
    except (TypeError, ValueError):
        return 0.0
    return amount if amount > 0 else 0.0


def local_day(value: Any) -> str:
    if value is None:
        return date_str(today())
    if isinstance(value, (int, float)):
        stamp = float(value)
        if stamp > SEC_MS_THRESHOLD:
            stamp /= 1000
        return dt.datetime.fromtimestamp(stamp).date().isoformat()
    text = str(value)
    try:
        parsed = dt.datetime.fromisoformat(text.replace("Z", "+00:00"))
        if parsed.tzinfo is not None:
            parsed = parsed.astimezone()
        return parsed.date().isoformat()
    except ValueError:
        return date_str(today())


def read_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text())
    except Exception:
        return None


def load_secret_config() -> dict[str, Any]:
    raw = read_json(home() / ".config" / "omarchy" / "ai-usage.json")
    return raw if isinstance(raw, dict) else {}


def secret(name: str, *config_keys: str) -> str:
    env = os.environ.get(name, "").strip()
    if env:
        return env
    config = load_secret_config()
    for key in config_keys or (name,):
        value = config.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return ""


def http_json(
    url: str,
    headers: dict[str, str],
    timeout: int = 20,
    data: bytes | None = None,
    method: str | None = None,
) -> tuple[int, Any]:
    request_headers = {"User-Agent": BROWSER_UA, "Accept": "application/json", **headers}
    req = urllib.request.Request(url, data=data, headers=request_headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            body = response.read()
            if not body:
                return response.status, None
            try:
                return response.status, json.loads(body)
            except json.JSONDecodeError:
                return response.status, None
    except urllib.error.HTTPError as exc:
        try:
            payload = json.loads(exc.read().decode("utf-8", "replace"))
        except Exception:
            payload = None
        return exc.code, payload
    except Exception:
        return 0, None


class Bucket:
    def __init__(self) -> None:
        self.input_tokens = 0
        self.output_tokens = 0
        self.cache_read = 0
        self.cache_write = 0
        self.prompts = 0
        self.sessions: set[str] = set()
        self.today_sessions: set[str] = set()
        self.today_prompts = 0
        self.days: dict[str, int] = {day: 0 for day in recent_dates()}
        self.models: dict[str, dict[str, int]] = {}
        self.today_models: dict[str, int] = {}
        self.active_days: set[str] = set()

    def add(
        self,
        day: str,
        session: str,
        model: str,
        input_tokens: int,
        output_tokens: int,
        cache_read: int,
        cache_write: int,
    ) -> None:
        total = input_tokens + output_tokens + cache_read + cache_write
        if total <= 0:
            return
        self.input_tokens += input_tokens
        self.output_tokens += output_tokens
        self.cache_read += cache_read
        self.cache_write += cache_write
        self.prompts += 1
        self.sessions.add(session)
        self.active_days.add(day)
        if day in self.days:
            self.days[day] += total
        if day == date_str(today()):
            self.today_prompts += 1
            self.today_sessions.add(session)
            self.today_models[model] = self.today_models.get(model, 0) + total
        bucket = self.models.setdefault(
            model,
            {
                "inputTokens": 0,
                "outputTokens": 0,
                "cacheReadInputTokens": 0,
                "cacheCreationInputTokens": 0,
            },
        )
        bucket["inputTokens"] += input_tokens
        bucket["outputTokens"] += output_tokens
        bucket["cacheReadInputTokens"] += cache_read
        bucket["cacheCreationInputTokens"] += cache_write

    def today_tokens(self) -> int:
        return self.days.get(date_str(today()), 0)

    def snapshot(self) -> dict[str, Any]:
        return {
            "todayPrompts": self.today_prompts,
            "todaySessions": len(self.today_sessions),
            "todayTotalTokens": self.today_tokens(),
            "todayTokensByModel": dict(self.today_models),
            "recentDays": [
                {"date": day, "messageCount": self.days.get(day, 0)} for day in recent_dates()
            ],
            "totalPrompts": self.prompts,
            "totalSessions": len(self.sessions),
            "activeDays": len(self.active_days),
            "activeDates": sorted(self.active_days),
            "modelUsage": self.models,
            "hasLocalStats": self.prompts > 0 or self.today_tokens() > 0,
            "hasPromptStats": True,
        }


def empty_bucket_snapshot() -> dict[str, Any]:
    return {
        "todayPrompts": 0,
        "todaySessions": 0,
        "todayTotalTokens": 0,
        "todayTokensByModel": {},
        "recentDays": [{"date": day, "messageCount": 0} for day in recent_dates()],
        "totalPrompts": 0,
        "totalSessions": 0,
        "activeDays": 0,
        "activeDates": [],
        "modelUsage": {},
        "hasLocalStats": False,
        "hasPromptStats": True,
    }


def snapshot_from(bucket: Bucket) -> dict[str, Any]:
    return bucket.snapshot()


def provider_record(
    provider_id: str,
    name: str,
    *,
    tier: str = "",
    limits: list[dict[str, Any]] | None = None,
    balance: dict[str, Any] | None = None,
    status: str = "",
    help_text: str = "",
    ready: bool = True,
    stats: dict[str, Any] | None = None,
) -> dict[str, Any]:
    record = {
        "id": provider_id,
        "name": name,
        "tierLabel": tier,
        "ready": ready,
        "usageStatusText": status,
        "authHelpText": help_text,
        "limits": limits or [],
        "balance": balance,
    }
    record.update(stats or empty_bucket_snapshot())
    return record


def parse_model(raw: Any) -> tuple[str, str]:
    if isinstance(raw, dict):
        provider = str(raw.get("providerID") or raw.get("provider") or "")
        model = str(raw.get("id") or raw.get("modelID") or raw.get("model") or "unknown")
        return provider, model or "unknown"
    text = str(raw or "").strip()
    if text.startswith("{"):
        try:
            parsed = json.loads(text)
            if isinstance(parsed, dict):
                return parse_model(parsed)
        except json.JSONDecodeError:
            pass
    if "/" in text:
        provider, model = text.split("/", 1)
        return provider, model or "unknown"
    return "", text or "unknown"


def friendly_model(raw: Any) -> str:
    provider, model = parse_model(raw)
    return f"{model} ({provider})" if provider else model


def opencode_db() -> Path:
    return expand("~/.local/share/opencode/opencode.db")


def scan_opencode_db() -> dict[str, Bucket]:
    buckets = {
        "openai": Bucket(),
        "xai": Bucket(),
        "opencode": Bucket(),
        "opencode-go": Bucket(),
    }
    db = opencode_db()
    if not db.is_file():
        return buckets
    try:
        conn = sqlite3.connect(f"file:{db}?mode=ro&immutable=1", uri=True, timeout=5)
        conn.row_factory = sqlite3.Row
    except sqlite3.Error:
        return buckets
    try:
        for row in conn.execute(
            """
            SELECT id, model, time_created,
                   COALESCE(tokens_input,0) AS tokens_input,
                   COALESCE(tokens_output,0) AS tokens_output,
                   COALESCE(tokens_reasoning,0) AS tokens_reasoning,
                   COALESCE(tokens_cache_read,0) AS tokens_cache_read,
                   COALESCE(tokens_cache_write,0) AS tokens_cache_write
            FROM session
            WHERE time_created > 0
            """
        ):
            provider, model = parse_model(row["model"])
            key = provider if provider in buckets else ""
            if key == "":
                continue
            input_tokens = number(row["tokens_input"]) + number(row["tokens_reasoning"])
            output_tokens = number(row["tokens_output"])
            cache_read = number(row["tokens_cache_read"])
            cache_write = number(row["tokens_cache_write"])
            if input_tokens + output_tokens + cache_read + cache_write <= 0:
                continue
            buckets[key].add(
                local_day(row["time_created"]),
                f"opencode:{row['id']}",
                model,
                input_tokens,
                output_tokens,
                cache_read,
                cache_write,
            )
    except sqlite3.Error:
        pass
    finally:
        conn.close()
    return buckets


def scan_codex_sessions(bucket: Bucket) -> None:
    roots = [expand("~/.codex/sessions"), expand("~/.codex/archived_sessions")]
    cutoff = dt.datetime.now().timestamp() - 30 * 24 * 3600
    files: list[Path] = []
    for root in roots:
        if not root.exists():
            continue
        for path in root.rglob("*.jsonl"):
            try:
                if path.stat().st_mtime >= cutoff:
                    files.append(path)
            except OSError:
                continue
    for path in files:
        current_model = "codex"
        try:
            with path.open(errors="replace") as handle:
                for raw in handle:
                    try:
                        entry = json.loads(raw)
                    except json.JSONDecodeError:
                        continue
                    if entry.get("type") == "turn_context":
                        payload = entry.get("payload") or {}
                        current_model = str(
                            payload.get("model") or payload.get("model_slug") or current_model
                        )
                        continue
                    payload = entry.get("payload") or entry
                    if entry.get("type") == "response_item" and isinstance(payload, dict):
                        payload = payload.get("payload") or payload
                    if not isinstance(payload, dict) or payload.get("type") != "token_count":
                        continue
                    usage = (payload.get("info") or {}).get("last_token_usage") or {}
                    cache_read = number(usage.get("cached_input_tokens"))
                    cache_write = number(usage.get("cache_write_input_tokens"))
                    input_tokens = max(
                        0, number(usage.get("input_tokens")) - cache_read - cache_write
                    )
                    output_tokens = number(usage.get("output_tokens"))
                    if not (input_tokens or output_tokens or cache_read or cache_write):
                        continue
                    bucket.add(
                        local_day(entry.get("timestamp") or path.stat().st_mtime),
                        str(path),
                        current_model,
                        input_tokens,
                        output_tokens,
                        cache_read,
                        cache_write,
                    )
        except OSError:
            continue


def scan_grok_sessions(bucket: Bucket) -> None:
    root = expand("~/.grok/sessions")
    if not root.exists():
        return
    cutoff = dt.datetime.now().timestamp() - 30 * 24 * 3600
    for path in root.rglob("signals.json"):
        try:
            if path.stat().st_mtime < cutoff:
                continue
            data = read_json(path)
        except OSError:
            continue
        if not isinstance(data, dict):
            continue
        tokens = number(data.get("totalTokensBeforeCompaction") or data.get("contextTokensUsed"))
        if tokens <= 0:
            continue
        models = data.get("modelsUsed") or []
        model = str(data.get("primaryModelId") or (models[0] if models else "grok"))
        bucket.add(
            local_day(path.stat().st_mtime),
            str(path.parent),
            model,
            tokens,
            0,
            0,
            0,
        )


def limit_entry(title: str, percent: float, resets_at: str, label: str = "") -> dict[str, Any]:
    return {
        "title": title,
        "label": label or title,
        "percent": max(0.0, min(1.0, percent)),
        "resetsAt": resets_at,
    }


def unix_to_iso(value: Any) -> str:
    stamp = number(value)
    if stamp <= 0:
        return ""
    return dt.datetime.fromtimestamp(stamp, dt.timezone.utc).isoformat()


def fetch_codex_limits() -> tuple[list[dict[str, Any]], str, str, str]:
    auth = read_json(expand("~/.codex/auth.json"))
    if not isinstance(auth, dict):
        return [], "", "Codex not logged in", "Run `codex login`."
    tokens = auth.get("tokens") if isinstance(auth.get("tokens"), dict) else {}
    access = str(tokens.get("access_token") or "")
    account = str(tokens.get("account_id") or "")
    if not access:
        return [], "", "Codex not logged in", "Run `codex login`."
    status, payload = http_json(
        "https://chatgpt.com/backend-api/wham/usage",
        {
            "Authorization": f"Bearer {access}",
            "ChatGPT-Account-Id": account,
        },
    )
    if status != 200 or not isinstance(payload, dict):
        return [], "", "Codex limits unavailable", "Refresh Codex login if this persists."
    limits: list[dict[str, Any]] = []
    rate = payload.get("rate_limit") if isinstance(payload.get("rate_limit"), dict) else {}
    for key, fallback_title in (("primary_window", "Weekly"), ("secondary_window", "Session")):
        window = rate.get(key)
        if not isinstance(window, dict):
            continue
        seconds = number(window.get("limit_window_seconds"))
        title = "Weekly" if seconds >= 604800 else fallback_title
        if seconds == 18000:
            title = "Session"
        limits.append(
            limit_entry(
                title,
                money(window.get("used_percent")) / 100.0,
                unix_to_iso(window.get("reset_at")),
            )
        )
    extras = payload.get("additional_rate_limits")
    if isinstance(extras, list):
        for extra in extras:
            if not isinstance(extra, dict):
                continue
            extra_rate = extra.get("rate_limit") if isinstance(extra.get("rate_limit"), dict) else {}
            window = extra_rate.get("primary_window")
            if not isinstance(window, dict):
                continue
            name = str(extra.get("limit_name") or "Extra")
            limits.append(
                limit_entry(
                    name,
                    money(window.get("used_percent")) / 100.0,
                    unix_to_iso(window.get("reset_at")),
                )
            )
    return limits, str(payload.get("plan_type") or ""), "", ""


def fetch_grok_limits() -> tuple[list[dict[str, Any]], str, str, str]:
    try:
        result = subprocess.run(
            ["codexbar", "usage", "--provider", "grok", "--format", "json"],
            check=False,
            capture_output=True,
            text=True,
            timeout=25,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return [], "SuperGrok", "Grok limits unavailable", "Install `codexbar` or run `grok login`."
    if result.returncode != 0:
        return [], "SuperGrok", "Grok limits unavailable", "Run `grok login` and retry."
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        return [], "SuperGrok", "Grok limits unavailable", "codexbar returned invalid JSON."
    rows = payload if isinstance(payload, list) else [payload]
    for row in rows:
        if not isinstance(row, dict):
            continue
        usage = row.get("usage") if isinstance(row.get("usage"), dict) else {}
        primary = usage.get("primary") if isinstance(usage.get("primary"), dict) else {}
        if "usedPercent" not in primary:
            continue
        reset = str(primary.get("resetsAt") or "")
        return (
            [limit_entry("Weekly", money(primary.get("usedPercent")) / 100.0, reset)],
            str(usage.get("loginMethod") or "SuperGrok"),
            "",
            "",
        )
    return [], "SuperGrok", "Grok limits unavailable", "Run `grok login`."


def fetch_opencode_go() -> tuple[list[dict[str, Any]], str, str]:
    auth = read_json(expand("~/.local/share/opencode/auth.json"))
    key = ""
    if isinstance(auth, dict):
        for name in ("opencode-go", "opencode"):
            entry = auth.get(name)
            if isinstance(entry, dict) and str(entry.get("key") or "").strip():
                key = str(entry.get("key")).strip()
                break
    if not key:
        return [], "OpenCode key missing", "Connect OpenCode Zen / Go in `opencode`."
    status, payload = http_json(
        "https://opencode.ai/zen/go/v1/usage",
        {"Authorization": f"Bearer {key}"},
    )
    if status == 403:
        error = payload.get("error") if isinstance(payload, dict) else {}
        message = ""
        if isinstance(error, dict):
            message = str(error.get("message") or "")
        if "subscription" in message.lower():
            return [], "", "No Go plan on this key. Zen wallet has no public balance API yet."
        return [], "OpenCode Go unavailable", message or "Go usage was rejected."
    if status != 200 or not isinstance(payload, dict):
        return [], "OpenCode Go unavailable", "Could not reach /zen/go/v1/usage."
    usage = payload.get("usage") if isinstance(payload.get("usage"), dict) else payload
    limits: list[dict[str, Any]] = []
    for key_name, title in (("rolling", "Session"), ("weekly", "Weekly"), ("monthly", "Monthly")):
        window = usage.get(key_name) if isinstance(usage, dict) else None
        if not isinstance(window, dict):
            continue
        percent = window.get("percent", window.get("usagePercent"))
        reset = str(window.get("resetsAt") or "")
        if percent is None:
            continue
        limits.append(limit_entry(title, money(percent) / 100.0, reset))
    return limits, "", ""


def fetch_openai_api() -> tuple[dict[str, Any] | None, dict[str, Any], str, str]:
    key = secret("OPENAI_ADMIN_KEY", "openaiAdminKey", "OPENAI_ADMIN_KEY")
    if not key:
        return (
            None,
            empty_bucket_snapshot(),
            "OpenAI Admin key missing",
            "Set OPENAI_ADMIN_KEY or openaiAdminKey in ~/.config/omarchy/ai-usage.json",
        )
    start = int((dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=7)).timestamp())
    headers = {"Authorization": f"Bearer {key}"}
    cost_status, cost_payload = http_json(
        "https://api.openai.com/v1/organization/costs?"
        + urllib.parse.urlencode({"start_time": start, "bucket_width": "1d", "limit": 7}),
        headers,
    )
    usage_status, usage_payload = http_json(
        "https://api.openai.com/v1/organization/usage/completions?"
        + urllib.parse.urlencode(
            {"start_time": start, "bucket_width": "1d", "group_by": "model", "limit": 7}
        ),
        headers,
    )
    if cost_status in {401, 403} or usage_status in {401, 403}:
        return (
            None,
            empty_bucket_snapshot(),
            "OpenAI Admin key rejected",
            "Create a Usage-capable Admin key at platform.openai.com",
        )
    bucket = Bucket()
    spent = 0.0
    if isinstance(usage_payload, dict):
        for item in usage_payload.get("data") or []:
            if not isinstance(item, dict):
                continue
            day = local_day(item.get("start_time"))
            for result in item.get("results") or []:
                if not isinstance(result, dict):
                    continue
                input_tokens = number(result.get("input_tokens"))
                output_tokens = number(result.get("output_tokens"))
                cache_read = number(result.get("input_cached_tokens"))
                model = str(result.get("model") or "openai")
                bucket.add(day, f"openai-api:{day}:{model}", model, input_tokens, output_tokens, cache_read, 0)
    if isinstance(cost_payload, dict):
        for item in cost_payload.get("data") or []:
            if not isinstance(item, dict):
                continue
            for result in item.get("results") or []:
                if not isinstance(result, dict):
                    continue
                amount = result.get("amount") if isinstance(result.get("amount"), dict) else {}
                spent += money(amount.get("value"))
    balance = None
    if spent > 0:
        balance = {
            "remaining": 0,
            "funded": spent,
            "spent": spent,
            "currency": "USD",
            "estimated": False,
        }
    status = ""
    help_text = ""
    if cost_status != 200 and usage_status != 200:
        status = "OpenAI usage unavailable"
        help_text = "Admin Usage/Costs endpoints failed."
    return balance, snapshot_from(bucket), status, help_text


def fetch_xai_api() -> tuple[dict[str, Any] | None, str, str]:
    key = secret("XAI_MANAGEMENT_KEY", "xaiManagementKey", "XAI_MANAGEMENT_KEY")
    team = secret("XAI_TEAM_ID", "xaiTeamId", "XAI_TEAM_ID")
    if not team:
        grok_auth = read_json(expand("~/.grok/auth.json"))
        if isinstance(grok_auth, dict):
            for entry in grok_auth.values():
                if isinstance(entry, dict) and entry.get("team_id"):
                    team = str(entry["team_id"])
                    break
    if not key:
        return (
            None,
            "xAI Management key missing",
            "Set XAI_MANAGEMENT_KEY or xaiManagementKey in ~/.config/omarchy/ai-usage.json",
        )
    if not team:
        return None, "xAI team id missing", "Set xaiTeamId or run `grok login`."
    status, payload = http_json(
        f"https://management-api.x.ai/v1/billing/teams/{team}/prepaid/balance",
        {"Authorization": f"Bearer {key}"},
    )
    if status in {401, 403}:
        return None, "xAI Management key rejected", "Create a billing-capable management key."
    if status != 200 or not isinstance(payload, dict):
        return None, "xAI billing unavailable", "Management prepaid balance request failed."
    total = payload.get("total") if isinstance(payload.get("total"), dict) else {}
    cents = 0.0
    try:
        cents = abs(float(str(total.get("val") or 0)))
    except (TypeError, ValueError):
        cents = 0.0
    remaining = cents / 100.0
    spent = 0.0
    changes = payload.get("changes")
    if isinstance(changes, list):
        for change in changes:
            if not isinstance(change, dict):
                continue
            if str(change.get("changeOrigin") or "") != "SPEND":
                continue
            amount = change.get("amount") if isinstance(change.get("amount"), dict) else {}
            try:
                spent += abs(float(str(amount.get("val") or 0))) / 100.0
            except (TypeError, ValueError):
                pass
    funded = remaining + spent if remaining + spent > 0 else remaining
    return (
        {
            "remaining": remaining,
            "funded": funded,
            "spent": spent,
            "currency": "USD",
            "estimated": False,
        },
        "",
        "",
    )


def build_snapshot() -> dict[str, Any]:
    local = scan_opencode_db()
    openai_local = local["openai"]
    xai_local = local["xai"]
    zen_local = local["opencode"]
    go_local = local["opencode-go"]

    scan_codex_sessions(openai_local)
    scan_grok_sessions(xai_local)

    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
        codex_f = pool.submit(fetch_codex_limits)
        grok_f = pool.submit(fetch_grok_limits)
        go_f = pool.submit(fetch_opencode_go)
        openai_f = pool.submit(fetch_openai_api)
        xai_f = pool.submit(fetch_xai_api)
        codex_limits, codex_tier, codex_status, codex_help = codex_f.result()
        grok_limits, grok_tier, grok_status, grok_help = grok_f.result()
        go_limits, go_status, go_help = go_f.result()
        openai_balance, openai_stats, openai_status, openai_help = openai_f.result()
        xai_balance, xai_status, xai_help = xai_f.result()

    openai_stats_final = openai_stats
    xai_api_stats = empty_bucket_snapshot() if xai_status else snapshot_from(xai_local)

    opencode_all = Bucket()
    for source in (zen_local, go_local, openai_local, xai_local):
        for model, usage in source.models.items():
            opencode_all.models[model] = {
                "inputTokens": opencode_all.models.get(model, {}).get("inputTokens", 0) + usage["inputTokens"],
                "outputTokens": opencode_all.models.get(model, {}).get("outputTokens", 0) + usage["outputTokens"],
                "cacheReadInputTokens": opencode_all.models.get(model, {}).get("cacheReadInputTokens", 0)
                + usage["cacheReadInputTokens"],
                "cacheCreationInputTokens": opencode_all.models.get(model, {}).get("cacheCreationInputTokens", 0)
                + usage["cacheCreationInputTokens"],
            }
        for day, count in source.days.items():
            opencode_all.days[day] = opencode_all.days.get(day, 0) + count
        for model, count in source.today_models.items():
            opencode_all.today_models[model] = opencode_all.today_models.get(model, 0) + count
        opencode_all.prompts += source.prompts
        opencode_all.today_prompts += source.today_prompts
        opencode_all.sessions.update(source.sessions)
        opencode_all.today_sessions.update(source.today_sessions)
        opencode_all.active_days.update(source.active_days)
    zen_stats = snapshot_from(opencode_all)

    subs = [
        provider_record(
            "codex",
            "Codex",
            tier=codex_tier or "ChatGPT",
            limits=codex_limits,
            status=codex_status,
            help_text=codex_help,
            ready=not codex_status,
            stats=snapshot_from(openai_local),
        ),
        provider_record(
            "grok",
            "Grok",
            tier=grok_tier or "SuperGrok",
            limits=grok_limits,
            status=grok_status,
            help_text=grok_help,
            ready=not grok_status,
            stats=snapshot_from(xai_local),
        ),
        provider_record(
            "opencode",
            "OpenCode",
            tier="Go" if go_limits else "Zen",
            limits=go_limits,
            status=go_status,
            help_text=go_help,
            ready=True,
            stats=zen_stats if zen_stats.get("hasLocalStats") else snapshot_from(go_local),
        ),
    ]
    apis = [
        provider_record(
            "openai-api",
            "OpenAI API",
            tier="Platform",
            balance=openai_balance,
            status=openai_status,
            help_text=openai_help,
            ready=not openai_status,
            stats=openai_stats_final,
        ),
        provider_record(
            "xai-api",
            "xAI API",
            tier="Prepaid",
            balance=xai_balance,
            status=xai_status,
            help_text=xai_help,
            ready=not xai_status,
            stats=xai_api_stats,
        ),
    ]
    return {
        "schemaVersion": 1,
        "updatedAt": iso_now(),
        "views": {"subs": subs, "apis": apis},
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", help="optional snapshot path")
    args = parser.parse_args()
    snapshot = build_snapshot()
    encoded = json.dumps(snapshot, separators=(",", ":"))
    if args.out:
        path = expand(args.out)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(encoded + "\n")
    print(encoded)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
