#!/bin/bash

# Check if we're in tmux
if [ -z "$TMUX" ]; then
	exit 0
fi

# Get the current pane's command
PANE_PID=$(tmux display-message -p '#{pane_pid}')
PANE_CMD=$(ps -o comm= -p $(pgrep -P $PANE_PID 2>/dev/null) 2>/dev/null | head -1)

# Get current window name
CURRENT_NAME=$(tmux display-message -p '#W')

# Check if SSH or mosh is running in the current pane
if [[ "$PANE_CMD" == "ssh" ]] || [[ "$PANE_CMD" == "mosh-client" ]]; then
	# If window doesn't already have SSH marker, add it
	if [[ "$CURRENT_NAME" != "󰣀 "* ]] && [[ "$CURRENT_NAME" != "SSH:"* ]]; then
		# Try to get the SSH host from the process
		SSH_PROCESS=$(ps -o args= -p $(pgrep -P $PANE_PID 2>/dev/null) 2>/dev/null | grep -E '(ssh|mosh)' | head -1)
		if [[ -n "$SSH_PROCESS" ]]; then
			# Extract hostname from SSH command
			HOST=$(echo "$SSH_PROCESS" | sed -E 's/.*@([^ ]+).*/\1/' | sed -E 's/.*ssh[[:space:]]+([^ ]+).*/\1/')
			if [[ "$HOST" != "$SSH_PROCESS" ]]; then
				tmux rename-window "󰣀  ${HOST%%.*}"
			else
				tmux rename-window "󰣀  SSH"
			fi
		else
			tmux rename-window "󰣀  SSH"
		fi
	fi
else
	# Remove SSH marker if it exists and restore original name
	if [[ "$CURRENT_NAME" == "󰣀 "* ]] || [[ "$CURRENT_NAME" == "SSH:"* ]]; then
		# Default back to shell name or "zsh"
		tmux rename-window "$(basename $SHELL)"
	fi
fi
