# General aliases
alias wb="waybar &>/dev/null & disown"
alias dc="logout"
alias sz="source ~/.zshrc"
alias xx='clear'
alias search='web-search'
alias q='web-search'
alias pbcopy='xsel --clipboard --input'
alias pbpaste='xsel --clipboard --output'
alias v='nvim'
alias nvim-tj='NVIM_APPNAME=nvim-tj nvim'
alias nvim-prime='NVIM_APPNAME=nvim-prime nvim'
alias oc='opencode'
alias df='duf'
alias windows='omarchy-windows-vm stop'
alias sf='source ~/.fabric-patterns.zsh'
alias jn='new-java'
alias cn='new-clion'
alias rn='new-rust'
alias nr='repo-init'
alias ginit='repo-init'
alias ya='yazi'
alias bd="bootdev"
alias cc="calc"
alias cat=bat

#git
alias lg='lazygit'
alias ghd='gh dash'
alias gpr='gh-pr-create-smart'
alias ghi='gh-issue-create-smart'
alias gl="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"
alias gs="git status"
alias wtd='gh pr diff'
alias wtv='gh pr view'
alias wtc='gh pr checks'
alias wtp='gh pr review'
alias wtiv='gh issue view'
alias wtic='gh issue comment'
alias wtdd='wd --delete-remote'

#Eza
alias l="eza -l --icons --git -a"
alias ls='eza --icons --long --group-directories-first'
alias lt="eza --tree --level=2 --long --icons"
alias ltree="eza --tree --level=2  --icons"
alias lsg='eza --icons --long --git --group-directories-first'
alias ltg="eza --tree --level=2 --long --icons --git"

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

# Herdr
alias ha='herdr'

# Directory navigation
alias p='cd ~/personal'
alias pl='cd ~/dev/school'
alias pn='cd ~/personal/Notes'
alias pa='cd ~/personal/Archive'
alias d='cd ~/dev'
alias dp='cd ~/dev/projects/'
alias dw='cd ~/dev/work'
alias dr='cd ~/dev/repos'
alias ds='cd ~/dev/school'
alias dos='cd ~/dev/open-source'
alias nvc="cd $HOME/.config/nvim && nvim"

# Mail and Maven
alias m='mailsy m'
alias mm='mailsy me'
alias mg='sudo mailsy g'
alias mvnag='mvn archetype:generate'
