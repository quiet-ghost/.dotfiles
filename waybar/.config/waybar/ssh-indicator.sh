#!/usr/bin/env bash

# Check for active SSH client connections (not ssh-agent or sshd)
ssh_process=$(pgrep -a -u $USER ssh | grep -v "ssh-agent" | grep "ssh " | head -n1)

if [ -n "$ssh_process" ]; then
	# Extract the hostname from the SSH command
	# Format is typically: "12345 ssh user@host" or "12345 ssh host"
	hostname=$(echo "$ssh_process" | sed -n 's/.*ssh[[:space:]]\+\([^[:space:]]*@\)\?\([^[:space:]]\+\).*/\2/p')

	if [ -n "$hostname" ]; then
		echo "{\"text\":\"  - $hostname \",\"class\":\"ssh-active\",\"tooltip\":\"SSH: $hostname\"}"

	else
		echo "{\"text\":\"  -   \",\"class\":\"ssh-inactive\",\"tooltip\":\"Local session\"}"
	fi
else
	# No active SSH connection
	echo "{\"text\":\"  -   \",\"class\":\"ssh-inactive\",\"tooltip\":\"Local session\"}"
fi
