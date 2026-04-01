#!/usr/bin/env bash

set -euo pipefail

ssh_process=$(pgrep -a -u "$USER" ssh | grep -v "ssh-agent" | grep -E "ssh( |$)" | head -n1 || true)

[[ -n "$ssh_process" ]] || exit 0

ssh_pid=${ssh_process%% *}
ssh_command=${ssh_process#* }

ss_output=$(ss -Htnp 2>/dev/null | grep "pid=$ssh_pid," | grep ESTAB | head -n1 || true)

[[ -n "$ss_output" ]] || exit 0

hostname=$(sed -n 's/.*ssh[[:space:]]\+\([^[:space:]]*@\)\?\([^[:space:]-][^[:space:]]*\).*/\2/p' <<<"$ssh_command")

if [[ -z "$hostname" ]]; then
  remote_address=$(awk '{print $5}' <<<"$ss_output")
  hostname=${remote_address%:*}
fi

[[ -n "$hostname" ]] || exit 0

printf '{"text":"ssh: %s","class":"ssh-active","tooltip":"SSH: %s"}\n' "$hostname" "$hostname"
