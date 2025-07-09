#!/bin/bash

# Ghost's Complete Development Environment Setup Script
# This script will completely clone your machine setup with a single command
# Usage: curl -fsSL https://raw.githubusercontent.com/yourusername/dotfiles/main/setup-enhanced.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_REPO="https://github.com/quiet-ghost/.dotfiles.git" # Update this with your actual repo
DOTFILES_DIR="$HOME/.dotfiles"

# Your project repositories (add your actual repos here)
declare -A PROJECTS=(
	# Work projects
	["work/project1"]="https://github.com/company/project1.git"
	["work/project2"]="https://github.com/company/project2.git"

	# Personal projects
	["personal/Projects/my-app"]="https://github.com/yourusername/my-app.git"
	["personal/Projects/dotfiles"]="https://github.com/yourusername/dotfiles.git"

	# Open source contributions
	["open-source/neovim"]="https://github.com/neovim/neovim.git"
	["open-source/tmux"]="https://github.com/tmux/tmux.git"

	# Tools
	["tools/scripts"]="https://github.com/yourusername/scripts.git"
)

# Logging functions
log_info() {
	echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
	echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
	echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
	echo -e "${PURPLE}[STEP]${NC} $1"
}

# Check if command exists
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Detect OS
detect_os() {
	if [[ "$OSTYPE" == "linux-gnu"* ]]; then
		if command_exists pacman; then
			echo "arch"
		elif command_exists apt; then
			echo "ubuntu"
		elif command_exists dnf; then
			echo "fedora"
		else
			echo "unknown"
		fi
	elif [[ "$OSTYPE" == "darwin"* ]]; then
		echo "macos"
	else
		echo "unknown"
	fi
}

# Install core packages
install_core_packages() {
	local os=$(detect_os)
	log_step "Installing core packages for $os..."

	case $os in
	"arch")
		log_info "Updating system and installing core packages..."
		sudo pacman -Syu --noconfirm

		# Core development tools
		sudo pacman -S --noconfirm --needed \
			git curl wget zsh tmux neovim stow fzf ripgrep fd xsel xclip bat eza yazi \
			lazygit fastfetch nodejs npm python python-pip base-devel go rust \
			btop htop tree unzip vim nano cmake meson ninja

		# Hyprland and desktop environment
		sudo pacman -S --noconfirm --needed \
			hyprland hyprpaper hypridle hyprlock hyprshot waybar wofi \
			dunst grim slurp wl-clip-persist swww swaync \
			pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber \
			brightnessctl power-profiles-daemon networkmanager

		# Fonts and themes
		sudo pacman -S --noconfirm --needed \
			ttf-font-awesome noto-fonts noto-fonts-emoji

		# Development languages and tools
		sudo pacman -S --noconfirm --needed \
			jdk21-openjdk maven php postgresql docker

		# Media and utilities
		sudo pacman -S --noconfirm --needed \
			firefox obs-studio libreoffice-fresh gparted

		# Install AUR helper (paru) if not present
		if ! command_exists paru && ! command_exists yay; then
			log_info "Installing paru AUR helper..."
			cd /tmp
			git clone https://aur.archlinux.org/paru.git
			cd paru
			makepkg -si --noconfirm
			cd ~
		fi
		;;
	"ubuntu")
		log_info "Installing packages with apt..."
		sudo apt update
		sudo apt install -y \
			git curl wget zsh tmux neovim stow fzf ripgrep fd-find xsel xclip bat exa \
			nodejs npm python3 python3-pip build-essential software-properties-common \
			btop htop tree unzip vim nano cmake meson ninja-build \
			firefox obs-studio libreoffice gparted
		;;
	"fedora")
		log_info "Installing packages with dnf..."
		sudo dnf update -y
		sudo dnf install -y \
			git curl wget zsh tmux neovim stow fzf ripgrep fd-find xsel xclip bat exa \
			nodejs npm python3 python3-pip @development-tools \
			btop htop tree unzip vim nano cmake meson ninja-build \
			firefox obs-studio libreoffice gparted
		;;
	"macos")
		log_info "Installing packages with Homebrew..."
		if ! command_exists brew; then
			log_info "Installing Homebrew..."
			/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		fi
		brew update
		brew install \
			git curl wget zsh tmux neovim stow fzf ripgrep fd bat eza yazi lazygit \
			fastfetch node python go rust btop htop tree cmake meson ninja
		;;
	*)
		log_error "Unsupported OS. Please install packages manually."
		exit 1
		;;
	esac

	log_success "Core packages installed successfully"
}

# Install AUR packages (Arch only)
install_aur_packages() {
	local os=$(detect_os)
	if [[ "$os" != "arch" ]]; then
		return 0
	fi

	log_step "Installing AUR packages..."

	local aur_helper=""
	if command_exists paru; then
		aur_helper="paru"
	elif command_exists yay; then
		aur_helper="yay"
	else
		log_warning "No AUR helper found, skipping AUR packages"
		return 0
	fi

	log_info "Installing AUR packages with $aur_helper..."

	# Essential AUR packages
	$aur_helper -S --noconfirm --needed \
		legcord-bin \
		visual-studio-code-bin \
		obsidian \
		opencode-bin \
		jetbrains-toolbox \
		lazydocker \
		typora \
		zen-browser-bin \
		youtube-music-bin \
		proton-mail-bin \
		slack-desktop \
		parsec-bin \
		timeshift-autosnap \
		wezterm-git \
		catppuccin-gtk-theme-mocha \
		ags-hyprpanel-git \
		spring-boot-cli \
		rmpc-git \
		2>/dev/null || log_warning "Some AUR packages failed to install"

	log_success "AUR packages installation completed"
}

# Clone dotfiles repository
clone_dotfiles() {
	log_step "Setting up dotfiles..."

	if [[ -d "$DOTFILES_DIR" ]]; then
		log_warning "Dotfiles directory already exists. Updating..."
		cd "$DOTFILES_DIR"
		git pull origin main
	else
		log_info "Cloning dotfiles repository..."
		git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
	fi

	cd "$DOTFILES_DIR"
	log_success "Dotfiles repository ready"
}

# Create directory structure
create_directories() {
	log_step "Creating directory structure..."

	# Main directories
	mkdir -p ~/dev/{work,tools,open-source}
	mkdir -p ~/personal/{Projects,Learning,Notes,Archive}
	mkdir -p ~/.local/bin
	mkdir -p ~/.config

	# Additional directories for your workflow
	mkdir -p ~/Downloads/Software
	mkdir -p ~/Documents/{Scripts,Templates}
	mkdir -p ~/.cache
	mkdir -p ~/.local/share

	log_success "Directory structure created"
}

# Clone your projects
clone_projects() {
	log_step "Cloning your projects..."

	for project_path in "${!PROJECTS[@]}"; do
		local full_path="$HOME/dev/$project_path"
		local repo_url="${PROJECTS[$project_path]}"

		if [[ -d "$full_path" ]]; then
			log_info "Project $project_path already exists, updating..."
			cd "$full_path"
			git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || log_warning "Failed to update $project_path"
		else
			log_info "Cloning $project_path..."
			mkdir -p "$(dirname "$full_path")"
			git clone "$repo_url" "$full_path" 2>/dev/null || log_warning "Failed to clone $project_path"
		fi
	done

	log_success "Project cloning completed"
}

# Setup Zsh and Oh My Zsh
setup_zsh() {
	log_step "Setting up Zsh and Oh My Zsh..."

	# Install Oh My Zsh if not present
	if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
		log_info "Installing Oh My Zsh..."
		sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	fi

	# Install Zsh plugins
	local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

	# zsh-autosuggestions
	if [[ ! -d "$custom_dir/plugins/zsh-autosuggestions" ]]; then
		log_info "Installing zsh-autosuggestions..."
		git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_dir/plugins/zsh-autosuggestions"
	fi

	# fast-syntax-highlighting
	if [[ ! -d "$custom_dir/plugins/fast-syntax-highlighting" ]]; then
		log_info "Installing fast-syntax-highlighting..."
		git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$custom_dir/plugins/fast-syntax-highlighting"
	fi

	# zsh-autocomplete
	if [[ ! -d "$custom_dir/plugins/zsh-autocomplete" ]]; then
		log_info "Installing zsh-autocomplete..."
		git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git "$custom_dir/plugins/zsh-autocomplete"
	fi

	# Change default shell to zsh
	if [[ "$SHELL" != "$(which zsh)" ]]; then
		log_info "Changing default shell to zsh..."
		chsh -s "$(which zsh)"
	fi

	log_success "Zsh setup completed"
}

# Setup Tmux plugins
setup_tmux() {
	log_step "Setting up Tmux plugins..."

	# Install TPM (Tmux Plugin Manager)
	if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
		log_info "Installing Tmux Plugin Manager..."
		git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	fi

	log_success "Tmux setup completed"
}

# Setup development tools
setup_dev_tools() {
	log_step "Setting up development tools..."

	# Install Node Version Manager (nvm)
	if [[ ! -d "$HOME/.nvm" ]]; then
		log_info "Installing NVM..."
		curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
		export NVM_DIR="$HOME/.nvm"
		[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
		nvm install --lts
		nvm use --lts
	fi

	# Install SDKMAN for Java
	if [[ ! -d "$HOME/.sdkman" ]]; then
		log_info "Installing SDKMAN..."
		curl -s "https://get.sdkman.io" | bash
		source "$HOME/.sdkman/bin/sdkman-init.sh"
		sdk install java
		sdk install maven
		sdk install gradle
	fi

	# Install Rust (if not already installed)
	if ! command_exists rustc; then
		log_info "Installing Rust..."
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
		source "$HOME/.cargo/env"
	fi

	# Install Go tools
	if command_exists go; then
		log_info "Installing Go tools..."
		go install github.com/jesseduffield/lazydocker@latest
		go install github.com/charmbracelet/glow@latest
	fi

	# Install Python tools
	if command_exists pip; then
		log_info "Installing Python tools..."
		pip install --user pipx
		pipx install poetry
		pipx install black
		pipx install flake8
	fi

	log_success "Development tools setup completed"
}

# Stow dotfiles
stow_dotfiles() {
	log_step "Stowing dotfiles..."

	cd "$DOTFILES_DIR"

	# Backup existing configs
	local backup_dir="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
	mkdir -p "$backup_dir"

	# List of configs to stow
	local configs=("zsh" "tmux" "nvim" "hypr" "waybar" "ghostty" "fastfetch" "wofi" "wezterm")

	for config in "${configs[@]}"; do
		if [[ -d "$config" ]]; then
			log_info "Stowing $config..."

			# Backup existing config if it exists
			if [[ -e "$HOME/.config/$config" ]] || [[ -e "$HOME/.$config" ]]; then
				log_warning "Backing up existing $config configuration..."
				cp -r "$HOME/.config/$config" "$backup_dir/" 2>/dev/null || true
				cp -r "$HOME/.$config" "$backup_dir/" 2>/dev/null || true
			fi

			stow -t "$HOME" "$config" 2>/dev/null || {
				log_warning "Failed to stow $config, trying with --adopt..."
				stow --adopt -t "$HOME" "$config"
			}
		fi
	done

	log_success "Dotfiles stowed successfully"
	log_info "Backup created at: $backup_dir"
}

# Setup private environment file
setup_private_env() {
	log_step "Setting up private environment file..."

	if [[ ! -f "$HOME/.env.private" ]]; then
		cat >"$HOME/.env.private" <<'EOF'
# Private environment variables - DO NOT COMMIT TO GIT
# Add your API keys and secrets here

# AI API Keys
# export OPENAI_API_KEY="your-key-here"
# export ANTHROPIC_API_KEY="your-key-here"
# export XAI_API_KEY="your-key-here"

# Database URLs
# export DATABASE_URL="postgresql://user:pass@localhost/db"

# Other secrets
# export GITHUB_TOKEN="your-token-here"
EOF
		log_success "Created ~/.env.private template"
		log_warning "Please add your API keys to ~/.env.private"
	else
		log_info "Private environment file already exists"
	fi
}

# Setup custom scripts
setup_custom_scripts() {
	log_step "Setting up custom scripts..."

	# Make sure .local/bin is in PATH and exists
	mkdir -p ~/.local/bin

	# Create tmux sessionizer scripts if they don't exist
	if [[ ! -f ~/.local/bin/tmux-sessionizer ]]; then
		log_info "Creating tmux-sessionizer script..."
		cat >~/.local/bin/tmux-sessionizer <<'EOF'
#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find ~/dev ~/personal ~/.dotfiles -mindepth 1 -maxdepth 1 -type d | fzf)
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s $selected_name -c $selected
    exit 0
fi

if ! tmux has-session -t=$selected_name 2> /dev/null; then
    tmux new-session -ds $selected_name -c $selected
fi

tmux switch-client -t $selected_name
EOF
		chmod +x ~/.local/bin/tmux-sessionizer
	fi

	# Create other utility scripts
	if [[ ! -f ~/.local/bin/tmux-kill-session ]]; then
		log_info "Creating tmux-kill-session script..."
		cat >~/.local/bin/tmux-kill-session <<'EOF'
#!/usr/bin/env bash
session=$(tmux list-sessions -F "#{session_name}" | fzf)
if [[ -n $session ]]; then
    tmux kill-session -t $session
fi
EOF
		chmod +x ~/.local/bin/tmux-kill-session
	fi

	if [[ ! -f ~/.local/bin/tmux-switch-session ]]; then
		log_info "Creating tmux-switch-session script..."
		cat >~/.local/bin/tmux-switch-session <<'EOF'
#!/usr/bin/env bash
session=$(tmux list-sessions -F "#{session_name}" | fzf)
if [[ -n $session ]]; then
    tmux switch-client -t $session
fi
EOF
		chmod +x ~/.local/bin/tmux-switch-session
	fi

	log_success "Custom scripts setup completed"
}

# Setup desktop environment (Linux only)
setup_desktop_environment() {
	local os=$(detect_os)
	if [[ "$os" != "arch" ]]; then
		log_info "Skipping desktop environment setup (not Arch Linux)"
		return 0
	fi

	log_step "Setting up desktop environment..."

	# Enable services
	log_info "Enabling system services..."
	sudo systemctl enable NetworkManager
	sudo systemctl enable bluetooth
	sudo systemctl enable power-profiles-daemon

	# Setup Hyprland session
	if [[ ! -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
		log_info "Setting up Hyprland session..."
		sudo mkdir -p /usr/share/wayland-sessions
		sudo tee /usr/share/wayland-sessions/hyprland.desktop >/dev/null <<'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
	fi

	log_success "Desktop environment setup completed"
}

# Main setup function
main() {
	echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
	echo -e "${PURPLE}║                Ghost's Complete Machine Setup                ║${NC}"
	echo -e "${PURPLE}║              One script to rule them all! 🚀                ║${NC}"
	echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
	echo

	log_info "This script will completely clone your development environment"
	log_info "Including: packages, dotfiles, projects, tools, and configurations"
	echo

	# Ask for confirmation
	read -p "Do you want to continue with the complete setup? (y/N): " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		log_info "Setup cancelled"
		exit 0
	fi

	# Ask about project cloning
	echo
	read -p "Do you want to clone your projects automatically? (y/N): " -n 1 -r
	echo
	local clone_projects_flag=$([[ $REPLY =~ ^[Yy]$ ]] && echo "true" || echo "false")

	# Run setup steps
	log_info "Starting complete environment setup..."
	echo

	install_core_packages
	install_aur_packages
	clone_dotfiles
	create_directories

	if [[ "$clone_projects_flag" == "true" ]]; then
		clone_projects
	fi

	setup_zsh
	setup_tmux
	setup_dev_tools
	setup_custom_scripts
	stow_dotfiles
	setup_private_env
	setup_desktop_environment

	echo
	echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
	echo -e "${GREEN}║                    Setup Completed! 🎉                      ║${NC}"
	echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
	echo
	log_info "Your machine has been completely cloned! Next steps:"
	echo
	echo "1. 🔐 Add your API keys to ~/.env.private"
	echo "2. 🔄 Restart your terminal or run: source ~/.zshrc"
	echo "3. 📦 Open tmux and install plugins: <prefix> + I"
	echo "4. ⚡ Open nvim to complete LazyVim setup"
	echo "5. 🎨 Customize any configurations as needed"
	echo "6. 🖥️  If using Hyprland, log out and select Hyprland session"
	echo
	log_success "Welcome to your perfectly cloned development environment! 🚀"
}

# Run main function
main "$@"
