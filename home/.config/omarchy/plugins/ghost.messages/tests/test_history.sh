#!/usr/bin/env bash

set -euo pipefail

plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_dir="$(mktemp -d)"
trap 'chmod -R u+rwx "$fixture_dir" 2>/dev/null || true; rm -rf "$fixture_dir"' EXIT

printf '%s\n' '{"app":"Signal","summary":"Older","timestamp":100}' > "$fixture_dir/100-1.json"
printf '%s\n' '{"app":"Slack","summary":"Newer","timestamp":200}' > "$fixture_dir/200-2.json"
printf '%s\n' 'not-json' > "$fixture_dir/300-3.json"

actual="$(OMARCHY_MESSAGES_HISTORY_DIR="$fixture_dir" "$plugin_dir/history.sh")"

jq -e '
  length == 2 and
  .[0].summary == "Newer" and
  .[1].summary == "Older"
' >/dev/null <<< "$actual"

blocked_dir="$fixture_dir/blocked"
mkdir "$blocked_dir"
chmod 000 "$blocked_dir"
if OMARCHY_MESSAGES_HISTORY_DIR="$blocked_dir" "$plugin_dir/history.sh" >/dev/null 2>&1; then
  printf 'history parser: expected unreadable directory to fail\n' >&2
  exit 1
fi
chmod 700 "$blocked_dir"

printf 'history parser: ok\n'
