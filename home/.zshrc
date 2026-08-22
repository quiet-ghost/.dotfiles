# ============================================================================
# ENVIRONMENT VARIABLES & PATH CONFIGURATION
# ============================================================================
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/dev/tools/dev-tools/bin"
  "$HOME/dev/tools/project-bootstrap/bin"
  "$HOME/usr/bin"
  "$HOME/go/bin"
  "$HOME/dev/school/Boot/Course 2 Linux/worldbanc/private/bin"
  "$HOME/.lmstudio/bin"
  $path
)

opencode2() {
  command "$HOME/.local/bin/opencode2-isolated" "$@"
}

# Oh My Zsh installation path
export ZSH="$HOME/.oh-my-zsh"

# Browser for gh/xdg-open (Helium)
export BROWSER=helium-browser

# Go configuration
export GOPATH="$HOME/go"

# Java - let mise manage JAVA_HOME dynamically
if command -v mise >/dev/null 2>&1; then
  export JAVA_HOME="$(mise where java 2>/dev/null)"
fi

# Load private environment variables
[[ -f ~/.env.private ]] && source ~/.env.private

# ============================================================================
# OH MY ZSH CONFIGURATION
# ============================================================================

ZSH_THEME=""
zstyle ':omz:update' mode auto

# Plugins
plugins=(git zsh-autosuggestions fast-syntax-highlighting)
# zsh-autocomplete currently broken?


# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ============================================================================
# PLUGIN MANAGER SETUP
# ============================================================================

# mise (formerly rtx) - runtime version manager
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# direnv - per-directory environment loading
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# ============================================================================
# TOOL CONFIGURATIONS
# ============================================================================

# FZF - Fuzzy finder
if command -v fzf >/dev/null 2>&1; then
    # Modern fzf initialization
    source <(fzf --zsh)

    # FZF default options with custom theme
    export FZF_DEFAULT_OPTS="--height=20% --layout=reverse --border=rounded --padding=1 --color='bg+:#26233a,bg:#191724,spinner:#9ccfd8,hl:#c4a7e7,fg:#e0def4,header:#9ccfd8,info:#ebbcba,pointer:#9ccfd8,marker:#eb6f92,fg+:#e0def4,prompt:#c4a7e7,hl+:#c4a7e7,border:#6e6a86' --preview 'bat --color=always --style=numbers --line-range=:500 {}' --bind 'focus:transform-header:file --brief {}'"

    # Legacy fzf configuration (fallback)
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi

# Starship prompt
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
command -v atuin >/dev/null 2>&1 && eval "$(atuin init zsh --disable-up-arrow)"

# ============================================================================
# KEY BINDINGS
# ============================================================================

bindkey -s '^[f' 'vf\n'
bindkey -s '^[s' 'tmux-sessionizer\n'

# ============================================================================
# FUNCTIONS
# ============================================================================

# Web search function for ? alias
function web_search() {
  # Check if w3m is installed
  if ! command -v w3m >/dev/null 2>&1; then
    echo "\033[0;31mError: w3m is not installed. Please install it first.\033[0m"
    echo "\033[0;33mInstall with: sudo pacman -S w3m\033[0m"
    return 1
  fi

  # Check if query provided
  if [[ $# -eq 0 ]]; then
    echo "\033[0;33mUsage: search <search query>\033[0m"
    echo "\033[0;33mExample: search arch linux installation\033[0m"
    return 1
  fi

  # Join all arguments into query string
  local query="$*"

  # URL encode the query (basic encoding for common characters)
  local encoded_query="${query// /%20}"
  encoded_query="${encoded_query//&/%26}"
  encoded_query="${encoded_query//?/%3F}"
  encoded_query="${encoded_query//=/%3D}"
  encoded_query="${encoded_query//#/%23}"
  encoded_query="${encoded_query//+/%2B}"

  # Construct Brave Search URL
  local search_url="https://search.brave.com/search?q=${encoded_query}"

  # Launch w3m with theme-matched colors
  echo "\033[0;36m Searching Brave for: \033[0;35m${query}\033[0m"
  w3m -o color_display=1 -o color_active_link="#c4a7e7" -o color_link="#9ccfd8" -o color_visited_link="#eb6f92" -o color_bg="#191724" -o color_text="#e0def4" "${search_url}"
}

# ? command for web search with noglob wrapper
function query_command() {
  noglob ~/.local/bin/? "$@"
}

# Create ? alias that calls the function
alias \?='query_command'

# Auto-activate Python virtual environments
function auto_venv() {
  local old_venv="$VIRTUAL_ENV"

  # Check if we should deactivate
  if [[ -n "$VIRTUAL_ENV" ]]; then
    # Find if current directory or any parent has the active venv
    local venv_dir="${VIRTUAL_ENV%/bin/python*}"
    venv_dir="${venv_dir%/.venv}"

    # If we're not in the venv's project directory tree, deactivate
    if [[ "$PWD" != "$venv_dir"* ]]; then
      deactivate
      echo "\033[0;33mDeactivated venv\033[0m"
    else
      # We're still in the right directory, no need to reactivate
      return
    fi
  fi

  # Look for a venv to activate in current or parent directories
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.venv/bin/activate" ]]; then
      source "$dir/.venv/bin/activate"
      [[ "$old_venv" != "$VIRTUAL_ENV" ]] && echo "\033[0;32mActivated venv: $(basename $dir)\033[0m"
      return
    fi
    dir="${dir:h}"
  done
}

# Activate auto-hooks on directory change
autoload -U add-zsh-hook
add-zsh-hook chpwd auto_venv

# Run hooks once on shell startup for current directory
auto_venv

# ============================================================================
# COMPLETIONS
# ============================================================================

# Bun completions
[ -s "/home/ghost/.bun/_bun" ] && source "/home/ghost/.bun/_bun"

# ============================================================================
# ALIASES & OVERRIDES
# ============================================================================

# Unalias ls variants set by Oh My Zsh or plugins
unalias ls 2>/dev/null

# Load custom aliases (loaded last to override everything)
source "$HOME/.aliases.zsh"

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

typeset -U path PATH
