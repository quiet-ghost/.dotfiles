# Early PATH setup
export PATH="$HOME/.local/bin:/home/ghost/.opencode/bin:$PATH:/usr/bin/nvim"

# Oh My Zsh setup
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
zstyle ':omz:update' mode auto

# Minimal plugin list - removed duplicates
plugins=(git zsh-syntax-highlighting)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Load additional plugins conditionally
_load_plugin() {
    [[ -f "$1" ]] && source "$1"
}

_load_plugin "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
_load_plugin "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
_load_plugin "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh"

# Configure zsh-autocomplete
zstyle ':autocomplete:*' min-input 2
zstyle ':autocomplete:*' delay 0.4
zstyle ':autocomplete:*' list-lines 8
zstyle ':autocomplete:tab:*' insert-unambiguous yes
zstyle ':autocomplete:tab:*' widget-style menu-select
compdef -d xx

# Source private env and fzf conditionally
[[ -f ~/.env.private ]] && source ~/.env.private

# Lazy load heavy tools
_lazy_load_nvm() {
    unset -f nvm node npm npx
    export NVM_DIR="$HOME/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
}

nvm() { _lazy_load_nvm && nvm "$@"; }
node() { _lazy_load_nvm && node "$@"; }
npm() { _lazy_load_nvm && npm "$@"; }
npx() { _lazy_load_nvm && npx "$@"; }

_lazy_load_sdkman() {
    unset -f sdk
    export SDKMAN_DIR="$HOME/.sdkman"
    [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
}

sdk() { _lazy_load_sdkman && sdk "$@"; }

# Environment variables
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin:/usr/bin
export RUSTONIG_SYSTEM_LIBONIG=1

# FZF setup - only if fzf is available
if command -v fzf >/dev/null 2>&1; then
    [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
    source <(fzf --zsh)
    export FZF_DEFAULT_OPTS="--style full --preview 'fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}'"
fi

# Aliases - grouped for clarity
alias xx='clear'
alias pbcopy='xsel --clipboard --input'
alias pbpaste='xsel --clipboard --output'
alias v='nvim'
alias lg='lazygit'
alias ya='yazi'
alias yac='yazi --cwd-file'
alias ls='eza --icons=always'
alias oc='opencode'
alias df='duf'
alias st='speedtest-cli --simple'
alias arc='sudo arch-clean.sh'
alias windows='~/boot-to-windows.sh'

# FZF-based aliases
alias vh="eval \$(history | fzf | cut -d' ' -f4-)"
alias vk="kill -9 \$(ps aux | fzf --multi | awk '{print \$2}')"
alias vb="git checkout \$(git branch --all | fzf | tr -d ' *')"
alias vc="git checkout \$(git log --oneline | fzf --preview 'git show {1}' | cut -d' ' -f1)"
alias vp="nvim \$(find ~/ ~/dev/ ~/personal/ ~/.dotfiles/ -mindepth 1 -maxdepth 3 -type d | fzf)"
alias vf='nvim -c "lua require(\"telescope.builtin\").find_files({ search_dirs = { \"~/dev/\", \"~/personal/\", \"~/.dotfiles/\" } })"'
alias vg='nvim -c "lua require(\"telescope.builtin\").live_grep({ search_dirs = { \"~/dev/\", \"~/personal/\", \"~/.dotfiles/\" } })"'

# Tmux aliases
alias tms='tmux has-session -t main 2>/dev/null && tmux attach-session -t main || { tmux new-session -s main -d \; send-keys -t default:1 "opencode" Enter  \; new-window -n term \; new-window \; attach-session -t main:1; }'
alias tmss='tmux-sessionizer'
alias tmp='tmux-sessionizer-nvim-style-bin'
alias tk='tmux-kill-session'
alias ts='tmux-switch-session'

# Directory navigation
alias p='cd ~/personal'
alias pp='cd ~/personal/Projects'
alias pl='cd ~/personal/Learning'
alias pn='cd ~/personal/Notes'
alias pa='cd ~/personal/Archive'
alias d='cd ~/dev'
alias dw='cd ~/dev/work'
alias dt='cd ~/dev/tools'
alias dos='cd ~/dev/open-source'
alias c='cd ~/.dotfiles'

# Mail and Maven
alias m='mailsy m'
alias mm='mailsy me'
alias mg='sudo mailsy g'
alias mvnag='mvn archetype:generate'

# Key bindings
bindkey -s '^[f' 'vf\n'
bindkey -s '^[s' 'tmux-sessionizer\n'
bindkey -s '^[w' 'mux-sesh\n'

# Grep file contents and jump to line
vcg() {
    local file_line
    file_line=$(rg --line-number --no-heading --smart-case . | fzf --preview 'bat --style=numbers --color=always {1} --highlight-line {2}' --preview-window=right:50%)
    if [[ -n $file_line ]]; then
        local file=$(echo "$file_line" | cut -d: -f1)
        local line=$(echo "$file_line" | cut -d: -f2)
        nvim --goto "$file:$line"
    fi
}

# Function for fuzzy file finding with VS Code
vcf() {
    local file
    # Run fzf and check its exit status separately
    file=$(fd --type f | fzf --preview 'bat --style=numbers --color=always {}' --preview-window=right:50%)
    local exit_status=$?
    if [ $exit_status -eq 0 ] && [ -n "$file" ]; then
        code "$file"
    fi
}
# Function for fuzzy file finding with nvim
vff() {
    local file
    # Run fzf and check its exit status separately
    file=$(fd --type f | fzf --preview 'bat --style=numbers --color=always {}' --preview-window=right:50%)
    local exit_status=$?
    if [ $exit_status -eq 0 ] && [ -n "$file" ]; then
        v "$file"
    fi
}
# Function for fuzzy file finding with cursor
cf() {
    local file
    # Run fzf and check its exit status separately
    file=$(fd --type f | fzf --preview 'bat --style=numbers --color=always {}' --preview-window=right:50%)
    local exit_status=$?
    if [ $exit_status -eq 0 ] && [ -n "$file" ]; then
        cc "$file"
    fi
}
# Yazi config
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}



yt() {
    if [ "$#" -eq 0 ] || [ "$#" -gt 2 ]; then
        echo "Usage: yt [-t | --timestamps] youtube-link"
        echo "Use the '-t' flag to get the transcript with timestamps."
        return 1
    fi

    transcript_flag="--transcript"
    if [ "$1" = "-t" ] || [ "$1" = "--timestamps" ]; then
        transcript_flag="--transcript-with-timestamps"
        shift
    fi
    local video_link="$1"
    fabric -y "$video_link" $transcript_flag
}



