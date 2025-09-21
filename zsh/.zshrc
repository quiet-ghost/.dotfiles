# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
eval "$(mise activate zsh)"


# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"
zstyle ':omz:update' mode auto

plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)

alias sz="source ~/.zshrc"
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
alias sf='source ~/.fabric-patterns.zsh'
# fabric alias removed - now handled by lazy loading function

# FZF-based aliases
alias vh="eval \$(history | fzf | cut -d' ' -f4-)"
alias vk="kill -9 \$(ps aux | fzf --multi | awk '{print \$2}')"
alias vb="git checkout \$(git branch --all | fzf | tr -d ' *')"
alias vc="git checkout \$(git log --oneline | fzf --preview 'git show {1}' | cut -d' ' -f1)"
alias vp="nvim \$(find ~/ ~/dev/ ~/personal/ ~/.dotfiles/ -mindepth 1 -maxdepth 3 -type d | fzf)"
alias vf='nvim -c "lua require(\"telescope.builtin\").find_files({ search_dirs = { \"~/dev/\", \"~/personal/\", \"~/.dotfiles/\" } })"'
alias vg='nvim -c "lua require(\"telescope.builtin\").live_grep({ search_dirs = { \"~/dev/\", \"~/personal/\", \"~/.dotfiles/\" } })"'

# Tmux aliases
# alias tms='tmux has-session -t main 2>/dev/null && tmux attach-session -t main || { tmux new-session -s main -d \; send-keys -t default:1 "opencode" Enter  \; new-window -n term \; new-window \; attach-session -t main:1; } && { tmux has-session -t monitoring 2>/dev/null || { tmux new-session -s monitoring -d -n btop "btop" \; new-window -n opencode-sesh-server "/home/ghost-desktop/dev/open-source/opencode-sessions/server"; }; }'
# alias tmss='tmux-sessionizer'
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
alias nvc="cd $HOME/.config/nvim && nvim"

# Mail and Maven
alias m='mailsy m'
alias mm='mailsy me'
alias mg='sudo mailsy g'
alias mvnag='mvn archetype:generate'

# Key bindings
bindkey -s '^[f' 'vf\n'
bindkey -s '^[s' 'tmux-sessionizer\n'
bindkey -s '^[w' 'mux-sesh\n'

[[ -f ~/.env.private ]] && source ~/.env.private
source $ZSH/oh-my-zsh.sh
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# FZF setup - only if fzf is available
if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)
    export FZF_DEFAULT_OPTS="--height=20% --layout=reverse --border=rounded --padding=1 --color='bg+:#313244,
bg:#1e1e2e,spinner:#74c7ec,hl:#89b4fa,fg:#cdd6f4,header:#74c7ec,info:#89b4fa,pointer:#74c7ec,marker:#74c7ec,
fg+:#cdd6f4,prompt:#89b4fa,hl+:#89b4fa,border:#6c7086' --preview 'bat --color=always --style=numbers -
-line-range=:500 {}' --bind 'focus:transform-header:file --brief {}'"
fi

# Ensure ~/.local/bin is in PATH (after all other PATH modifications)
export PATH="$HOME/.local/bin:$PATH"export PATH="$HOME/.local/bin:$PATH"
