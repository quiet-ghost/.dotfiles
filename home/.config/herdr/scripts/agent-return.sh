#!/usr/bin/env bash
set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"
return_dir="${XDG_RUNTIME_DIR:-/tmp}/herdr-agent-return-$UID"
socket_key="$(printf '%s' "${HERDR_SOCKET_PATH:-default}" | sha256sum | cut -c1-12)"
return_file="$return_dir/$socket_key.json"

[ -f "$return_file" ] || exit 0
state="$(cat "$return_file")"
agents_workspace="$(jq -er '.agents_workspace // empty' <<<"$state")"
return_tab="$(jq -er '.return_tab' <<<"$state")"
if [ -z "$agents_workspace" ]; then
	agent_tab="$(jq -er '.agent_tab' <<<"$state")"
	agents_workspace="$("$HERDR" tab get "$agent_tab" | jq -er '.result.tab.workspace_id')"
fi

# Do not make Alt+d a global jump when focus has already moved elsewhere.
[ "${HERDR_ACTIVE_WORKSPACE_ID:-}" = "$agents_workspace" ] || exit 0
rm -f "$return_file"
"$HERDR" tab focus "$return_tab" >/dev/null
