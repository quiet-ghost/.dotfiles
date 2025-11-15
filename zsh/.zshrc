# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Bin PATH
export PATH="$HOME/.cache/.bun/bin:$PATH"

if [ -n "$ZSH_VERSION" ]; then
    eval "$(mise activate zsh)"
    export GOPATH="$HOME/go"
    export PATH="$GOPATH/bin:$PATH"
    ZSH_THEME=""
    zstyle ':omz:update' mode auto
    
    plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)
fi

[[ -f ~/.env.private ]] && source ~/.env.private

if [ -n "$ZSH_VERSION" ]; then
    source $ZSH/oh-my-zsh.sh
    source /usr/share/fzf/key-bindings.zsh
    source /usr/share/fzf/completion.zsh
fi

# FZF setup - only if fzf is available
if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)
    export FZF_DEFAULT_OPTS="--height=20% --layout=reverse --border=rounded --padding=1 --color='bg+:#313244,bg:#1e1e2e,spinner:#74c7ec,hl:#89b4fa,fg:#cdd6f4,header:#74c7ec,info:#89b4fa,pointer:#74c7ec,marker:#74c7ec,fg+:#cdd6f4,prompt:#89b4fa,hl+:#89b4fa,border:#6c7086' --preview 'bat --color=always --style=numbers --line-range=:500 {}' --bind 'focus:transform-header:file --brief {}'"
fi

# Ensure ~/.local/bin is in PATH (after all other PATH modifications)
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/usr/bin:$PATH"
#export JAVA_HOME=/usr/lib/jvm/liberica-jdk-17-full

. "$HOME/.local/share/../bin/env"

# Key bindings
bindkey -s '^[f' 'vf\n'
bindkey -s '^[s' 'tmux-sessionizer\n'
# bindkey -s '^[w' 'mux-sesh\n'

# Java - let mise manage JAVA_HOME dynamically
export JAVA_HOME="$(mise where java 2>/dev/null || echo '')"

eval "$(starship init zsh)"

# Unalias any ls variants set by Oh My Zsh or plugins
unalias ls 2>/dev/null

# Aliases - loaded last to override everything
source ~/.dotfiles/zsh/aliases.zsh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
