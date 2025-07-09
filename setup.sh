#!/bin/bash

# Ghost's Development Environment Setup Script
# Usage: curl -fsSL https://raw.githubusercontent.com/yourusername/dotfiles/main/setup.sh | bash
# Or: wget -qO- https://raw.githubusercontent.com/yourusername/dotfiles/main/setup.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_REPO="https://github.com/yourusername/dotfiles.git"  # Update this with your actual repo
DOTFILES_DIR="$HOME/.dotfiles"

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

# Install packages based on OS
install_packages() {
    local os=$(detect_os)
    log_info "Detected OS: $os"
    
    case $os in
        "arch")
            log_info "Installing packages with pacman..."
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm git curl wget zsh tmux neovim stow fzf ripgrep fd \
                xsel xclip bat eza yazi lazygit fastfetch nodejs npm python python-pip \
                base-devel go rust
            
            # Install AUR helper (yay) if not present
            if ! command_exists yay; then
                log_info "Installing yay AUR helper..."
                cd /tmp
                git clone https://aur.archlinux.org/yay.git
                cd yay
                makepkg -si --noconfirm
                cd ~
            fi
            ;;
        "ubuntu")
            log_info "Installing packages with apt..."
            sudo apt update
            sudo apt install -y git curl wget zsh tmux neovim stow fzf ripgrep fd-find \
                xsel xclip bat exa nodejs npm python3 python3-pip build-essential \
                software-properties-common
            
            # Install newer versions from snap if available
            if command_exists snap; then
                sudo snap install go --classic
                sudo snap install --edge nvim --classic
            fi
            ;;
        "fedora")
            log_info "Installing packages with dnf..."
            sudo dnf update -y
            sudo dnf install -y git curl wget zsh tmux neovim stow fzf ripgrep fd-find \
                xsel xclip bat exa nodejs npm python3 python3-pip @development-tools
            ;;
        "macos")
            log_info "Installing packages with Homebrew..."
            if ! command_exists brew; then
                log_info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew update
            brew install git curl wget zsh tmux neovim stow fzf ripgrep fd bat eza \
                yazi lazygit fastfetch node python go rust
            ;;
        *)
            log_error "Unsupported OS. Please install packages manually."
            exit 1
            ;;
    esac
    
    log_success "Base packages installed successfully"
}

# Clone dotfiles repository
clone_dotfiles() {
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
    log_info "Creating directory structure..."
    
    # Main directories
    mkdir -p ~/dev/{work,tools,open-source}
    mkdir -p ~/personal/{Projects,Learning,Notes,Archive}
    mkdir -p ~/.local/bin
    mkdir -p ~/.config
    
    log_success "Directory structure created"
}

# Setup Zsh and Oh My Zsh
setup_zsh() {
    log_info "Setting up Zsh and Oh My Zsh..."
    
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
    log_info "Setting up Tmux plugins..."
    
    # Install TPM (Tmux Plugin Manager)
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        log_info "Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi
    
    log_success "Tmux setup completed"
}

# Setup Neovim
setup_neovim() {
    log_info "Setting up Neovim..."
    
    # Install LazyVim if config doesn't exist
    if [[ ! -d "$HOME/.config/nvim" ]]; then
        log_info "LazyVim will be installed when you first run nvim"
    fi
    
    log_success "Neovim setup completed"
}

# Setup development tools
setup_dev_tools() {
    log_info "Setting up development tools..."
    
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
    fi
    
    # Install Rust (if not already installed)
    if ! command_exists rustc; then
        log_info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    
    log_success "Development tools setup completed"
}

# Stow dotfiles
stow_dotfiles() {
    log_info "Stowing dotfiles..."
    
    cd "$DOTFILES_DIR"
    
    # Backup existing configs
    local backup_dir="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # List of configs to stow
    local configs=("zsh" "tmux" "nvim" "hypr" "waybar" "ghostty" "fastfetch")
    
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
    log_info "Setting up private environment file..."
    
    if [[ ! -f "$HOME/.env.private" ]]; then
        cat > "$HOME/.env.private" << 'EOF'
# Private environment variables - DO NOT COMMIT TO GIT
# Add your API keys and secrets here

# Example:
# export OPENAI_API_KEY="your-key-here"
# export ANTHROPIC_API_KEY="your-key-here"
# export XAI_API_KEY="your-key-here"
EOF
        log_success "Created ~/.env.private template"
        log_warning "Please add your API keys to ~/.env.private"
    else
        log_info "Private environment file already exists"
    fi
}

# Optional software installation
install_optional_software() {
    log_info "Installing optional software..."
    
    local os=$(detect_os)
    
    case $os in
        "arch")
            # AUR packages
            if command_exists yay; then
                log_info "Installing AUR packages..."
                yay -S --noconfirm --needed \
                    visual-studio-code-bin \
                    discord \
                    spotify \
                    brave-bin \
                    obsidian \
                    mailsy \
                    opencode-bin 2>/dev/null || log_warning "Some AUR packages failed to install"
            fi
            ;;
        "ubuntu")
            # Snap packages
            if command_exists snap; then
                sudo snap install code --classic
                sudo snap install discord
                sudo snap install obsidian --classic
            fi
            ;;
        "macos")
            # Homebrew casks
            brew install --cask visual-studio-code discord spotify brave-browser obsidian
            ;;
    esac
    
    log_success "Optional software installation completed"
}

# Main setup function
main() {
    log_info "Starting Ghost's Development Environment Setup..."
    log_info "This script will set up your complete development environment"
    
    # Ask for confirmation
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Setup cancelled"
        exit 0
    fi
    
    # Run setup steps
    install_packages
    clone_dotfiles
    create_directories
    setup_zsh
    setup_tmux
    setup_neovim
    setup_dev_tools
    stow_dotfiles
    setup_private_env
    
    # Ask about optional software
    echo
    read -p "Do you want to install optional software (VSCode, Discord, etc.)? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_optional_software
    fi
    
    log_success "Setup completed successfully!"
    echo
    log_info "Next steps:"
    echo "1. Add your API keys to ~/.env.private"
    echo "2. Restart your terminal or run: source ~/.zshrc"
    echo "3. Open tmux and install plugins: <prefix> + I"
    echo "4. Open nvim to complete LazyVim setup"
    echo "5. Customize any configurations as needed"
    echo
    log_info "Enjoy your new development environment! 🚀"
}

# Run main function
main "$@"