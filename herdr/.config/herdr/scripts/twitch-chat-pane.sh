#!/usr/bin/env bash
# Toggle a persistent Twitch chat pane in herdr (tmux Alt+Shift+C twin).
# Parks the live process in workspace "tui_chat"; shows it as a left ~20% split.
set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"
PARKING_LABEL="tui_chat"
PANE_LABEL="twitchchat"
DIR="${TWITCHCHAT_DIR:-$HOME/dev/projects/TwitchChat}"
CMD="${TWITCHCHAT_CMD:-exec bun run dev}"
# first-child ratio before swap → chat ends at left 20%
RATIO="0.2"

json_field() {
	# json_field <json> <jq-filter>
	jq -er "$2" <<<"$1"
}

herdr_json() {
	"$HERDR" "$@"
}

notify() {
	local title="$1"
	local body="${2:-}"
	if "$HERDR" notification show "$title" --body "$body" >/dev/null 2>&1; then
		return 0
	fi
	printf '%s: %s\n' "$title" "$body" >&2 || true
}

snapshot_json() {
	herdr_json api snapshot
}

active_tab_id() {
	if [ -n "${HERDR_ACTIVE_TAB_ID:-}" ]; then
		printf '%s\n' "$HERDR_ACTIVE_TAB_ID"
		return
	fi
	json_field "$(snapshot_json)" '.result.snapshot.focused_tab_id'
}

active_pane_id() {
	if [ -n "${HERDR_ACTIVE_PANE_ID:-}" ]; then
		printf '%s\n' "$HERDR_ACTIVE_PANE_ID"
		return
	fi
	json_field "$(snapshot_json)" '.result.snapshot.focused_pane_id'
}

find_chat_pane() {
	herdr_json pane list |
		jq -er --arg label "$PANE_LABEL" '
			.result.panes[]
			| select(.label == $label)
			| .pane_id
		' 2>/dev/null | head -n1 || true
}

pane_info() {
	local pane_id="$1"
	herdr_json pane get "$pane_id"
}

pane_tab_id() {
	json_field "$(pane_info "$1")" '.result.pane.tab_id'
}

pane_workspace_id() {
	json_field "$(pane_info "$1")" '.result.pane.workspace_id'
}

tab_pane_count() {
	local tab_id="$1"
	herdr_json pane list |
		jq -er --arg tab "$tab_id" '
			[.result.panes[] | select(.tab_id == $tab)] | length
		'
}

find_parking_workspace() {
	herdr_json workspace list |
		jq -er --arg label "$PARKING_LABEL" '
			.result.workspaces[]
			| select(.label == $label)
			| .workspace_id
		' 2>/dev/null | head -n1 || true
}

mark_pane() {
	local pane_id="$1"
	herdr_json pane rename "$pane_id" "$PANE_LABEL" >/dev/null
}

move_result_pane_id() {
	json_field "$1" '.result.move_result.pane.pane_id'
}

move_changed() {
	json_field "$1" '.result.move_result.changed'
}

move_reason() {
	jq -r '.result.move_result.reason // empty' <<<"$1"
}

ensure_placeholder() {
	# Keep a tab alive when we are about to move its only pane away.
	local tab_id="$1"
	local count
	count="$(tab_pane_count "$tab_id")"
	if [ "$count" -le 1 ]; then
		local any_pane
		any_pane="$(
			herdr_json pane list |
				jq -er --arg tab "$tab_id" '
					.result.panes[]
					| select(.tab_id == $tab)
					| .pane_id
				' | head -n1
		)"
		herdr_json pane split "$any_pane" --direction down --ratio 0.9 --no-focus >/dev/null
	fi
}

create_chat_in_parking() {
	local created root_pane parking_ws
	created="$(herdr_json workspace create --cwd "$DIR" --label "$PARKING_LABEL" --no-focus)"
	root_pane="$(json_field "$created" '.result.root_pane.pane_id')"
	parking_ws="$(json_field "$created" '.result.workspace.workspace_id')"
	mark_pane "$root_pane"
	herdr_json pane run "$root_pane" "$CMD" >/dev/null
	# Give the shell a moment to exec; label is already set.
	printf '%s\n' "$root_pane"
	# silence unused in case callers only need pane
	: "$parking_ws"
}

ensure_chat_pane() {
	local pane_id
	pane_id="$(find_chat_pane)"
	if [ -n "$pane_id" ]; then
		printf '%s\n' "$pane_id"
		return
	fi

	# Stale parking workspace without a labeled chat — close and recreate.
	local parking_ws
	parking_ws="$(find_parking_workspace)"
	if [ -n "$parking_ws" ]; then
		herdr_json workspace close "$parking_ws" >/dev/null 2>&1 || true
	fi

	create_chat_in_parking
}

close_extra_parking_tabs() {
	# After parking the chat in a fresh tab, drop leftover placeholder tabs.
	local parking_ws="$1"
	local keep_tab="$2"
	local tab_id
	herdr_json tab list --workspace "$parking_ws" 2>/dev/null |
		jq -r --arg keep "$keep_tab" '
			.result.tabs[]
			| select(.tab_id != $keep)
			| .tab_id
		' 2>/dev/null |
		while IFS= read -r tab_id; do
			[ -n "$tab_id" ] || continue
			herdr_json tab close "$tab_id" >/dev/null 2>&1 || true
		done
}

hide_chat() {
	local pane_id="$1"
	local parking_ws move_json new_id reason chat_tab

	parking_ws="$(find_parking_workspace)"
	if [ -z "$parking_ws" ]; then
		move_json="$(
			herdr_json pane move "$pane_id" \
				--new-workspace \
				--label "$PARKING_LABEL" \
				--tab-label chat \
				--no-focus
		)"
	else
		# If chat is already alone in parking, nothing to do.
		if [ "$(pane_workspace_id "$pane_id")" = "$parking_ws" ]; then
			return 0
		fi
		move_json="$(
			herdr_json pane move "$pane_id" \
				--new-tab \
				--workspace "$parking_ws" \
				--label chat \
				--no-focus
		)"
	fi

	if [ "$(move_changed "$move_json")" != "true" ]; then
		reason="$(move_reason "$move_json")"
		notify "twitchchat" "hide failed${reason:+ ($reason)}"
		return 1
	fi

	new_id="$(move_result_pane_id "$move_json")"
	mark_pane "$new_id"

	chat_tab="$(json_field "$move_json" '.result.move_result.pane.tab_id')"
	parking_ws="$(json_field "$move_json" '.result.move_result.pane.workspace_id')"
	close_extra_parking_tabs "$parking_ws" "$chat_tab"
}

show_chat() {
	local pane_id="$1"
	local active_tab active_pane src_tab move_json new_id reason

	active_tab="$(active_tab_id)"
	active_pane="$(active_pane_id)"
	src_tab="$(pane_tab_id "$pane_id")"

	ensure_placeholder "$src_tab"

	# Re-resolve pane id after placeholder split (id unchanged, but be safe).
	pane_id="$(find_chat_pane)"
	if [ -z "$pane_id" ]; then
		notify "twitchchat" "pane disappeared before show"
		return 1
	fi

	move_json="$(
		herdr_json pane move "$pane_id" \
			--tab "$active_tab" \
			--target-pane "$active_pane" \
			--split right \
			--ratio "$RATIO" \
			--no-focus
	)"

	if [ "$(move_changed "$move_json")" != "true" ]; then
		reason="$(move_reason "$move_json")"
		notify "twitchchat" "show failed${reason:+ ($reason)}"
		return 1
	fi

	new_id="$(move_result_pane_id "$move_json")"
	# Layout after move@0.2: original left 20%, chat right 80%.
	# Swap puts chat on the left while keeping the 20% geometry.
	herdr_json pane swap --pane "$new_id" --direction left >/dev/null
	mark_pane "$new_id"
	# Swap focuses the moved pane; kick focus back to the original (now right).
	herdr_json pane focus --pane "$new_id" --direction right >/dev/null 2>&1 || true
}

main() {
	if ! command -v jq >/dev/null 2>&1; then
		notify "twitchchat" "jq is required"
		exit 1
	fi

	if [ ! -d "$DIR" ]; then
		notify "twitchchat" "missing dir: $DIR"
		exit 1
	fi

	local pane_id active_tab chat_tab
	pane_id="$(ensure_chat_pane)"
	if [ -z "$pane_id" ]; then
		notify "twitchchat" "failed to create pane"
		exit 1
	fi

	# Refresh after ensure (create path already returns id).
	pane_id="$(find_chat_pane)"
	if [ -z "$pane_id" ]; then
		notify "twitchchat" "failed to find pane"
		exit 1
	fi

	active_tab="$(active_tab_id)"
	chat_tab="$(pane_tab_id "$pane_id")"

	if [ "$chat_tab" = "$active_tab" ]; then
		hide_chat "$pane_id"
	else
		show_chat "$pane_id"
	fi
}

main "$@"
