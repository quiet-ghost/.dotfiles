# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
# Path to nvim installation
export PATH="$PATH:/usr/bin/nvim"
# Path to Tmux-sessionizer
export PATH="$HOME/.local/bin:$PATH"
#avante path
export OPENAI_API_KEY="sk-proj-g6bsJchxUDrKfxtuBC8eT3BlbkFJ6ssBDLXm0N7LmWPMr3mI"
export ANTHROPIC_API_KEY="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"
export XAI_API_KEY=xai-QoL9AXqNY2t3toIezu5sIi9HP1wQWykkbMqPByZomZXf0SuaxrbsKpMe9CpWqTsGe3bQmN7a5OcoSa0y

# Theme
ZSH_THEME="robbyrussell"

# Auto-update Oh My Zsh
zstyle ':omz:update' mode auto

# Plugins
plugins=(git zsh-syntax-highlighting fast-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
source ${ZSH_CUSTOM:- ~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ${ZSH_CUSTOM:- ~/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source ${ZSH_CUSTOM:- ~/.oh-my-zsh/custom}/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# Zsh configuration file
alias xx='clear'
alias pbcopy='xsel --clipboard --input'
alias pbpaste='xsel --clipboard --output'
alias vh="eval \$(history | fzf | cut -d' ' -f4-)" # History search
alias vk="kill -9 \$(ps aux | fzf --multi | awk '{print \$2}')" # Kill processes
alias vb="git checkout \$(git branch --all | fzf | tr -d ' *')" # Git branch and commit switch
alias vc="git checkout \$(git log --oneline | fzf --preview 'git show {1}' | cut -d' ' -f1)"
alias vp="nvim \$(find ~/ ~/Github/ ~/.dotfiles/ -mindepth 1 -maxdepth 2 -type d | fzf)" # Project switcher
alias cc='~/Applications/Cursor-0.47.9-x86_64.AppImage'
alias lg='lazygit'
alias vf='nvim -c "lua require(\"telescope.builtin\").find_files({ search_dirs = { \"~/Github/\", \"~/.dotfiles/\" } })"'
alias vg='nvim -c "lua require(\"telescope.builtin\").live_grep({ search_dirs = {  \"~/Github/\", \"~/.dotfiles/\" } })"'
alias v='nvim'
alias ya='yazi'
alias yac='yazi --cwd-file'
alias ls='eza --icons=always'
alias tms='tmux has-session -t main 2>/dev/null && tmux attach-session -t main || { tmux new-session -s main -d \; send-keys -t main:1 "nvim" Enter  \; new-window -n term \; new-window \; attach-session -t main:1; }'
alias tmss='~/Github/Repos/tmux-sessionizer/tmux-sessionizer'
alias arc='sudo arch-clean.sh'

# fzf configuration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source <(fzf --zsh)
export FZF_DEFAULT_OPTS="--style full --preview 'fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}'"

# Golang environment variables
export PATH=$PATH:/usr/local/go/bin

# Bind Alt+F to vcf
bindkey -s '^[f' 'vf\n'

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


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export RUSTONIG_SYSTEM_LIBONIG=1
