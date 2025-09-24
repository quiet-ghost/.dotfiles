#!/bin/bash
# ~/.dotfiles/cloudflared/install.sh

HOSTNAME=$(hostname)

#tunnel:
cloudflared tunnel create ${HOSTNAME}-tunnel

#DNS:
cloudflared tunnel route ${HOSTNAME}-tunnel ${HOSTNAME}-quigghost.dev
cloudflared tunnel route ${HOSTNAME}-tunnel ${HOSTNAME}-obs.quietghost.dev

#install:
sudo cloudflared service install

#Symlink:
ln -s ~/.dotfiles/cloudflared/config.yaml ~/.cloudflared/config.yaml
