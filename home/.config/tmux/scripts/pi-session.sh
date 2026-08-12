#!/usr/bin/env bash

sanitize_name() {
	printf '%s' "$1" | tr '/ ' '--' | tr -cd '[:alnum:]-_'
}

get_session_name() {
	local current_path="$1"
	local repo_root
	local common_dir
	local common_root
	local repo_name
	local worktree_name

	repo_root=$(cd "$current_path" && git rev-parse --show-toplevel 2>/dev/null)
	if [ -z "$repo_root" ]; then
		echo "pi-$(sanitize_name "$(basename "$current_path")")"
		return
	fi

	common_dir=$(cd "$current_path" && git rev-parse --git-common-dir 2>/dev/null || true)
	if [ -n "$common_dir" ]; then
		common_root=$(dirname "$(cd "$current_path" && realpath "$common_dir")")
	else
		common_root="$repo_root"
	fi

	repo_name=$(sanitize_name "$(basename "$common_root")")

	case "$repo_root" in
		"$common_root/.worktrees/"*)
			worktree_name="${repo_root#"$common_root/.worktrees/"}"
			worktree_name=$(sanitize_name "$worktree_name")
			if [ -n "$worktree_name" ]; then
				echo "pi-${repo_name}-${worktree_name}"
			else
				echo "pi-${repo_name}"
			fi
			;;
		*)
			echo "pi-${repo_name}"
			;;
	esac
}
current_path="${1:-$PWD}"
session_name=$(get_session_name "$current_path")

if ! tmux has-session -t "$session_name" 2>/dev/null; then
	tmux new-session -d -s "$session_name" -c "$current_path" pi
fi

# Create popup and attach to session
exec tmux display-popup -E -w 90% -h 90% "tmux attach-session -t $session_name"
