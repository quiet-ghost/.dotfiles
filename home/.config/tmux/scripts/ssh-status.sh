#!/bin/bash

set -euo pipefail

local_hostname=$(hostname -s)
pane_pid=$(tmux display-message -p '#{pane_pid}')

ssh_pid=""
ssh_command=""

find_ssh_process() {
  local parent_pid=$1
  local child_pid command_name

  while read -r child_pid; do
    [[ -n $child_pid ]] || continue

    command_name=$(ps -p "$child_pid" -o comm= 2>/dev/null)
    if [[ $command_name == "ssh" ]]; then
      ssh_pid=$child_pid
      ssh_command=$(ps -p "$child_pid" -o args= 2>/dev/null)
      return 0
    fi

    find_ssh_process "$child_pid" && return 0
  done < <(ps -o pid= --ppid "$parent_pid" 2>/dev/null)

  return 1
}

find_ssh_process "$pane_pid" || true

if [[ -n $ssh_pid ]]; then
  ss_output=$(ss -Htnp 2>/dev/null | grep "pid=$ssh_pid," | grep ESTAB | head -n1 || true)
else
  ss_output=""
fi

if [[ -n $ss_output ]]; then
  remote_hostname=$(sed -n 's/.*ssh[[:space:]]\+\([^[:space:]]*@\)\?\([^[:space:]-][^[:space:]]*\).*/\2/p' <<<"$ssh_command")

  if [[ -z $remote_hostname ]]; then
    remote_address=$(awk '{print $5}' <<<"$ss_output")
    remote_hostname=${remote_address%:*}
  fi

  if [[ -n $remote_hostname ]]; then
    printf '#[fg=#6c7086,bg=#191724]%s#[fg=#eb6f92,bg=#191724] -> %s' "$local_hostname" "$remote_hostname"
    exit 0
  fi
fi

printf '#[fg=#6c7086,bg=#191724]%s' "$local_hostname"
