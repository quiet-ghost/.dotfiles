# General aliases
alias dc="logout"
alias sz="source ~/.zshrc"
alias xx='clear'
alias pbcopy='xsel --clipboard --input'
alias pbpaste='xsel --clipboard --output'
alias v='nvim'
alias nvim-tj='NVIM_APPNAME=nvim-tj nvim'
alias nvim-java='NVIM_APPNAME=nvim-java nvim'
alias lg='lazygit'
alias ls='eza --icons --long --git --group-directories-first'
alias oc='opencode'
alias df='duf'
alias windows='omarchy-windows-vm stop'
alias sf='source ~/.fabric-patterns.zsh'
alias jn='new-java'
alias cn='new-cpp'
alias ya='yazi'

#alias suffix
alias -s json=jless
alias -s md=bat
alias -s txt=bat
alias -s log=bat
alias -s py='$EDITOR'
alias -s js='$EDITOR'
alias -s ts='$EDITOR'
alias -s go='$EDITOR'
alias -s rs='$EDITOR'
alias -s java='$EDITOR'
alias -s cpp='$EDITOR'

# FZF-based aliases
alias vh="eval \$(history | fzf | cut -d' ' -f4-)"
alias vk="kill -9 \$(ps aux | fzf --multi | awk '{print \$2}')"
alias vb="git checkout \$(git branch --all | fzf | tr -d ' *')"
alias vc="git checkout \$(git log --oneline | fzf --preview 'git show {1}' | cut -d' ' -f1)"
alias vp="nvim \$(find ~/ ~/dev/ ~/personal/ ~/.dotfiles/ -mindepth 1 -maxdepth 3 -type d | fzf)"
alias vf='nvim -c "lua require(\"telescope.builtin\").find_files({ search_dirs = { \"~/dev/\", \"~/personal/\", \"~/.dotfiles/\" } })"'
alias vg='nvim -c "lua require(\"telescope.builtin\").live_grep({ search_dirs = { \"~/dev/\", \"~/personal/\", \"~/.dotfiles/\" } })"'

# Tmux aliases
alias tk='tmux-kill-session'
alias ts='tmux-switch-session'
alias ta='tmux attach -t quietghost'

# Directory navigation
alias p='cd ~/personal'
alias pl='cd ~/personal/Learning'
alias pn='cd ~/personal/Notes'
alias pa='cd ~/personal/Archive'
alias d='cd ~/dev'
alias dp='cd ~/dev/projects/'
alias dw='cd ~/dev/work'
alias dt='cd ~/dev/tools'
alias dos='cd ~/dev/open-source'
alias nvc="cd $HOME/.config/nvim && nvim"

# Mail and Maven
alias m='mailsy m'
alias mm='mailsy me'
alias mg='sudo mailsy g'
alias mvnag='mvn archetype:generate'
