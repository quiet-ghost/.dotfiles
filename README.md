# Dotfiles

Personal Arch Linux and Omarchy development environment, managed as one [GNU Stow](https://www.gnu.org/software/stow/) package.

## Overview

The repository mirrors `$HOME` under `home/`. This keeps the root small and makes deployment a single operation.

```text
.
├── home/       # deployable files that mirror $HOME
├── extras/     # source material and stateful installers
├── AGENTS.md   # repository guidance
├── README.md
└── LICENSE
```

`home/` includes configuration for Hyprland, Neovim, Herdr, Zsh, Ghostty, OpenCode, Pi, Tmux, Waybar, and other daily tools. Shared agent skills deploy to `~/.agents/skills/` for native OpenCode and Pi discovery.

`extras/` contains material that should not be linked into `$HOME`:

- `keyboard/` contains keyboard source files and installation notes.
- `templates/` provides inputs for `repo-init`.
- `cloudflared/` contains privileged, stateful deployment tooling.

## Install

```bash
sudo pacman -S git stow
git clone --recurse-submodules https://github.com/quiet-ghost/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
stow --simulate home
stow home
```

These files describe my machines, not a universal installer. Review SSH, systemd, desktop, hardware, and network configuration before deploying them elsewhere.

## Update

```bash
git pull --recurse-submodules
git submodule update --init --recursive
stow -R home
```

### Migrating From The Old Layout

Clones from before the single-package migration must unlink the old packages before pulling the commit that removes them:

```bash
cd ~/.dotfiles
stow -D agents applications atuin background bat bin bun gh-dash ghostty git \
  herdr hypr mise mux-sesh nvim omarchy opencode pi ssh starship swayosd \
  systemd tmux uwsm walker waybar zsh
git pull --recurse-submodules
git submodule update --init --recursive
stow home
```

This is a one-time migration. New clones use only `stow home`.

## Remove

```bash
stow -D home
```

Unstowing removes managed links. It does not remove application state, installed packages, or enabled services.

## Systemd

User unit files live under `home/.config/systemd/user/`, but enablement remains host-local:

```bash
systemctl --user daemon-reload
systemctl --user enable --now <unit>.service
```

Some units depend on machine-specific hardware or scripts. Inspect them before enabling.

## Checks

There is no repo-wide build or CI command. Validate the component changed.

```bash
# Herdr attach proxy
python3 home/.config/herdr/scripts/test_herdr_attach_proxy.py

# Pi TypeScript extensions
cd home/.pi
npm run check
```

## Privacy

Credentials, sessions, logs, caches, dependencies, backups, and private environment files are ignored. Public configuration can still reveal usernames, hosts, domains, ports, and project names. Inspect changes and scan Git history before publishing.
