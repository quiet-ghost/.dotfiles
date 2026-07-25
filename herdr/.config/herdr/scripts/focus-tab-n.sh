#!/usr/bin/env bash
# Focus the Nth tab (1-based) in the active herdr workspace.
# Used for base-layer symbol chords (ctrl+alt+< { [ …) on custom number-row layouts.
set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"
n="${1:-}"

if [[ ! $n =~ ^[1-9]$ ]]; then
	printf 'usage: %s <1-9>\n' "${0##*/}" >&2
	exit 2
fi

herdr_json() {
	"$HERDR" "$@"
}

active_workspace_id() {
	if [[ -n ${HERDR_ACTIVE_WORKSPACE_ID:-} ]]; then
		printf '%s\n' "$HERDR_ACTIVE_WORKSPACE_ID"
		return
	fi
	herdr_json api snapshot |
		jq -er '.result.snapshot.focused_workspace_id // empty'
}

ws="$(active_workspace_id)"
if [[ -z $ws ]]; then
	printf 'no active workspace\n' >&2
	exit 1
fi

# Herdr tab.number is sparse after closes; bar order = sort_by number, then Nth slot.
tab_id="$(
	herdr_json tab list --workspace "$ws" |
		jq -er --argjson n "$n" '
			(.result.tabs // .result // .)
			| if type == "array" then . else .tabs // [] end
			| sort_by(.number // 0)
			| .[$n - 1].tab_id // empty
		'
)"

if [[ -z $tab_id ]]; then
	printf 'no tab slot %s in workspace %s\n' "$n" "$ws" >&2
	exit 1
fi

herdr_json tab focus "$tab_id" >/dev/null
