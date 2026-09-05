# General aliases
alias wb="omarchy restart shell"
alias dc="logout"
alias sz="source ~/.zshrc"
alias xx='clear'
alias search='web-search'
alias q='web-search'
alias pbcopy='xsel --clipboard --input'
alias pbpaste='xsel --clipboard --output'
alias v='nvim'
alias vim='nvim --clean'
alias nvim-tj='NVIM_APPNAME=nvim-tj nvim'
alias nvim-prime='NVIM_APPNAME=nvim-prime nvim'
alias oc='opencode'
unalias oc2 mup 2>/dev/null || true
unfunction oc2up 2>/dev/null || true
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
function mup() {
  MISE_MINIMUM_RELEASE_AGE=0 npm_config_min_release_age=0 mise up "$@" || return
  opencode-update
}

win() {
  local password

  ssh -o BatchMode=yes ghost-dev '
    compose="$HOME/.config/windows/docker-compose.yml"
    docker compose -f "$compose" up -d >/dev/null || exit 1

    for _ in $(seq 1 60); do
      docker logs omarchy-windows 2>&1 | grep -qi "windows started successfully" && exit 0
      sleep 2
    done

    echo "Windows did not become ready within two minutes." >&2
    exit 1
  ' || return 1

  password=$(ssh -o BatchMode=yes ghost-dev \
    'docker inspect omarchy-windows --format "{{range .Config.Env}}{{println .}}{{end}}" | sed -n "s/^PASSWORD=//p"') || {
    print -u2 'Could not retrieve the Windows password from ghost-dev.'
    return 1
  }

  [[ -n "$password" ]] || {
    print -u2 'The omarchy-windows container has no configured password.'
    return 1
  }

  printf '%s\n' \
    '/v:ghost-dev' \
    '/u:ghost-win' \
    '/cert:tofu' \
    '/auth-pkg-list:!kerberos,!u2u' \
    '/dynamic-resolution' \
    '+clipboard' \
    '+auto-reconnect' \
    "/p:$password" |
    xfreerdp3 /args-from:stdin
}

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
