#!/bin/bash
NOTES_SESSION="notes"
NOTES_DIR="$HOME/personal/Notes/Imports"

# Ensure the notes directory exists
mkdir -p "$NOTES_DIR"

# Check if notes session exists
if ! tmux has-session -t $NOTES_SESSION 2>/dev/null; then
	# Create notes session with neovim in the Import directory
	tmux new-session -d -s $NOTES_SESSION -c "$NOTES_DIR" "nvim ."
fi

# Attach to the notes session
tmux attach-session -t $NOTES_SESSION
