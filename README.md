# Ghost's Dotfiles 🚀

A complete development environment setup with automated installation script. Supports Arch Linux, Ubuntu, Fedora, and macOS.

## ⚡ Quick Setup

**One-line install:**

```bash
curl -fsSL https://raw.githubusercontent.com/quiet-ghost/.dotfiles/main/setup-enhanced.sh | bash
```

Or download and run:

```bash
wget https://raw.githubusercontent.com/quiet-ghost/.dotfiles/main/setup.sh
chmod +x setup.sh
./setup.sh
```

## 🛠 What's Included

### Core Tools

- **Shell**: Zsh with Oh My Zsh + plugins (autosuggestions, syntax highlighting, autocomplete)
- **Terminal Multiplexer**: Tmux with custom configuration and plugins
- **Editor**: Neovim with LazyVim configuration
- **File Manager**: Yazi with custom keybindings
- **Fuzzy Finder**: FZF with custom previews
- **Git UI**: Lazygit
- **System Info**: Fastfetch

### Development Environment

- **Languages**: Node.js (via NVM), Python, Go, Rust, Java (via SDKMAN)
- **Package Managers**: npm, pip, cargo, go modules
- **Build Tools**: Base development tools for each OS
- **Version Control**: Git with custom aliases and configuration

### Window Management (Linux)

- **Compositor**: Hyprland with custom configuration
- **Status Bar**: Waybar with custom styling
- **App Launcher**: Wofi
- **Terminal**: Ghostty
- **Notifications**: Hyprland notifications

### Custom Scripts & Aliases

- **Tmux Session Management**: `tmux-sessionizer`, `tmux-kill-session`, `tmux-switch-session`
- **File Navigation**: Custom fzf-based file and directory switchers
- **Git Workflows**: Branch switching, commit browsing with fzf
- **Project Management**: Quick navigation to dev directories

## 📁 Directory Structure

The setup script creates this directory structure:

```
~/
├── dev/
│   ├── work/          # Work projects
│   ├── tools/         # Development tools
│   └── open-source/   # Open source contributions
├── personal/
│   ├── Projects/      # Personal projects
│   ├── Learning/      # Learning materials
│   ├── Notes/         # Notes and documentation
│   └── Archive/       # Archived projects
└── .dotfiles/         # This repository
```

## 🔧 Manual Setup (Alternative)

If you prefer manual installation:

### 1. Clone Repository

```bash
git clone https://github.com/quiet-ghost/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 2. Install Dependencies

**Arch Linux:**

```bash
sudo pacman -S git curl wget zsh tmux neovim stow fzf ripgrep fd xsel xclip bat eza yazi lazygit fastfetch nodejs npm python python-pip base-devel go rust
```

**Ubuntu/Debian:**

```bash
sudo apt install git curl wget zsh tmux neovim stow fzf ripgrep fd-find xsel xclip bat exa nodejs npm python3 python3-pip build-essential
```

**macOS:**

```bash
brew install git curl wget zsh tmux neovim stow fzf ripgrep fd bat eza yazi lazygit fastfetch node python go rust
```

### 3. Setup Shell

```bash
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete
```

### 4. Stow Configurations

```bash
cd ~/.dotfiles
stow zsh tmux nvim  # Add other configs as needed
```

### 5. Setup Private Environment

```bash
cp .env.private.example ~/.env.private
# Edit ~/.env.private with your API keys
```

## 🔐 Security

- **API Keys**: Stored in `~/.env.private` (not tracked in git)
- **Sensitive Data**: All credentials are kept out of version control
- **Safe to Fork**: Repository contains no personal information

### Setting up API Keys

Create `~/.env.private` with your keys:

```bash
export OPENAI_API_KEY="your-key-here"
export ANTHROPIC_API_KEY="your-key-here"
export XAI_API_KEY="your-key-here"
```

## ⌨️ Key Bindings

### Tmux (Prefix: Ctrl+Space)

- `Prefix + |` - Split horizontally
- `Prefix + -` - Split vertically
- `Prefix + r` - Reload config
- `Alt + 1-5` - Switch to window 1-5

### Zsh

- `Alt + s` - Tmux sessionizer
- `Alt + w` - Tmux session switcher
- `Alt + f` - File finder with nvim

### Custom Aliases

- `xx` - Clear terminal
- `v` - Neovim
- `lg` - Lazygit
- `ya` - Yazi file manager
- `oc` - Opencode
- `vf` - Find files with Telescope
- `vg` - Live grep with Telescope
- `vp` - Project switcher

## 🎨 Customization

### Themes

- **Zsh**: Robbyrussell theme
- **Tmux**: Catppuccin Mocha
- **Neovim**: Material theme
- **Terminal**: Catppuccin color scheme

### Fonts

Recommended: Nerd Fonts (FiraCode, JetBrains Mono, or Hack)

## 📦 Included Packages

See `packages.txt`, `packages-user.txt`, and `packages-aur.txt` for complete package lists.

## 🔄 Updates

To update your dotfiles:

```bash
cd ~/.dotfiles
git pull origin main
# Re-stow any updated configurations
stow zsh tmux nvim
```

## 🐛 Troubleshooting

### Common Issues

**Zsh completion issues in nvim terminal:**

- Fixed with `compdef -d xx` in the configuration

**Stow conflicts:**

- Backup existing configs before stowing
- Use `stow --adopt` to resolve conflicts

**Missing plugins:**

- Run the setup script again
- Manually install missing plugins

### Getting Help

1. Check the `TODO.md` for detailed setup instructions
2. Review individual config files for specific settings
3. Open an issue if you find bugs

## 🤝 Contributing

Feel free to fork and customize for your own use! If you find improvements or fixes, pull requests are welcome.

## 📄 License

MIT License - see LICENSE file for details.

---

**Enjoy your new development environment!** 🎉
