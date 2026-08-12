#!/usr/bin/env bash

sanitize_name() {
	printf '%s' "$1" | tr '/ ' '--' | tr -cd '[:alnum:]-_'
}

get_session_name() {
	local current_path="$1"
	local suffix

	if [[ -f "$HOME/.local/lib/wt-paths.sh" ]]; then
		# shellcheck source=/dev/null
		source "$HOME/.local/lib/wt-paths.sh"
		suffix="$(wt_path_suffix "$current_path")"
	else
		suffix="$(sanitize_name "$(basename "$current_path")")"
	fi

	printf 'pi-%s\n' "$suffix"
}
current_path="${1:-$PWD}"
session_name=$(get_session_name "$current_path")

if ! tmux has-session -t "$session_name" 2>/dev/null; then
	tmux new-session -d -s "$session_name" -c "$current_path" pi
fi

# Create popup and attach to session
exec tmux display-popup -E -w 90% -h 90% "tmux attach-session -t $session_name"
