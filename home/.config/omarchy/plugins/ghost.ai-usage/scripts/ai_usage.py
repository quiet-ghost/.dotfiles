#!/usr/bin/env python3
"""Collect subscription quotas and API spend into one display-ready snapshot."""

from __future__ import annotations

import argparse
import base64
import concurrent.futures
import datetime as dt
import email.utils
import fcntl
import json
import os
import re
import sqlite3
import stat
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Iterator

SEC_MS_THRESHOLD = 10_000_000_000
BROWSER_UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36"
)
CODEX_CLIENT_ID = "app_EMoamEEZ73f0CkXaXp7hrann"
CODEX_UA = "codex-cli"
CLAUDE_USAGE_ENDPOINT = "https://api.anthropic.com/api/oauth/usage"
CLAUDE_PROBE_MIN_INTERVAL_SEC = 15
TOKEN_SKEW_SEC = 60
DEFAULT_BACKOFF_SEC = 300
FORCE_REFRESH = False
CACHE_ROOT: Path | None = None


def home() -> Path:
    return Path.home()


def expand(path: str) -> Path:
    text = os.path.expandvars(path)
    if text == "~":
        return home().resolve()
    if text.startswith("~/"):
        return (home() / text[2:]).resolve()
    return Path(os.path.expanduser(text)).resolve()


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


def cache_dir() -> Path:
    if CACHE_ROOT is not None:
        return CACHE_ROOT
    return home() / ".cache" / "omarchy" / "ai-usage"


def cache_path(name: str) -> Path:
    return cache_dir() / name


def atomic_write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(payload, indent=2) + "\n"
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    tmp = Path(tmp_name)
    try:
        with os.fdopen(fd, "w") as handle:
            handle.write(encoded)
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(tmp, stat.S_IRUSR | stat.S_IWUSR)
        tmp.replace(path)
    except Exception:
        tmp.unlink(missing_ok=True)
        raise


def parse_retry_after(headers: dict[str, str] | None, fallback: int = DEFAULT_BACKOFF_SEC) -> int:
    if not headers:
        return fallback
    raw = str(headers.get("Retry-After") or headers.get("retry-after") or "").strip()
    if not raw:
        return fallback
    try:
        return max(1, int(raw))
    except ValueError:
        pass
    try:
        when = email.utils.parsedate_to_datetime(raw)
    except (TypeError, ValueError, OverflowError):
        return fallback
    if when.tzinfo is None:
        when = when.replace(tzinfo=dt.timezone.utc)
    delay = int((when - dt.datetime.now(dt.timezone.utc)).total_seconds())
    return max(1, delay)


def load_backoff(name: str) -> int:
    raw = read_json(cache_path(f"{name}.backoff.json"))
    if not isinstance(raw, dict):
        return 0
    until = number(raw.get("until"))
    remaining = until - int(time.time())
    return remaining if remaining > 0 else 0


def store_backoff(name: str, seconds: int) -> None:
    atomic_write_json(
        cache_path(f"{name}.backoff.json"),
        {"until": int(time.time()) + max(1, seconds)},
    )


def clear_backoff(name: str) -> None:
    cache_path(f"{name}.backoff.json").unlink(missing_ok=True)


def load_cached_limits(name: str) -> tuple[list[dict[str, Any]], str] | None:
    raw = read_json(cache_path(f"{name}.limits.json"))
    if not isinstance(raw, dict):
        return None
    limits = raw.get("limits")
    if not isinstance(limits, list):
        return None
    return limits, str(raw.get("tier") or "")


def store_cached_limits(name: str, limits: list[dict[str, Any]], tier: str) -> None:
    atomic_write_json(
        cache_path(f"{name}.limits.json"),
        {"limits": limits, "tier": tier, "updatedAt": iso_now()},
    )


@contextmanager
def file_lock(name: str) -> Iterator[None]:
    path = cache_path(f"{name}.lock")
    path.parent.mkdir(parents=True, exist_ok=True)
    handle = path.open("a+")
    try:
        fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
        yield
    finally:
        fcntl.flock(handle.fileno(), fcntl.LOCK_UN)
        handle.close()


def jwt_exp(token: str) -> int:
    parts = token.split(".")
    if len(parts) < 2:
        return 0
    try:
        padded = parts[1] + "=" * (-len(parts[1]) % 4)
        claims = json.loads(base64.urlsafe_b64decode(padded))
    except Exception:
        return 0
    return number(claims.get("exp")) if isinstance(claims, dict) else 0


def token_fresh(token: str, expires_at_ms: Any = None) -> bool:
    now = int(time.time())
    exp = jwt_exp(token)
    if exp > 0:
        return exp - TOKEN_SKEW_SEC > now
    stamp = number(expires_at_ms)
    if stamp <= 0:
        return bool(token)
    if stamp > SEC_MS_THRESHOLD:
        stamp //= 1000
    return stamp - TOKEN_SKEW_SEC > now


def http_json(
    url: str,
    headers: dict[str, str],
    timeout: int = 20,
    data: bytes | None = None,
    method: str | None = None,
) -> tuple[int, Any, dict[str, str]]:
    request_headers = {"User-Agent": BROWSER_UA, "Accept": "application/json", **headers}
    req = urllib.request.Request(url, data=data, headers=request_headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            body = response.read()
            response_headers = dict(response.headers.items())
            if not body:
                return response.status, None, response_headers
            try:
                return response.status, json.loads(body), response_headers
            except json.JSONDecodeError:
                return response.status, None, response_headers
    except urllib.error.HTTPError as exc:
        try:
            payload = json.loads(exc.read().decode("utf-8", "replace"))
        except Exception:
            payload = None
        return exc.code, payload, dict(exc.headers.items()) if exc.headers else {}
    except Exception:
        return 0, None, {}


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


def opencode_session_table(conn: sqlite3.Connection) -> str:
    names = {
        str(row[0])
        for row in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")
    }
    if "session_v2" in names:
        return "session_v2"
    return "session"


def scan_opencode_db(db: Path | None = None) -> dict[str, Bucket]:
    buckets = {
        "openai": Bucket(),
        "xai": Bucket(),
        "opencode": Bucket(),
        "opencode-go": Bucket(),
        "openrouter": Bucket(),
        "anthropic": Bucket(),
    }
    path = db or opencode_db()
    if not path.is_file():
        return buckets
    try:
        conn = sqlite3.connect(f"file:{path}?mode=ro", uri=True, timeout=5)
        conn.row_factory = sqlite3.Row
    except sqlite3.Error:
        return buckets
    try:
        table = opencode_session_table(conn)
        for row in conn.execute(
            f"""
            SELECT id, model, time_created,
                   COALESCE(tokens_input,0) AS tokens_input,
                   COALESCE(tokens_output,0) AS tokens_output,
                   COALESCE(tokens_reasoning,0) AS tokens_reasoning,
                   COALESCE(tokens_cache_read,0) AS tokens_cache_read,
                   COALESCE(tokens_cache_write,0) AS tokens_cache_write
            FROM {table}
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


def cached_limit_result(
    name: str, status: str, help_text: str
) -> tuple[list[dict[str, Any]], str, str, str]:
    cached = load_cached_limits(name)
    if cached is None:
        return [], "", status, help_text
    limits, tier = cached
    return limits, tier, status, help_text


def backoff_limit_result(name: str, seconds: int) -> tuple[list[dict[str, Any]], str, str, str]:
    minutes = max(1, (seconds + 59) // 60)
    return cached_limit_result(
        name,
        f"{name.title()} limits cooling down",
        f"Last good meters shown. Next live check in about {minutes}m.",
    )


def parse_codex_limits(payload: dict[str, Any]) -> tuple[list[dict[str, Any]], str]:
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
    return limits, str(payload.get("plan_type") or "")


def codex_auth_path() -> Path:
    return expand("~/.codex/auth.json")


def refresh_codex_tokens(auth: dict[str, Any]) -> dict[str, Any] | None:
    tokens = auth.get("tokens") if isinstance(auth.get("tokens"), dict) else {}
    refresh = str(tokens.get("refresh_token") or "")
    if not refresh:
        return None
    body = urllib.parse.urlencode(
        {
            "grant_type": "refresh_token",
            "refresh_token": refresh,
            "client_id": CODEX_CLIENT_ID,
        }
    ).encode()
    status, payload, _headers = http_json(
        "https://auth.openai.com/oauth/token",
        {"Content-Type": "application/x-www-form-urlencoded", "User-Agent": CODEX_UA},
        data=body,
        method="POST",
    )
    if status != 200 or not isinstance(payload, dict) or not payload.get("access_token"):
        return None
    next_tokens = dict(tokens)
    next_tokens["access_token"] = str(payload.get("access_token") or "")
    if payload.get("refresh_token"):
        next_tokens["refresh_token"] = str(payload.get("refresh_token"))
    if payload.get("id_token"):
        next_tokens["id_token"] = str(payload.get("id_token"))
    updated = dict(auth)
    updated["tokens"] = next_tokens
    updated["last_refresh"] = iso_now()
    atomic_write_json(codex_auth_path(), updated)
    return updated


def load_codex_auth() -> dict[str, Any] | None:
    with file_lock("codex-auth"):
        auth = read_json(codex_auth_path())
        if not isinstance(auth, dict):
            return None
        tokens = auth.get("tokens") if isinstance(auth.get("tokens"), dict) else {}
        access = str(tokens.get("access_token") or "")
        if access and token_fresh(access):
            return auth
        return refresh_codex_tokens(auth) or auth


def request_codex_usage(auth: dict[str, Any]) -> tuple[int, Any, dict[str, str]]:
    tokens = auth.get("tokens") if isinstance(auth.get("tokens"), dict) else {}
    access = str(tokens.get("access_token") or "")
    account = str(tokens.get("account_id") or "")
    if not access:
        return 0, None, {}
    return http_json(
        "https://chatgpt.com/backend-api/wham/usage",
        {
            "Authorization": f"Bearer {access}",
            "ChatGPT-Account-Id": account,
            "User-Agent": CODEX_UA,
        },
    )


def fetch_codex_limits() -> tuple[list[dict[str, Any]], str, str, str]:
    if not FORCE_REFRESH:
        remaining = load_backoff("codex")
        if remaining > 0:
            return backoff_limit_result("codex", remaining)
    auth = load_codex_auth()
    if not isinstance(auth, dict):
        return [], "", "Codex not logged in", "Run `codex login`."
    tokens = auth.get("tokens") if isinstance(auth.get("tokens"), dict) else {}
    if not str(tokens.get("access_token") or ""):
        return [], "", "Codex not logged in", "Run `codex login`."
    status, payload, headers = request_codex_usage(auth)
    if status in {401, 403}:
        refreshed = refresh_codex_tokens(auth)
        if refreshed is not None:
            auth = refreshed
            status, payload, headers = request_codex_usage(auth)
    if status == 429:
        seconds = parse_retry_after(headers)
        store_backoff("codex", seconds)
        return backoff_limit_result("codex", seconds)
    if status != 200 or not isinstance(payload, dict):
        if status in {401, 403}:
            return cached_limit_result(
                "codex",
                "Codex login expired",
                "Token refresh failed. Run `codex login` if this persists.",
            )
        return cached_limit_result(
            "codex",
            "Codex limits unavailable",
            "Could not reach ChatGPT usage. Last good meters shown if available.",
        )
    limits, tier = parse_codex_limits(payload)
    store_cached_limits("codex", limits, tier)
    clear_backoff("codex")
    return limits, tier, "", ""


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
    status, payload, _headers = http_json(
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
    cost_status, cost_payload, _cost_headers = http_json(
        "https://api.openai.com/v1/organization/costs?"
        + urllib.parse.urlencode({"start_time": start, "bucket_width": "1d", "limit": 7}),
        headers,
    )
    usage_status, usage_payload, _usage_headers = http_json(
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
    status, payload, _headers = http_json(
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


def fetch_openrouter() -> tuple[dict[str, Any] | None, list[dict[str, Any]], str, str, str]:
    management = secret(
        "OPENROUTER_MANAGEMENT_KEY",
        "openrouterManagementKey",
        "OPENROUTER_MANAGEMENT_KEY",
    )
    key = secret("OPENROUTER_API_KEY", "openrouterApiKey", "OPENROUTER_API_KEY")
    if not key:
        auth = read_json(expand("~/.local/share/opencode/auth.json"))
        if isinstance(auth, dict):
            entry = auth.get("openrouter")
            if isinstance(entry, dict) and str(entry.get("key") or "").strip():
                key = str(entry.get("key")).strip()

    if not management and not key:
        return (
            None,
            [],
            "OpenRouter",
            "OpenRouter key missing",
            "Set openrouterManagementKey or openrouterApiKey in ~/.config/omarchy/ai-usage.json",
        )

    balance = None
    limits: list[dict[str, Any]] = []
    label = "OpenRouter"
    help_text = ""
    status_text = ""

    if management:
        status, payload, _headers = http_json(
            "https://openrouter.ai/api/v1/credits",
            {"Authorization": f"Bearer {management}"},
        )
        if status == 403:
            status_text = "OpenRouter management key rejected"
            help_text = "Use a Management key from openrouter.ai/settings/management-keys"
        elif status in {401}:
            status_text = "OpenRouter management key rejected"
            help_text = "Check openrouterManagementKey"
        elif status == 200 and isinstance(payload, dict):
            data = payload.get("data") if isinstance(payload.get("data"), dict) else payload
            funded = money(data.get("total_credits"))
            spent = money(data.get("total_usage"))
            left = max(0.0, funded - spent)
            balance = {
                "remaining": left,
                "funded": funded,
                "spent": spent,
                "currency": "USD",
                "estimated": False,
            }
            if funded > 0:
                limits.append(limit_entry("Account", spent / funded, ""))
            label = "OpenRouter account"
        else:
            status_text = "OpenRouter credits unavailable"
            help_text = "GET /api/v1/credits failed."

    if key and (balance is None or not limits):
        status, payload, _headers = http_json(
            "https://openrouter.ai/api/v1/key",
            {"Authorization": f"Bearer {key}"},
        )
        if status in {401, 403} and balance is None:
            return None, [], "OpenRouter", "OpenRouter key rejected", "Create a key at openrouter.ai/settings/keys"
        if status == 200 and isinstance(payload, dict):
            data = payload.get("data") if isinstance(payload.get("data"), dict) else payload
            used = money(data.get("usage"))
            remaining = data.get("limit_remaining")
            limit = data.get("limit")
            funded = money(limit) if limit is not None else used + money(remaining)
            left = money(remaining) if remaining is not None else max(0.0, funded - used)
            if balance is None and (funded > 0 or left > 0 or used > 0):
                balance = {
                    "remaining": left,
                    "funded": funded if funded > 0 else left + used,
                    "spent": used,
                    "currency": "USD",
                    "estimated": False,
                }
            if funded > 0:
                limits.append(limit_entry("Key cap", 1.0 - (left / funded) if funded else 0.0, ""))
            label = str(data.get("label") or label)
            if balance is not None:
                status_text = ""
                help_text = ""
        elif balance is None:
            return None, [], "OpenRouter", "OpenRouter usage unavailable", "GET /api/v1/key failed."

    return balance, limits, label, status_text, help_text


def parse_utilization(value: Any) -> float:
    try:
        return float(str(value).strip().replace("%", ""))
    except (TypeError, ValueError):
        return float("nan")


def normalize_utilization(value: Any, percent_scale: bool) -> float:
    amount = parse_utilization(value)
    if not (amount >= 0):
        return -1.0
    if percent_scale or amount > 1:
        return min(1.0, amount / 100.0)
    return min(1.0, amount)


def normalize_reset_at(value: Any) -> str:
    if value is None:
        return ""
    raw = str(value).strip()
    if raw == "":
        return ""
    if raw.isdigit():
        stamp = int(raw)
        if stamp < 1e12:
            stamp *= 1000
        try:
            return dt.datetime.fromtimestamp(stamp / 1000, dt.timezone.utc).isoformat()
        except (OverflowError, OSError, ValueError):
            return raw
    try:
        parsed = dt.datetime.fromisoformat(raw.replace("Z", "+00:00"))
        return parsed.isoformat()
    except ValueError:
        return raw


def claude_plan_label(tier: str, subscription: str) -> str:
    if tier:
        match = re.search(r"max_(\d+x)", tier, re.IGNORECASE)
        if match:
            return "Max " + match.group(1)
    if subscription:
        return subscription[0].upper() + subscription[1:]
    return ""


def claude_usage_bucket(payload: dict[str, Any], key: str) -> dict[str, Any] | None:
    bucket = payload.get(key)
    return bucket if isinstance(bucket, dict) else None


def claude_scoped_window(kind: str) -> str:
    text = kind.lower()
    if "month" in text:
        return "Monthly"
    if "week" in text or "day" in text:
        return "Weekly"
    if "hour" in text or "session" in text:
        return "Session"
    return ""


def claude_scoped_limits(payload: dict[str, Any], percent_scale: bool) -> list[dict[str, Any]]:
    entries = payload.get("limits")
    if not isinstance(entries, list):
        return []
    out: list[dict[str, Any]] = []
    seen: set[tuple[str, str]] = set()
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        scope = entry.get("scope")
        model = scope.get("model") if isinstance(scope, dict) else None
        if not isinstance(model, dict):
            continue
        name = str(model.get("display_name") or model.get("id") or "").strip()
        kind = str(entry.get("kind") or "").strip()
        if name == "" or (name, kind) in seen:
            continue
        percent = normalize_utilization(entry.get("percent"), percent_scale)
        if percent < 0:
            continue
        seen.add((name, kind))
        window = claude_scoped_window(kind)
        title = f"{name} {window}" if window else name
        out.append(limit_entry(title, percent, normalize_reset_at(entry.get("resets_at"))))
    return out


def parse_claude_limits(payload: dict[str, Any]) -> list[dict[str, Any]]:
    weekly = claude_usage_bucket(payload, "seven_day_oauth_apps") or claude_usage_bucket(
        payload, "seven_day"
    )
    session = claude_usage_bucket(payload, "five_hour")
    raw = [
        session.get("utilization") if session else None,
        weekly.get("utilization") if weekly else None,
    ]
    entries = payload.get("limits")
    if isinstance(entries, list):
        raw += [entry.get("percent") for entry in entries if isinstance(entry, dict)]
    percent_scale = any(parse_utilization(value) >= 1 for value in raw)
    limits: list[dict[str, Any]] = []
    if session is not None:
        percent = normalize_utilization(session.get("utilization"), percent_scale)
        if percent >= 0:
            limits.append(
                limit_entry("Session", percent, normalize_reset_at(session.get("resets_at")))
            )
    if weekly is not None:
        percent = normalize_utilization(weekly.get("utilization"), percent_scale)
        if percent >= 0:
            limits.append(
                limit_entry("Weekly", percent, normalize_reset_at(weekly.get("resets_at")))
            )
    limits.extend(claude_scoped_limits(payload, percent_scale))
    extra = payload.get("extra_usage")
    if isinstance(extra, dict) and extra.get("is_enabled"):
        percent = normalize_utilization(extra.get("utilization"), percent_scale)
        if percent >= 0:
            limits.append(limit_entry("Extra", percent, ""))
    return limits


def claude_config_dir() -> Path:
    return expand(os.environ.get("CLAUDE_CONFIG_DIR") or "~/.claude")


def claude_creds_path() -> Path:
    return claude_config_dir() / ".credentials.json"


def claude_oauth_login() -> tuple[str, int, str]:
    creds = read_json(claude_creds_path())
    login = creds.get("claudeAiOauth") if isinstance(creds, dict) else None
    if not isinstance(login, dict):
        return "", 0, ""
    plan = claude_plan_label(
        str(login.get("rateLimitTier") or ""),
        str(login.get("subscriptionType") or ""),
    )
    return str(login.get("accessToken") or ""), number(login.get("expiresAt")), plan


def claude_limit_window_open(entry: dict[str, Any], now: dt.datetime) -> bool:
    raw = str(entry.get("resetsAt") or "")
    if raw == "":
        return True
    try:
        resets_at = dt.datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return True
    if resets_at.tzinfo is None:
        resets_at = resets_at.replace(tzinfo=dt.timezone.utc)
    return resets_at > now


def usable_cached_claude_limits(cached: dict[str, Any]) -> list[dict[str, Any]]:
    entries = cached.get("limits")
    if not isinstance(entries, list):
        return []
    now = dt.datetime.now(dt.timezone.utc)
    return [
        entry
        for entry in entries
        if isinstance(entry, dict) and claude_limit_window_open(entry, now)
    ]


def load_claude_probe_cache() -> dict[str, Any]:
    raw = read_json(cache_path("claude.limits.json"))
    return raw if isinstance(raw, dict) else {}


def store_claude_probe_cache(limits: list[dict[str, Any]], tier: str) -> None:
    atomic_write_json(
        cache_path("claude.limits.json"),
        {
            "fetchedAtMs": int(time.time() * 1000),
            "limits": limits,
            "tier": tier,
            "updatedAt": iso_now(),
        },
    )


def probe_claude_limits(access_token: str) -> dict[str, Any]:
    status, payload, headers = http_json(
        CLAUDE_USAGE_ENDPOINT,
        {
            "Authorization": f"Bearer {access_token}",
            "anthropic-beta": "oauth-2025-04-20",
            "Accept": "application/json",
        },
    )
    if status == 429:
        retry_after = str(headers.get("Retry-After") or headers.get("retry-after") or "")
        help_text = "Anthropic's usage endpoint is rate limiting checks right now"
        if retry_after:
            help_text += f" (retry after {retry_after}s)"
        help_text += ". Local Claude Code stats are still shown."
        return {"ok": False, "helpText": help_text}
    if status == 0:
        return {
            "ok": False,
            "transport": True,
            "helpText": "Couldn't reach Anthropic's usage endpoint. Retrying shortly. Local Claude Code stats are still shown.",
        }
    if status != 200 or not isinstance(payload, dict):
        return {
            "ok": False,
            "helpText": f"Anthropic's usage endpoint returned status {status or 0}. Local Claude Code stats are still shown.",
        }
    limits = parse_claude_limits(payload)
    if not limits:
        return {
            "ok": False,
            "helpText": "Anthropic's usage endpoint returned no limits. Local Claude Code stats are still shown.",
        }
    return {"ok": True, "limits": limits}


def fetch_claude_limits() -> tuple[list[dict[str, Any]], str, str, str]:
    token, expires_at_ms, plan = claude_oauth_login()
    cached = load_claude_probe_cache()
    fallback = usable_cached_claude_limits(cached)
    cached_tier = str(cached.get("tier") or plan)

    if token == "":
        return fallback, cached_tier, "Waiting for auth", "Run `claude auth login` to restore authoritative usage."
    if expires_at_ms > 0 and expires_at_ms <= time.time() * 1000:
        help_text = "Claude Code's saved sign-in expired"
        if fallback:
            help_text += " — showing the last known limits."
        else:
            help_text += "."
        help_text += " Start Claude Code, or run `claude auth login`, to refresh it."
        return fallback, cached_tier, "Sign-in expired", help_text

    fetched_at = number(cached.get("fetchedAtMs")) / 1000
    if fallback and not FORCE_REFRESH and time.time() - fetched_at < CLAUDE_PROBE_MIN_INTERVAL_SEC:
        return fallback, cached_tier, "", ""

    probe = probe_claude_limits(token)
    if probe.get("ok"):
        limits = probe["limits"]
        store_claude_probe_cache(limits, plan)
        return limits, plan, "", ""
    if fallback:
        return fallback, cached_tier, "", ""
    return [], plan, "Claude limits unavailable", str(probe.get("helpText") or "")


def fetch_claude_api() -> tuple[dict[str, Any] | None, dict[str, Any], str, str]:
    key = secret("ANTHROPIC_ADMIN_KEY", "anthropicAdminKey", "ANTHROPIC_ADMIN_KEY")
    if not key:
        return (
            None,
            empty_bucket_snapshot(),
            "Claude Admin key missing",
            "Org spend needs sk-ant-admin-… from console.anthropic.com. Individual accounts have no remaining-credit API.",
        )
    start = (dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=7)).strftime("%Y-%m-%d")
    status, payload, _headers = http_json(
        "https://api.anthropic.com/v1/organizations/cost_report?"
        + urllib.parse.urlencode({"starting_at": start, "bucket_width": "1d", "limit": 7}),
        {
            "x-api-key": key,
            "anthropic-version": "2023-06-01",
        },
    )
    if status in {401, 403}:
        return None, empty_bucket_snapshot(), "Claude Admin key rejected", "Admin API is org-only."
    if status != 200 or not isinstance(payload, dict):
        return None, empty_bucket_snapshot(), "Claude API spend unavailable", "Cost report failed."
    spent = 0.0
    for bucket in payload.get("data") or []:
        if not isinstance(bucket, dict):
            continue
        for result in bucket.get("results") or []:
            if not isinstance(result, dict):
                continue
            try:
                spent += abs(float(str(result.get("amount") or 0))) / 100.0
            except (TypeError, ValueError):
                pass
    balance = None
    if spent > 0:
        balance = {
            "remaining": 0,
            "funded": spent,
            "spent": spent,
            "currency": "USD",
            "estimated": False,
        }
    return balance, empty_bucket_snapshot(), "", ""


def build_snapshot() -> dict[str, Any]:
    local = scan_opencode_db()
    openai_local = local["openai"]
    xai_local = local["xai"]
    zen_local = local["opencode"]
    go_local = local["opencode-go"]

    scan_codex_sessions(openai_local)
    scan_grok_sessions(xai_local)

    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        codex_f = pool.submit(fetch_codex_limits)
        grok_f = pool.submit(fetch_grok_limits)
        go_f = pool.submit(fetch_opencode_go)
        openai_f = pool.submit(fetch_openai_api)
        xai_f = pool.submit(fetch_xai_api)
        openrouter_f = pool.submit(fetch_openrouter)
        claude_f = pool.submit(fetch_claude_limits)
        claude_api_f = pool.submit(fetch_claude_api)
        codex_limits, codex_tier, codex_status, codex_help = codex_f.result()
        grok_limits, grok_tier, grok_status, grok_help = grok_f.result()
        go_limits, go_status, go_help = go_f.result()
        openai_balance, openai_stats, openai_status, openai_help = openai_f.result()
        xai_balance, xai_status, xai_help = xai_f.result()
        openrouter_balance, openrouter_limits, openrouter_tier, openrouter_status, openrouter_help = openrouter_f.result()
        claude_limits, claude_tier, claude_status, claude_help = claude_f.result()
        claude_api_balance, claude_api_stats, claude_api_status, claude_api_help = claude_api_f.result()

    openai_stats_final = openai_stats
    xai_api_stats = empty_bucket_snapshot() if xai_status else snapshot_from(xai_local)
    openrouter_local = local.get("openrouter") or Bucket()
    anthropic_local = local.get("anthropic") or Bucket()

    opencode_all = Bucket()
    for source in (zen_local, go_local, openai_local, xai_local, openrouter_local, anthropic_local):
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
            "claude",
            "Claude Code",
            tier=claude_tier or "Claude",
            limits=claude_limits,
            status=claude_status,
            help_text=claude_help,
            ready=not claude_status,
            stats=snapshot_from(anthropic_local),
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
        provider_record(
            "claude-api",
            "Claude API",
            tier="Platform",
            balance=claude_api_balance,
            status=claude_api_status,
            help_text=claude_api_help,
            ready=not claude_api_status,
            stats=claude_api_stats,
        ),
        provider_record(
            "openrouter",
            "OpenRouter",
            tier=openrouter_tier or "OpenRouter",
            limits=openrouter_limits,
            balance=openrouter_balance,
            status=openrouter_status,
            help_text=openrouter_help,
            ready=not openrouter_status,
            stats=snapshot_from(openrouter_local),
        ),
    ]
    providers = subs + apis
    return {
        "schemaVersion": 1,
        "updatedAt": iso_now(),
        "catalog": [
            {"id": "codex", "name": "Codex", "defaultView": "subs"},
            {"id": "grok", "name": "Grok", "defaultView": "subs"},
            {"id": "claude", "name": "Claude Code", "defaultView": "subs"},
            {"id": "opencode", "name": "OpenCode", "defaultView": "subs"},
            {"id": "openai-api", "name": "OpenAI API", "defaultView": "apis"},
            {"id": "xai-api", "name": "xAI API", "defaultView": "apis"},
            {"id": "claude-api", "name": "Claude API", "defaultView": "apis"},
            {"id": "openrouter", "name": "OpenRouter", "defaultView": "apis"},
        ],
        "providers": providers,
        "views": {"subs": subs, "apis": apis},
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", help="optional snapshot path")
    parser.add_argument(
        "--force-refresh",
        action="store_true",
        help="bypass usage backoff and refresh OAuth tokens if they look stale",
    )
    args = parser.parse_args()
    global FORCE_REFRESH
    FORCE_REFRESH = bool(args.force_refresh)
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
