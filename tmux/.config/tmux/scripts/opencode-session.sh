#!/bin/bash

get_session_name() {
	local current_path="$1"
	local repo_root
	repo_root=$(cd "$current_path" && git rev-parse --show-toplevel 2>/dev/null)
	if [ -z "$repo_root" ]; then
		echo "opencode-$(basename "$current_path" | tr " " "-" | tr -cd "[:alnum:]-_")"
		return
	fi
	local repo_name
	repo_name=$(basename "$repo_root" | tr " " "-" | tr -cd "[:alnum:]-_")
	if [[ "$current_path" == *"/.worktree/"* ]]; then
		local worktree_path
		worktree_path=$(echo "$current_path" | sed 's|.*/.worktree/\([^/]*\).*|\1|')
		if [ -n "$worktree_path" ]; then
			local clean_branch
			clean_branch=$(echo "$worktree_path" | tr " " "-" | tr -cd "[:alnum:]-_")
			echo "opencode-${repo_name}-${clean_branch}"
		else
			echo "opencode-${repo_name}"
		fi
	else
		echo "opencode-${repo_name}"
	fi
}
current_path="${1:-$PWD}"
session_name=$(get_session_name "$current_path")

if ! tmux has-session -t "$session_name" 2>/dev/null; then
	tmux new-session -d -s "$session_name" -c "$current_path" opencode
fi

# Create popup and attach to session
exec tmux display-popup -E -w 90% -h 90% "tmux attach-session -t $session_name"
