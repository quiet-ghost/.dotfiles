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
		echo "#[fg=#f38ba8,bg=default]󰣀 ${SSH_HOST}"
	else
		echo "#[fg=#f38ba8,bg=default]󰣀 SSH"
	fi
else
	echo "#[fg=#89b4fa,bg=default]󰒋 $(hostname -s)"
fi
else
	# Local session - show with blue computer icon
	echo "#[fg=#89b4fa,bg=#313244]█#[fg=default,bg=#89b4fa]󰒋 #[fg=#cdd6f4,bg=#1e1e2e] $(hostname -s) "
fi
