#!/usr/bin/env bash

set -uo pipefail

history_dir="${OMARCHY_MESSAGES_HISTORY_DIR:-$HOME/.local/state/omarchy/notifications/history}"

if [[ ! -d "$history_dir" ]]; then
  printf '[]\n'
  exit 0
fi

find "$history_dir" -maxdepth 1 -type f -name '*.json' -print0 \
  | sort -z -r \
  | head -z -n 10 \
  | while IFS= read -r -d '' file; do
      jq -c 'select(type == "object")' "$file" 2>/dev/null || true
    done \
  | jq -s 'sort_by(.timestamp // 0) | reverse'
