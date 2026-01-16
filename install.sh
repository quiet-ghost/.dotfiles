#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${BLUE}INFO${NC} $1"; }
log_success() { echo -e "${GREEN}OK${NC} $1"; }
log_warning() { echo -e "${YELLOW}WARN${NC} $1"; }
log_error() { echo -e "${RED}ERROR${NC} $1"; }

print_header() {
  local message="$1"
  if command -v gum >/dev/null 2>&1; then
    gum style --border rounded --padding "0 1" --margin "1 0" --border-foreground 212 "$message"
  else
    echo -e "${PURPLE}$message${NC}"
  fi
}

ensure_yay() {
  if command -v yay >/dev/null 2>&1; then
    return 0
  fi

  log_warning "yay not found. Installing yay from AUR."
  sudo pacman -S --needed --noconfirm base-devel git

  local yay_dir
  yay_dir="/tmp/yay"
  if [[ -d "$yay_dir" ]]; then
    rm -rf "$yay_dir"
  fi

  git clone https://aur.archlinux.org/yay.git "$yay_dir"
  pushd "$yay_dir" >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
}

install_pacman_packages() {
  local packages=(
    base-devel
    bat
    btop
    brightnessctl
    docker
    docker-buildx
    docker-compose
    duf
    dust
    eza
    fd
    fzf
    ghostty
    git
    git-lfs
    github-cli
    glow
    gum
    hypridle
    hyprland
    hyprlock
    jq
    jless
    lazygit
    lazydocker
    neovim
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
    pipewire
    pipewire-alsa
    pipewire-jack
    pipewire-pulse
    polkit-gnome
    qt5-wayland
    ripgrep
    starship
    stow
    swayosd
    tmux
    waybar
    walker
    wget
    wireplumber
    woff2-font-awesome
    xdg-desktop-portal-hyprland
    yaru-icon-theme
    yazi
    yq
    zsh
  )

  print_header "Installing pacman packages"
  sudo pacman -S --needed --noconfirm "${packages[@]}"
  log_success "pacman packages installed"
}

install_aur_packages() {
  local packages=(
    chatterino2-bin
    cursor-bin
    javafx-scenebuilder
    jetbrains-toolbox
    lan-mouse-git
    legcord-git
    openrgb-bin
    slack-desktop
    sst-bin
    ytmdesktop-bin
    zen-browser-bin
  )

  print_header "Installing AUR packages"
  yay -S --needed --noconfirm "${packages[@]}"
  log_success "AUR packages installed"
}

install_mise_runtimes() {
  if ! command -v mise >/dev/null 2>&1; then
    log_error "mise is not available on PATH"
    return 1
  fi

  local tools=(
    "bun@1.3.5"
    "deno@2.6.4"
    "flutter@3.38.3-stable"
    "go@1.25.5"
    "java@liberica-javafx-25.0.1+13"
    "maven@3.9.12"
    "node@24.11.1"
    "python@3.13.7"
    "ruby@4.0.0"
    "rust@1.91.1"
    "zig@0.15.2"
    "zls@0.15.1"
  )

  print_header "Installing mise runtimes"
  for tool in "${tools[@]}"; do
    mise use --global "$tool"
  done
  log_success "mise runtimes installed"
}

install_bun_globals() {
  if ! command -v bun >/dev/null 2>&1; then
    log_warning "bun is not available; skipping bun global installs"
    return 0
  fi

  print_header "Installing bun globals"
  bun install -g opencode-ai mux-sesh
  log_success "bun globals installed"
}

main() {
  print_header "Dotfiles tool installation"

  install_pacman_packages
  ensure_yay
  install_aur_packages
  install_mise_runtimes
  install_bun_globals

  log_success "Tool installation complete"
}

main "$@"
