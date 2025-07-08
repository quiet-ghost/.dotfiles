# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
# Path to nvim installation
export PATH="$PATH:/usr/bin/nvim"
# Path to Tmux-sessionizer
export PATH="$HOME/.local/bin:$PATH"
#avante path
export OPENAI_API_KEY="sk-proj-g6bsJchxUDrKfxtuBC8eT3BlbkFJ6ssBDLXm0N7LmWPMr3mI"
export ANTHROPIC_API_KEY="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"
export XAI_API_KEY="xai-QoL9AXqNY2t3toIezu5sIi9HP1wQWykkbMqPByZomZXf0SuaxrbsKpMe9CpWqTsGe3bQmN7a5OcoSa0y"

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
alias vp="nvim \$(find ~/ ~/dev/ ~/personal/ ~/.dotfiles/ -mindepth 1 -maxdepth 3 -type d | fzf)" # Project switcher
alias lg='lazygit'
alias vf='nvim -c "lua require(\"telescope.builtin\").find_files({ search_dirs = { \"~/dev/\", \"~/personal/\", \"~/.dotfiles/\" } })"'
alias vg='nvim -c "lua require(\"telescope.builtin\").live_grep({ search_dirs = { \"~/dev/\", \"~/personal/\", \"~/.dotfiles/\" } })"'
alias v='nvim'
alias ya='yazi'
alias yac='yazi --cwd-file'
alias ls='eza --icons=always'
alias tms='tmux has-session -t main 2>/dev/null && tmux attach-session -t main || { tmux new-session -s main -d \; send-keys -t default:1 "opencode" Enter  \; new-window -n term \; new-window \; attach-session -t main:1; }'
alias tmss='tmux-sessionizer'
alias tmp='tmux-sessionizer-nvim-style'  # Nvim plugin style interface
alias tk='tmux-kill-session'
alias ts='tmux-switch-session'
alias arc='sudo arch-clean.sh'

# Personal directories
alias p='cd ~/personal'
alias pp='cd ~/personal/Projects'
alias pl='cd ~/personal/Learning'
alias pn='cd ~/personal/Notes'
alias pa='cd ~/personal/Archive'

# Dev directories  
alias d='cd ~/dev'
alias dw='cd ~/dev/work'
alias dt='cd ~/dev/tools'
alias dos='cd ~/dev/open-source'
alias c='cd ~/.dotfiles'

#Tools
alias m='mailsy m'
alias mm='mailsy me'
alias mg='sudo mailsy g'
alias st='speedtest-cli --simple'
alias df='duf'
alias oc='opencode'
alias mvnag='mvn archetype:generate'
alias windows='~/boot-to-windows.sh'


# fzf configuration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source <(fzf --zsh)
export FZF_DEFAULT_OPTS="--style full --preview 'fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}'"

# Golang environment variables
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin:/usr/bin


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

# Define the base directory for Obsidian notes
#obsidian_base="/home/ghost/Github/Notes/Imports"

# Loop through all files in the ~/.config/fabric/patterns directory
#for pattern_file in ~/.config/fabric/patterns/*; do
    # Get the base name of the file (i.e., remove the directory path)
 #   pattern_name=$(basename "$pattern_file")

    # Remove any existing alias with the same name
  #  unalias "$pattern_name" 2>/dev/null

    # Define a function dynamically for each pattern
   # eval "
    #$pattern_name() {
     #   local title=\$1
      #  local date_stamp=\$(date +'%Y-%m-%d')
       # local output_path=\"\$obsidian_base/\${date_stamp}-\${title}.md\"

        # Check if a title was provided
        #if [ -n \"\$title\" ]; then
            # If a title is provided, use the output path
         #   fabric --pattern \"$pattern_name\" -o \"\$output_path\"
       # else
            # If no title is provided, use --stream
       #     fabric --pattern \"$pattern_name\" --stream
        #fi
  #  }
   # "
#done

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


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export RUSTONIG_SYSTEM_LIBONIG=1

# opencode
export PATH=/home/ghost/.opencode/bin:$PATH

# Bind Alt+s to tmux-sessionizer
bindkey -s '^[s' 'tmux-sessionizer\n'
# Bind Alt+w to tmux session switcher
bindkey -s '^[w' 'tmux-switch-session\n'

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
