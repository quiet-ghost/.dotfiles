#!/usr/bin/env bash

set -euo pipefail

config_target="$HOME/.cloudflared/config.yml"
service_target="$HOME/.config/systemd/user/cloudflared-stream-dev.service"
credentials="$HOME/.cloudflared/f7fe8dd4-cfd7-4e29-90ee-48140f5ca134.json"

if [[ ! -f "$config_target" || ! -f "$service_target" ]]; then
  printf 'Cloudflared config or service is not deployed; run stow home first.\n' >&2
  exit 1
fi

if [[ ! -f "$credentials" ]]; then
  printf 'Missing stream-dev tunnel credentials: %s\n' "$credentials" >&2
  exit 1
fi

cloudflared tunnel --config "$config_target" ingress validate
systemctl --user daemon-reload
systemctl --user enable --now cloudflared-stream-dev.service
