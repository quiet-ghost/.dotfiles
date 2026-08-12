# Dotfiles

Personal Arch Linux and Omarchy development environment, managed as one [GNU Stow](https://www.gnu.org/software/stow/) package.

This branch is the Omarchy 4/Quattro profile. Deploy it only after upgrading to Quattro.

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

`home/` includes configuration for Hyprland, Neovim, Herdr, Zsh, Ghostty, OpenCode, Pi, Tmux, and other daily tools. Shared agent skills deploy to `~/.agents/skills/` for native OpenCode and Pi discovery.

On this branch, Hyprland starts at `home/.config/hypr/hyprland.lua`. Custom Quickshell plugins live under `home/.config/omarchy/` and replace the retired Waybar, Walker, SwayOSD, Hypridle, and Hyprlock stack. The generated `~/.local/state/omarchy/current` tree is intentionally not versioned.

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

## Future Quattro Upgrade Runbook

Before upgrading, stop and disable the custom idle service because upstream will not retire it:

```bash
systemctl --user disable --now hypridle-custom.service
```

Complete the upgrade and confirm stock Omarchy 4 boots successfully before stowing this profile.

Quattro deletes `~/.config/uwsm/env`. Do not restow a replacement. Session env comes from `/usr/share/uwsm/env.d/10-omarchy`; keep personal overrides in `home/.config/uwsm/default`. After stow, re-apply the theme so generated templates refresh.

`omarchy-idle-policy` keeps desktops in persistent stay-awake mode. Laptops use the shell screensaver and lock at 900/902 seconds, then suspend around 1500 seconds; Quattro lock handles display blanking.

> **Monitor config:** Machine-specific identifiers belong only in ignored `home/.config/hypr/monitors_local.lua`. Public clones should copy the example and fill in local values.

```bash
cp home/.config/hypr/monitors_local.lua.example home/.config/hypr/monitors_local.lua
stow --simulate --verbose --target="$HOME" home
```

`home/.stow-local-ignore` prevents known runtime and generated files from deployment. Still inspect every simulated change, then omit `--simulate` only when all changes are expected:

```bash
stow --verbose --target="$HOME" home
systemctl --user enable --now syncthing.service
```

The post-Stow command is required because Syncthing enablement stays host-local.

The upgrade may create regular files where Stow needs to place symlinks, causing conflicts. Back up and remove only those conflicting files, keeping the backups outside Stow-managed destinations.

> **Never use `stow --adopt`.** It can replace repository files with upgrade-created destination content.

Install Cloudflared separately because it is stateful:

```bash
./extras/cloudflared/install.sh
```

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

## Custom Scripts

Located in `home/.local/bin/`:

- **Project aliases and workflows** - `gh-issue-create-smart`, `gh-pr-create-smart`, `gh-pr-review-session`, `gh-repo-path`, `repo-init`, `wd`, `wl`, `wt`, `wtdd`, `wti`, and `wtpr`
- **Display automation** - `hypr-display-monitor`, `hypr-display-switch`, `hypr-elgato-sanitize`, `hypr-elgato-watch`, and `hypr-odyssey-240`
- **Idle and timer helpers** - `omarchy-idle-policy` and `omarchy-timer`
- **Pi helper** - `pi`
- **Tmux helpers** - `tmux-kill-session`, `tmux-sessionizer`, and `tmux-switch-session`
- **System/project helpers** - `aur-install`, `cookiecutter-cpp`, `install_javafx_template.sh`, `kill-process`, `lutris`, `new-clion`, `new-cpp`, `new-java`, and `new-rust`

Third-party binaries, package-manager outputs, `node_modules`, generated wrappers, and secrets do not belong in this Stow package.

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
