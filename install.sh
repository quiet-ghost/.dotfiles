#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
ASSUME_YES=false
DRY_RUN=false
SKIP_SECTIONS=()
SELECTED_SECTIONS=()
SKIPPED_PACKAGES=()
INSTALLABLE_PACKAGES=()

ALL_SECTIONS=(
  repo-packages
  aur-packages
  dotfiles
  shell
  keyboard
  mise
  global-tools
  tmux
  services
)

# Extras found on this Omarchy machine after subtracting Omarchy's base package list.
PACMAN_PACKAGES=(
  atuin
  ccache
  cmake
  cursor-bin
  dbeaver
  discord
  duf
  elephant
  elephant-bluetooth
  elephant-calc
  elephant-clipboard
  elephant-desktopapplications
  elephant-files
  elephant-menus
  elephant-providerlist
  elephant-runner
  elephant-symbols
  elephant-todo
  elephant-unicode
  elephant-websearch
  fprintd
  freerdp
  ghostty
  git-lfs
  hyprshot
  jless
  just
  love
  maven
  nasm
  neovim
  ninja
  noto-fonts-extra
  nvm
  openbsd-netcat
  postgresql
  qt6-tools
  stow
  syncthing
  tailscale
  telegram-desktop
  thunar
  tree
  ttf-cascadia-mono-nerd
  usbutils
  w3m
  walker
  wl-clip-persist
  yazi
  yq
  zed
  zsh
)

AUR_PACKAGES=(
  bibata-cursor-theme-bin
  chatterino2-bin
  geforcenow-electron
  helium-browser-bin
  javafx-scenebuilder
  jetbrains-toolbox
  legcord-git
  linear-bin
  minio
  nats-server
  natscli
  pandoc-bin
  proton-authenticator-bin
  rose-pine-cursor
  slack-desktop
  spring-boot-cli
  sst-bin
  teams-for-linux-bin
  zen-browser-bin
)

STOW_PACKAGES=(
  applications
  atuin
  bin
  gh-dash
  ghostty
  git
  hypr
  mise
  mux-sesh
  nvim
  omarchy
  opencode
  ssh
  starship
  swayosd
  systemd
  tmux
  walker
  waybar
  zsh
)

STOW_IGNORE_REGEX=(
  '(^|/)\.git(/|$)'
  '(^|/)node_modules(/|$)'
  '(^|/)tmp(/|$)'
  '(^|/)\.jdtls-out(/|$)'
  '^\.config/tmux/plugins(/|$)'
  '(^|/).*sync-conflict.*$'
  '(^|/).*\.bak(\..*)?$'
  '(^|/).*\.backup$'
  '(^|/)debug\.log$'
)

BUN_GLOBAL_PACKAGES=(
  @quietghost/x-cli
  bash-language-server
  mux-sesh
  sst
  yaml-language-server
)

NPM_GLOBAL_PACKAGES=(
  opencode-ai@1.15.8
)

SYSTEM_SERVICES=(
  bluetooth.service
  cups.service
  cups-browsed.service
  docker.service
  iwd.service
  power-profiles-daemon.service
  tailscaled.service
)

USER_SERVICES=(
  elephant.service
  swayosd-server.service
  syncthing.service
)

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  -y, --yes, --all       Run every default section without prompts
  --dry-run              Print major commands without running them
  --skip-repo            Skip pacman packages
  --skip-aur             Skip AUR packages
  --skip-dotfiles        Skip stow
  --skip-shell           Skip zsh/Oh My Zsh setup
  --skip-keyboard        Skip programmer XKB install
  --skip-mise            Skip mise runtime install
  --skip-global-tools    Skip npm/bun globals and opencode npm install
  --skip-tmux            Skip TPM setup
  --skip-services        Skip service enablement
  -h, --help             Show this help
EOF
}

parse_args() {
  while (($#)); do
    case "$1" in
      -y | --yes | --all)
        ASSUME_YES=true
        ;;
      --dry-run)
        DRY_RUN=true
        ;;
      --skip-repo)
        SKIP_SECTIONS+=(repo-packages)
        ;;
      --skip-aur)
        SKIP_SECTIONS+=(aur-packages)
        ;;
      --skip-dotfiles)
        SKIP_SECTIONS+=(dotfiles)
        ;;
      --skip-shell)
        SKIP_SECTIONS+=(shell)
        ;;
      --skip-keyboard)
        SKIP_SECTIONS+=(keyboard)
        ;;
      --skip-mise)
        SKIP_SECTIONS+=(mise)
        ;;
      --skip-global-tools)
        SKIP_SECTIONS+=(global-tools)
        ;;
      --skip-tmux)
        SKIP_SECTIONS+=(tmux)
        ;;
      --skip-services)
        SKIP_SECTIONS+=(services)
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 2
        ;;
    esac
    shift
  done
}

have() {
  command -v "$1" >/dev/null 2>&1
}

gum_ready() {
  have gum && [[ -t 1 ]]
}

say() {
  if gum_ready; then
    gum style --foreground 212 --bold "$*"
  else
    printf '%s\n' "$*"
  fi
}

ok() {
  if gum_ready; then
    gum style --foreground 42 "OK  $*"
  else
    printf 'OK  %s\n' "$*"
  fi
}

warn() {
  if gum_ready; then
    gum style --foreground 214 "WARN  $*"
  else
    printf 'WARN  %s\n' "$*"
  fi
}

die() {
  if gum_ready; then
    gum style --foreground 196 --bold "ERROR  $*"
  else
    printf 'ERROR  %s\n' "$*" >&2
  fi
  exit 1
}

run_cmd() {
  local title=$1
  shift

  if $DRY_RUN; then
    printf 'DRY-RUN  %s:' "$title"
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  if gum_ready; then
    gum spin --spinner dot --title "$title" -- "$@"
  else
    printf '%s\n' "$title"
    "$@"
  fi
}

section_skipped() {
  local section=$1
  local skipped
  for skipped in "${SKIP_SECTIONS[@]}"; do
    [[ "$skipped" == "$section" ]] && return 0
  done
  return 1
}

select_sections() {
  local section
  if $ASSUME_YES || [[ ! -t 0 ]]; then
    SELECTED_SECTIONS=("${ALL_SECTIONS[@]}")
  elif gum_ready; then
    mapfile -t SELECTED_SECTIONS < <(
      gum choose --no-limit --selected='*' --height=12 --header='Install sections' "${ALL_SECTIONS[@]}"
    )
  else
    SELECTED_SECTIONS=("${ALL_SECTIONS[@]}")
  fi

  local filtered=()
  for section in "${SELECTED_SECTIONS[@]}"; do
    section_skipped "$section" || filtered+=("$section")
  done
  SELECTED_SECTIONS=("${filtered[@]}")
}

section_enabled() {
  local section=$1
  local selected
  for selected in "${SELECTED_SECTIONS[@]}"; do
    [[ "$selected" == "$section" ]] && return 0
  done
  return 1
}

require_omarchy_arch() {
  [[ -f /etc/arch-release ]] || die "Arch Linux required"

  if ! have omarchy; then
    warn "omarchy command missing. Continue only on fresh Omarchy after first login."
  fi

  if [[ "$DOTFILES_DIR" != "$HOME/.dotfiles" ]]; then
    warn "Repo is $DOTFILES_DIR, but zsh config expects $HOME/.dotfiles. Clone there or symlink it."
  fi
}

bootstrap_tools() {
  local missing=()
  local tool
  for tool in git gum stow; do
    have "$tool" || missing+=("$tool")
  done

  ((${#missing[@]} == 0)) && return 0
  run_cmd "Install bootstrap tools" sudo pacman -Syu --needed --noconfirm "${missing[@]}"
}

sudo_keepalive() {
  run_cmd "Refresh sudo" sudo -v

  if $DRY_RUN; then
    return 0
  fi

  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &
}

filter_missing_pacman() {
  local pkg
  for pkg in "$@"; do
    pacman -Q "$pkg" >/dev/null 2>&1 || printf '%s\n' "$pkg"
  done
}

filter_installable_pacman() {
  local pkg
  INSTALLABLE_PACKAGES=()
  for pkg in "$@"; do
    if pacman -Si "$pkg" >/dev/null 2>&1; then
      INSTALLABLE_PACKAGES+=("$pkg")
    else
      SKIPPED_PACKAGES+=("repo:$pkg")
      warn "Package not found in pacman repos: $pkg"
    fi
  done
}

filter_installable_aur() {
  local pkg
  INSTALLABLE_PACKAGES=()
  for pkg in "$@"; do
    if yay -Si "$pkg" >/dev/null 2>&1; then
      INSTALLABLE_PACKAGES+=("$pkg")
    else
      SKIPPED_PACKAGES+=("aur:$pkg")
      warn "Package not found in AUR: $pkg"
    fi
  done
}

install_repo_packages() {
  local -a missing installable

  mapfile -t missing < <(filter_missing_pacman "${PACMAN_PACKAGES[@]}")
  ((${#missing[@]} == 0)) && ok "repo packages already present" && return 0

  run_cmd "Update system packages" sudo pacman -Syu --noconfirm
  filter_installable_pacman "${missing[@]}"
  installable=("${INSTALLABLE_PACKAGES[@]}")
  ((${#installable[@]} == 0)) && return 0

  run_cmd "Install repo packages" sudo pacman -S --needed --noconfirm "${installable[@]}"
}

install_aur_packages() {
  local -a missing installable

  have yay || run_cmd "Install yay" sudo pacman -Syu --needed --noconfirm yay

  mapfile -t missing < <(filter_missing_pacman "${AUR_PACKAGES[@]}")
  ((${#missing[@]} == 0)) && ok "AUR packages already present" && return 0

  filter_installable_aur "${missing[@]}"
  installable=("${INSTALLABLE_PACKAGES[@]}")
  ((${#installable[@]} == 0)) && return 0

  run_cmd "Install AUR packages" yay -S --needed --noconfirm "${installable[@]}"
}

should_ignore_rel() {
  local rel=$1
  case "$rel" in
    .git | .git/* | */.git | */.git/*) return 0 ;;
    node_modules | node_modules/* | */node_modules | */node_modules/*) return 0 ;;
    tmp | tmp/* | */tmp | */tmp/*) return 0 ;;
    .jdtls-out | .jdtls-out/* | */.jdtls-out | */.jdtls-out/*) return 0 ;;
    .config/tmux/plugins | .config/tmux/plugins/*) return 0 ;;
    *sync-conflict* | *.bak | *.bak.* | *.backup | debug.log) return 0 ;;
  esac
  return 1
}

unique_backup_path() {
  local path=$1
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    printf '%s\n' "$path"
    return 0
  fi
  printf '%s.%s\n' "$path" "$(date +%s)"
}

backup_conflicts_for_package() {
  local package=$1
  local package_dir="$DOTFILES_DIR/$package"
  local source rel target backup source_real target_real

  while IFS= read -r -d '' source; do
    rel="${source#"$package_dir/"}"
    should_ignore_rel "$rel" && continue

    target="$HOME/$rel"
    [[ -e "$target" || -L "$target" ]] || continue

    if [[ -L "$target" ]]; then
      source_real="$(readlink -f "$source" 2>/dev/null || true)"
      target_real="$(readlink -f "$target" 2>/dev/null || true)"
      [[ -n "$source_real" && "$source_real" == "$target_real" ]] && continue
    fi

    backup="$(unique_backup_path "$BACKUP_DIR/$rel")"
    if $DRY_RUN; then
      printf 'DRY-RUN  backup %q -> %q\n' "$target" "$backup"
    else
      mkdir -p "$(dirname "$backup")"
      mv "$target" "$backup"
      warn "Backed up $target -> $backup"
    fi
  done < <(
    find "$package_dir" \
      \( -name .git -o -name node_modules -o -name tmp -o -name .jdtls-out \) -prune -o \
      \( -type f -o -type l \) -print0
  )
}

stow_package() {
  local package=$1
  local args=(--dir="$DOTFILES_DIR" --target="$HOME" --restow --no-folding)
  local pattern

  [[ -d "$DOTFILES_DIR/$package" ]] || die "Missing stow package: $package"
  backup_conflicts_for_package "$package"

  for pattern in "${STOW_IGNORE_REGEX[@]}"; do
    args+=(--ignore="$pattern")
  done

  run_cmd "Stow $package" stow "${args[@]}" "$package"
}

install_dotfiles() {
  local package
  $DRY_RUN || mkdir -p "$BACKUP_DIR"

  for package in "${STOW_PACKAGES[@]}"; do
    stow_package "$package"
  done

  run_cmd "Create workspace dirs" mkdir -p \
    "$HOME/dev/projects" \
    "$HOME/dev/work" \
    "$HOME/dev/repos" \
    "$HOME/dev/open-source" \
    "$HOME/personal/Learning" \
    "$HOME/personal/Notes" \
    "$HOME/personal/Archive"

  if ! $DRY_RUN; then
    find "$DOTFILES_DIR/bin" "$DOTFILES_DIR/waybar" "$DOTFILES_DIR/omarchy/.config/omarchy/hooks" \
      -type f \( -name '*.sh' -o -path '*/.local/bin/*' -o -path '*/usr/bin/*' \) -exec chmod +x {} + 2>/dev/null || true
    find "$DOTFILES_DIR/systemd/.config/systemd/user" -type f -name '*.service' -exec chmod 0644 {} + 2>/dev/null || true
  fi
}

clone_or_update() {
  local repo=$1
  local dir=$2

  if [[ -d "$dir/.git" ]]; then
    run_cmd "Update $(basename "$dir")" git -C "$dir" pull --ff-only
  else
    run_cmd "Create $(dirname "$dir")" mkdir -p "$(dirname "$dir")"
    run_cmd "Clone $(basename "$dir")" git clone --depth=1 "$repo" "$dir"
  fi
}

setup_shell() {
  local zsh_path current_shell custom_dir
  zsh_path="$(command -v zsh || true)"
  [[ -n "$zsh_path" ]] || die "zsh missing after package install"

  clone_or_update https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
  clone_or_update https://github.com/zsh-users/zsh-autosuggestions "$custom_dir/zsh-autosuggestions"
  clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_dir/zsh-syntax-highlighting"
  clone_or_update https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$custom_dir/fast-syntax-highlighting"
  clone_or_update https://github.com/marlonrichert/zsh-autocomplete.git "$custom_dir/zsh-autocomplete"

  current_shell="$(getent passwd "$USER" | cut -d: -f7)"
  if [[ "$current_shell" != "$zsh_path" ]]; then
    run_cmd "Set login shell" sudo chsh -s "$zsh_path" "$USER"
    warn "Log out/in required for zsh login shell"
  else
    ok "zsh already login shell"
  fi
}

setup_keyboard() {
  local layout="$DOTFILES_DIR/keyboard/xkb/programmer"
  [[ -f "$layout" ]] || die "Missing keyboard layout: $layout"
  run_cmd "Install programmer XKB layout" sudo install -Dm644 "$layout" /usr/share/X11/xkb/symbols/programmer
}

setup_mise() {
  have mise || die "mise missing after package install"

  run_cmd "Create mise config dir" mkdir -p "$HOME/.config/mise"
  if [[ ! -e "$HOME/.config/mise/config.toml" ]]; then
    run_cmd "Install mise config" cp "$DOTFILES_DIR/mise/.config/mise/config.toml" "$HOME/.config/mise/config.toml"
  fi

  run_cmd "Trust mise config" mise trust -y "$HOME/.config/mise/config.toml"
  run_cmd "Install mise runtimes" mise install -y
}

setup_global_tools() {
  have mise || die "mise required for global tools"
  run_cmd "Install Bun global tools" mise exec bun@latest -- bun add -g "${BUN_GLOBAL_PACKAGES[@]}"
  run_cmd "Install npm global tools" mise exec node@latest -- npm install -g "${NPM_GLOBAL_PACKAGES[@]}"

  if [[ -f "$HOME/.config/opencode/package.json" ]]; then
    run_cmd "Install opencode config deps" mise exec node@latest -- npm install --prefix "$HOME/.config/opencode"
  fi

  if [[ -f "$HOME/.config/opencode/career-ops/package.json" ]]; then
    run_cmd "Install career-ops deps" mise exec node@latest -- npm install --prefix "$HOME/.config/opencode/career-ops"
  fi
}

setup_tmux() {
  clone_or_update https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  if [[ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]]; then
    run_cmd "Install tmux plugins" "$HOME/.tmux/plugins/tpm/bin/install_plugins"
  fi
}

unit_exists() {
  systemctl list-unit-files "$1" --no-legend 2>/dev/null | grep -q .
}

user_unit_exists() {
  systemctl --user list-unit-files "$1" --no-legend 2>/dev/null | grep -q .
}

setup_services() {
  local service

  run_cmd "Reload user systemd" systemctl --user daemon-reload

  for service in "${SYSTEM_SERVICES[@]}"; do
    if unit_exists "$service"; then
      run_cmd "Enable $service" sudo systemctl enable --now "$service"
    else
      warn "System unit missing: $service"
    fi
  done

  for service in "${USER_SERVICES[@]}"; do
    if user_unit_exists "$service"; then
      run_cmd "Enable user $service" systemctl --user enable --now "$service"
    else
      warn "User unit missing: $service"
    fi
  done

  if getent group docker >/dev/null 2>&1 && ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    run_cmd "Add user to docker group" sudo usermod -aG docker "$USER"
    warn "Log out/in required for docker group"
  fi
}

validate_session_configs() {
  if have hyprctl && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    run_cmd "Reload Hyprland" hyprctl reload || true
    hyprctl configerrors || true
  fi

  if have omarchy && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    omarchy restart waybar >/dev/null 2>&1 || true
    omarchy restart swayosd >/dev/null 2>&1 || true
  fi
}

print_summary() {
  ok "Install script complete"

  if ((${#SKIPPED_PACKAGES[@]} > 0)); then
    warn "Skipped unavailable packages: ${SKIPPED_PACKAGES[*]}"
  fi

  if [[ -d "$BACKUP_DIR" ]] && [[ -n "$(find "$BACKUP_DIR" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
    warn "Backups written: $BACKUP_DIR"
  fi

  warn "Manual logins still needed: gh auth login, 1Password, Tailscale, Syncthing pairing."
}

main() {
  parse_args "$@"
  require_omarchy_arch
  bootstrap_tools
  sudo_keepalive
  select_sections

  say "Ghost Omarchy bootstrap"
  printf 'Sections: %s\n' "${SELECTED_SECTIONS[*]}"

  section_enabled repo-packages && install_repo_packages
  section_enabled aur-packages && install_aur_packages
  section_enabled dotfiles && install_dotfiles
  section_enabled shell && setup_shell
  section_enabled keyboard && setup_keyboard
  section_enabled mise && setup_mise
  section_enabled global-tools && setup_global_tools
  section_enabled tmux && setup_tmux
  section_enabled services && setup_services
  validate_session_configs
  print_summary
}

main "$@"
