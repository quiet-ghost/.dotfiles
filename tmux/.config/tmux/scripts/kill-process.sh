#!/bin/bash

# Enhanced process killer with clean fzf interface
# Similar to vk alias but with better formatting and preview

# Get processes with clean command formatting (no file paths)
get_processes() {
    ps -eo pid,user,%cpu,%mem,args --no-headers --sort=-%cpu | \
    awk '{
        # Extract full command line
        full_cmd = ""
        for(i=5; i<=NF; i++) full_cmd = full_cmd " " $i
        full_cmd = substr(full_cmd, 2) # Remove leading space
        
        # Extract just the command name (remove path)
        split($5, path_parts, "/")
        cmd_name = path_parts[length(path_parts)]
        
        # Get arguments (everything after the command)
        args = ""
        for(i=6; i<=NF; i++) args = args " " $i
        
        # Clean up common argument patterns
        gsub(/--config [^ ]*\//, "--config ", args)
        gsub(/\/[^ ]*\/([^\/]+)$/, "\\1", args)
        
        # Combine command and args
        display_cmd = cmd_name args
        
        # Truncate if too long
        if(length(display_cmd) > 45) {
            display_cmd = substr(display_cmd, 1, 42) "..."
        }
        
        printf "%-8s %-12s %6s %6s %s\n", $1, $2, $3"%", $4"%", display_cmd
    }'
}

# Main fzf interface with Material Deep Ocean/Catppuccin theming
selected=$(get_processes | \
    fzf --multi \
        --ansi \
        --reverse \
        --height=100% \
        --border=rounded \
        --prompt="󰯈 Kill Process > " \
        --header="PID      USER         %CPU   %MEM  COMMAND & ARGS" \
        --header-lines=0 \
        --padding=1 \
        --color='bg+:#313244,bg:#1e1e2e,spinner:#74c7ec,hl:#89b4fa' \
        --color='fg:#cdd6f4,header:#74c7ec,info:#89b4fa,pointer:#74c7ec' \
        --color='marker:#74c7ec,fg+:#cdd6f4,prompt:#89b4fa,hl+:#89b4fa' \
        --color='border:#6c7086' \
        --bind='ctrl-r:reload(ps -eo pid,user,%cpu,%mem,args --no-headers --sort=-%cpu | awk "{full_cmd=\"\"; for(i=5;i<=NF;i++) full_cmd=full_cmd\" \"\$i; full_cmd=substr(full_cmd,2); split(\$5,path_parts,\"/\"); cmd_name=path_parts[length(path_parts)]; args=\"\"; for(i=6;i<=NF;i++) args=args\" \"\$i; gsub(/--config [^ ]*\\//,\"--config \",args); display_cmd=cmd_name args; if(length(display_cmd)>45) display_cmd=substr(display_cmd,1,42)\"...\"; printf \"%-8s %-12s %6s %6s %s\\n\", \$1, \$2, \$3\"%\", \$4\"%\", display_cmd}")' \
        --bind='ctrl-a:select-all' \
        --bind='ctrl-d:deselect-all' \
        --info=inline \
        --layout=reverse)

# Exit if nothing selected
if [ -z "$selected" ]; then
    exit 0
fi

# Extract PIDs and kill silently
pids=$(echo "$selected" | awk '{print $1}' | tr '\n' ' ')

for pid in $pids; do
    kill -9 "$pid" 2>/dev/null
done

# Restart the process selector immediately (keeps popup open)
exec "$0"