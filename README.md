# Ghost's Dotfiles

Personal configuration files for Arch Linux with Hyprland, managed using [GNU Stow](https://www.gnu.org/software/stow/).

## System

- **OS**: [Arch Linux](https://archlinux.org/) ([omarchy](https://omarchy.org/) install)
- **Window Manager**: [Hyprland](https://hyprland.org/) (Wayland)
- **Terminal**: [Ghostty](https://ghostty.org/)
- **Shell**: Zsh
- **Editor**: [Neovim](https://neovim.io/) ([LazyVim](https://www.lazyvim.org/))
- **Multiplexer**: [Herdr](https://herdr.dev) (primary) / [Tmux](https://github.com/tmux/tmux)

## Components

### Core Configuration

- **hypr/** - Hyprland window manager configuration with custom keybindings, startup scripts, and theming
- **nvim/** - Neovim configuration based on LazyVim with custom plugins and Java development setup
- **herdr/** - [Herdr](https://herdr.dev) terminal workspace manager config, including persistent Twitch chat pane toggle (`Alt+Shift+C`)
- **tmux/** - Tmux configuration with session management and custom scripts
- **zsh/** - Zsh shell configuration

### Desktop Environment

- **waybar/** - [Waybar](https://github.com/Alexays/Waybar) status bar configuration with custom modules and SSH monitoring
- **walker/** - [Walker](https://github.com/abenz1267/walker) application launcher configuration
- **swayosd/** - [SwayOSD](https://github.com/ErikReider/SwayOSD) on-screen display daemon for volume and brightness
- **ghostty/** - [Ghostty](https://ghostty.org/) terminal emulator configuration

### Development Tools

- **git/** - Git configuration and aliases
- **opencode/** - [OpenCode](https://github.com/sst/opencode) AI coding agent configuration and custom agents
- **bin/** - Custom utility scripts and binaries

### Services

- **systemd/** - User systemd services including custom hypridle launcher
- **cloudflared/** - [Cloudflare Tunnel](https://github.com/cloudflare/cloudflared) configuration

## Installation

This repository uses GNU Stow for symlink management. Each directory represents a stow package.

### Prerequisites

```bash
sudo pacman -S stow git
```

### Deploy Configurations

Clone the repository:

```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

Use stow to symlink configurations:

```bash
# Install all configurations
stow */

# Install specific configuration
stow nvim
stow hypr
stow tmux
```

### Remove Configurations

```bash
# Remove specific configuration
stow -D nvim
```

## Custom Scripts

Located in `bin/.local/bin/` and `bin/usr/bin/`:

- **arch-install-ai-tool** - Automated AI development tools installation (deprecated due to using omarchy, but has same functionality)
- **arch-install-dev-env** - Development environment setup script (deprecated due to using omarchy, but has same functionality)
- **tmux-sessionizer** - Fuzzy find and jump to project directories in tmux
- **mux-sesh** - [Advanced tmux session management](https://github.com/quiet-ghost/mux-sesh)
- **hypridle-launcher** - Custom idle management launcher
- **kill-process** - Interactive process killer

## Directory Structure

```
.
├── .config/          # Application configurations (stow target)
├── .local/bin/       # User binaries (stow target)
├── backups/          # Configuration backups
└── usr/bin/          # System-level scripts
```

Each top-level directory follows the stow pattern where subdirectories mirror the home directory structure.
