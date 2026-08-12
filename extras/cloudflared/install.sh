#!/bin/bash
# ~/.dotfiles/extras/cloudflared/install.sh

HOSTNAME=$(hostname)

#tunnel:
cloudflared tunnel create ${HOSTNAME}-tunnel

#DNS:
cloudflared tunnel route ${HOSTNAME}-tunnel ${HOSTNAME}-quietghost.dev
cloudflared tunnel route ${HOSTNAME}-tunnel ${HOSTNAME}-obs.quietghost.dev

#install:
sudo cloudflared service install

#Symlink:
ln -s ~/.dotfiles/extras/cloudflared/config.yaml ~/.cloudflared/config.yaml
