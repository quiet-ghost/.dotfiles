#!/usr/bin/env bash
set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"
pane_id="$1"
tab_id="$2"
expected_pgid="$3"
return_file="${4:-}"
lock_dir="${XDG_RUNTIME_DIR:-/tmp}/herdr-agent-watch-$UID"
mkdir -p "$lock_dir"
chmod 700 "$lock_dir"

# Reopening an existing agent must not add another watcher.
exec 9>"$lock_dir/${pane_id//[^a-zA-Z0-9_-]/_}.lock"
flock -n 9 || exit 0

while info="$("$HERDR" pane process-info --pane "$pane_id" 2>/dev/null)"; do
	pgid="$(jq -er '.result.process_info.foreground_process_group_id' <<<"$info" 2>/dev/null || true)"
	[ "$pgid" = "$expected_pgid" ] || break
	sleep 0.2
done

if [ -n "$return_file" ] && [ -f "$return_file" ]; then
	state="$(cat "$return_file")"
	agents_workspace="$(jq -er '.agents_workspace // empty' <<<"$state" 2>/dev/null || true)"
	return_tab="$(jq -er '.return_tab' <<<"$state" 2>/dev/null || true)"
	if [ -z "$agents_workspace" ]; then
		agent_tab="$(jq -er '.agent_tab' <<<"$state" 2>/dev/null || true)"
		agents_workspace="$("$HERDR" tab get "$agent_tab" 2>/dev/null | jq -er '.result.tab.workspace_id' 2>/dev/null || true)"
	fi
	focused_tab_info="$("$HERDR" tab list 2>/dev/null | jq -er '.result.tabs[] | select(.focused == true)' 2>/dev/null || true)"
	focused_tab="$(jq -er '.tab_id' <<<"$focused_tab_info" 2>/dev/null || true)"
	focused_workspace="$(jq -er '.workspace_id' <<<"$focused_tab_info" 2>/dev/null || true)"
	if [ "$focused_workspace" = "$agents_workspace" ] && [ "$focused_tab" = "$tab_id" ] && [ -n "$return_tab" ]; then
		"$HERDR" tab focus "$return_tab" >/dev/null 2>&1 || true
		rm -f "$return_file"
	fi
fi

"$HERDR" tab close "$tab_id" >/dev/null 2>&1 || true
