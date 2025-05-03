# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
# Path to nvim installation
export PATH="$PATH:/usr/bin/nvim"
# Path to Tmux-sessionizer
export PATH="$HOME/.local/bin:$PATH"
#avante path
export OPENAI_API_KEY="sk-proj-g6bsJchxUDrKfxtuBC8eT3BlbkFJ6ssBDLXm0N7LmWPMr3mI"
export ANTHROPIC_API_KEY="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"
# Theme
ZSH_THEME="robbyrussell"

# Auto-update Oh My Zsh
zstyle ':omz:update' mode auto

# Plugins
plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-autocomplete fast-syntax-highlighting)
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
alias vp="nvim \$(find ~/Github/ -maxdepth 2 -type d | fzf)" # Project switcher
alias cc='~/Applications/Cursor-0.47.9-x86_64.AppImage'
alias lg='lazygit'
alias tf='nvim -c "Telescope find_files"'
alias tg='nvim -c "Telescope live_grep"'
alias v='nvim'
alias ya='yazi'
alias yac='yazi --cwd-file'
alias tms='tmux has-session -t main 2>/dev/null && tmux attach-session -t main || { tmux new-session -s main -d \; send-keys -t main:1 "nvim" Enter  \; new-window -n term \; new-window \; attach-session -t main:1; }'
alias tmss='tmux-sessionizer'
alias arc='sudo arch-clean.sh'

# fzf configuration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source <(fzf --zsh)
export FZF_DEFAULT_OPTS="--style full --preview 'fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}'"

# Golang environment variables
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$HOME/.local/bin:$PATH

# pyenv
#export PYENV_ROOT="$HOME/.pyenv"
#[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
#eval "$(pyenv init - zsh)"

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
        nvim "$file"
    fi
}
# Function for fuzzy file finding with nvim
vf() {
    local file
    # Run fzf and check its exit status separately
    file=$(fd --type f | fzf --preview 'bat --style=numbers --color=always {}' --preview-window=right:50%)
    local exit_status=$?
    if [ $exit_status -eq 0 ] && [ -n "$file" ]; then
        v "$file"
    fi
}
# Function for fuzzy file finding with nvim
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
