# Ghost's Dotfiles

Personal configuration for Arch Linux with [Omarchy](https://omarchy.org/), managed as explicit [GNU Stow](https://www.gnu.org/software/stow/) packages.

These files describe my machines. They are a reference, not a universal installer. Review each package before deploying it.

## System

- **OS:** Arch Linux with Omarchy
- **Desktop:** Hyprland on Wayland
- **Terminal:** Ghostty
- **Shell:** Zsh
- **Editor:** Neovim with LazyVim
- **Workspace manager:** Herdr, with Tmux retained

## Layout

Most top-level directories are independent Stow packages whose contents mirror paths below `$HOME`.

| Area | Packages |
| --- | --- |
| Desktop | `applications`, `background`, `ghostty`, `hypr`, `omarchy`, `swayosd`, `uwsm`, `walker`, `waybar` |
| Shell and CLI | `atuin`, `bat`, `bin`, `bun`, `git`, `mise`, `starship`, `zsh` |
| Editors and workspaces | `herdr`, `mux-sesh`, `nvim`, `tmux` |
| Agents | `agents`, `opencode`, `pi` |
| Services | `systemd` |

Shared agent skills live at `agents/.agents/skills/`. Stowing `agents` deploys them to the cross-tool standard `~/.agents/skills/`, which OpenCode and Pi discover natively.

The following directories are not normal Stow packages:

- `keyboard/` contains keyboard source material and documentation.
- `templates/` provides input for `repo-init`.
- `cloudflared/` contains privileged, stateful deployment tooling.

## Install

Install Git and Stow, then clone with submodules:

```bash
sudo pacman -S git stow
git clone --recurse-submodules https://github.com/quiet-ghost/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

Deploy only packages appropriate for the current host:

```bash
stow --simulate agents nvim zsh git
stow agents nvim zsh git
```

Desktop example:

```bash
stow hypr waybar walker ghostty swayosd uwsm omarchy
```

Never run `stow */`. It includes source-only and stateful directories.

## Update

```bash
git pull --recurse-submodules
git submodule update --init --recursive
stow -R agents nvim zsh git
```

## Remove

```bash
stow -D agents nvim
```

Unstowing removes managed links. It does not remove application state or installed packages.

## Special Cases

### Systemd

The `systemd` package deploys user unit files only. Enable services explicitly on each host so machine state does not enter the repository:

```bash
stow systemd
systemctl --user daemon-reload
systemctl --user enable --now <unit>.service
```

Some units reference scripts or hardware specific to one host. Inspect them before enabling.

Existing services remain enabled when upgrading from the old tracked `*.target.wants/` links. Disable unwanted units explicitly with `systemctl --user disable --now <unit>.service`.

### Cloudflared

`cloudflared/install.sh` creates tunnels, routes DNS, installs a privileged service, and writes local state. It is not part of normal Stow deployment. Read the script and configuration before running it.

### User Scripts

`bin/` includes personal workflow and desktop scripts. Some assume specific tools, project layouts, hardware, or services. User commands belong under `bin/.local/bin/`; paths under `bin/usr/` require separate review and are not installed system-wide by Stow.

## Checks

There is no repo-wide build or CI command. Validate only the component changed.

```bash
# Herdr attach proxy
python3 herdr/.config/herdr/scripts/test_herdr_attach_proxy.py

# Pi TypeScript extensions
cd pi/.pi
npm run check
```

Career Ops commands have their own scripts under `opencode/.config/opencode/career-ops/package.json`.

## Privacy

Runtime state, credentials, sessions, logs, caches, dependencies, backups, and private environment files are ignored. Before publishing changes, inspect the diff and scan the full Git history for secrets. Public configuration may still reveal usernames, hosts, domains, ports, or project names even when it contains no credential.
