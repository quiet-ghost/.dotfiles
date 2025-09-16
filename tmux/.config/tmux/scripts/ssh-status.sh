#!/bin/bash

# Get the current active pane's tty
PANE_TTY=$(tmux display-message -p '#{pane_tty}')
TTY_NAME="${PANE_TTY##*/}"

# Check all processes in the current pane for SSH
SSH_FOUND=0
SSH_HOST=""

# Get all processes running in this tty
for pid in $(ps -t "$TTY_NAME" -o pid= 2>/dev/null); do
	if [[ -n "$pid" ]]; then
		# Check if this is an ssh process
		CMD=$(ps -p "$pid" -o comm= 2>/dev/null)
		if [[ "$CMD" == "ssh" ]]; then
			SSH_FOUND=1
			# Try to get the hostname from the ssh command
			ARGS=$(ps -p "$pid" -o args= 2>/dev/null)
			# Extract hostname (handles user@host and just host)
			SSH_HOST=$(echo "$ARGS" | sed -E 's/.*ssh[[:space:]]+([^@[:space:]]+@)?([^[:space:]]+).*/\2/' | cut -d. -f1 | cut -d: -f1)
			break
		fi
	fi
done

if [[ $SSH_FOUND -eq 1 ]]; then
	if [[ -n "$SSH_HOST" ]] && [[ "$SSH_HOST" != "ssh" ]]; then
		# SSH session with known host - show with red lock icon
		echo "#[fg=#f38ba8,bg=#313244]█#[fg=#1e1e2e,bg=#f38ba8]󰣀  #[fg=#cdd6f4,bg=#313244] ${SSH_HOST} "
	else
		# SSH session but couldn't parse host
		echo "#[fg=#f38ba8,bg=#313244]█#[fg=#1e1e2e,bg=#f38ba8]󰣀  #[fg=#cdd6f4,bg=#313244] SSH "
	fi
else
	# Local session - show with blue computer icon
	echo "#[fg=#89b4fa,bg=#313244]█#[fg=#1e1e2e,bg=#89b4fa]󰒋 #[fg=#cdd6f4,bg=#313244] $(hostname -s) "
fi
