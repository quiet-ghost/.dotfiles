#!/usr/bin/env bash
set -euo pipefail

SESSION="tui_chat"
DIR="$HOME/dev/projects/TwitchChat"
PERCENT=20
TAG="@twitchchat"

find_chat_pane() {
	tmux list-panes -a -F "#{pane_id} #{${TAG}}" 2>/dev/null |
		awk '$2 == "1" { print $1; exit }'
}

mark_pane() {
	tmux set-option -p -t "$1" "$TAG" 1
}

pane_in_current_window() {
	local pane_id="$1"
	tmux list-panes -F '#{pane_id}' 2>/dev/null | grep -qx "$pane_id"
}

ensure_placeholder() {
	local target="$1"
	local count
	count=$(tmux list-panes -t "$target" 2>/dev/null | wc -l)
	if [ "$count" -le 1 ]; then
		tmux split-window -t "$target" -d -l 1 "exec sleep infinity"
	fi
}

ensure_session() {
	if tmux has-session -t "=$SESSION" 2>/dev/null; then
		return
	fi
	tmux new-session -d -s "$SESSION" -n chat -c "$DIR" "bun run dev"
	mark_pane "=$SESSION:chat"
}

hide_chat() {
	local pane_id="$1"

	if ! tmux has-session -t "=$SESSION" 2>/dev/null; then
		tmux new-session -d -s "$SESSION" -n chat -c "$DIR" "exec sleep infinity"
	fi

	if ! tmux list-windows -t "=$SESSION" -F '#{window_name}' 2>/dev/null | grep -qx chat; then
		tmux new-window -d -t "=$SESSION" -n chat -c "$DIR" "exec sleep infinity"
	fi

	tmux join-pane -s "$pane_id" -t "=$SESSION:chat"
	mark_pane "$pane_id"

	tmux list-panes -t "=$SESSION:chat" -F "#{pane_id} #{pane_current_command} #{${TAG}}" |
		awk '$3 != "1" { print $1 }' |
		while read -r extra; do
			tmux kill-pane -t "$extra" 2>/dev/null || true
		done
}

show_chat() {
	local pane_id="$1"
	local src_win
	src_win=$(tmux display-message -t "$pane_id" -p '#{session_name}:#{window_index}')
	ensure_placeholder "$src_win"
	tmux join-pane -hb -l "${PERCENT}%" -s "$pane_id"
	mark_pane "$pane_id"
}

ensure_session
pane_id=$(find_chat_pane)

if [ -z "$pane_id" ]; then
	tmux kill-session -t "=$SESSION" 2>/dev/null || true
	ensure_session
	pane_id=$(find_chat_pane)
fi

if [ -z "$pane_id" ]; then
	tmux display-message "twitchchat: failed to create pane"
	exit 1
fi

if pane_in_current_window "$pane_id"; then
	hide_chat "$pane_id"
else
	show_chat "$pane_id"
fi
