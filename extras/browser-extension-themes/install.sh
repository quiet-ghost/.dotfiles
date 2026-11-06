#!/usr/bin/env bash

set -euo pipefail
export PATH=/usr/bin:/usr/sbin

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
policy=/etc/chromium/policies/managed/color.json
backup=/var/lib/browser-extension-themes/color.json.bak

if (( EUID != 0 )); then
  printf 'Run sudo bash extras/browser-extension-themes/install.sh from the dotfiles root. Browser settings have not changed.\n' >&2
  exit 1
fi

systemd-analyze verify "$source_dir/browser-extension-themes.path" "$source_dir/browser-extension-themes.service"

if [[ -f $policy && ! -e $backup ]]; then
  install -d -m 0700 -o root -g root "${backup%/*}"
  install -m 0600 -o root -g root "$policy" "$backup"
fi

install -m 0644 -o root -g root \
  "$source_dir/browser-extension-themes.path" \
  "$source_dir/browser-extension-themes.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now browser-extension-themes.path
systemctl start browser-extension-themes.service
systemctl is-active --quiet browser-extension-themes.path

if [[ -e $policy ]]; then
  printf 'Browser theme guard did not remove %s. Inspect journalctl -u browser-extension-themes.service; browser profiles are unchanged.\n' "$policy" >&2
  exit 1
fi

printf 'Browser theme guard enabled. Chromium and Helium can use extension themes.\n'
