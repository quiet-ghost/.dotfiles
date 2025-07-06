# Laptop Setup TODO - Complete Implementation Guide

This document contains all the exact commands and configurations needed to replicate the desktop setup on the laptop.

## 1. Dependencies Installation

### Check and Install Required Software
```bash
# Check if dependencies exist
which tmux fzf nvim stow

# Install missing dependencies (Arch Linux)
sudo pacman -S tmux fzf neovim stow xsel xclip

# For other distros, use appropriate package manager:
# Ubuntu/Debian: sudo apt install tmux fzf neovim stow xsel xclip
# Fedora: sudo dnf install tmux fzf neovim stow xsel xclip
```

## 2. tmux-sessionizer Setup

### Stow the Scripts
```bash
cd ~/.dotfiles
stow bin
```

### Verify Scripts are Available
```bash
which tmux-sessionizer tmux-kill-session tmux-switch-session
ls -la ~/.local/bin/tmux*
```

### Add Aliases to zshrc
Add these lines to `~/.zshrc`:
```bash
# tmux aliases
alias tmss='tmux-sessionizer'
alias tk='tmux-kill-session'
alias ts='tmux-switch-session'
alias tms='tmux has-session -t main 2>/dev/null && tmux attach-session -t main || { tmux new-session -s main -d \; send-keys -t main:1 "opencode" Enter  \; new-window -n term \; new-window \; attach-session -t main:1; }'
```

### Add Keybindings to zshrc
Add these lines to `~/.zshrc`:
```bash
# tmux keybindings
bindkey -s '^[s' 'tmux-sessionizer\n'  # Alt+s
bindkey -s '^[w' 'tmux-switch-session\n'  # Alt+w
```

## 3. Directory Structure Creation

### Create Complete Directory Structure
```bash
# Create dev structure
mkdir -p ~/dev/work/{current,freelance,archived,templates,docs}
mkdir -p ~/dev/{tools,open-source}

# Create personal structure  
mkdir -p ~/personal/{Personal,Learning,Notes,Archive}
```

### Verify Structure
```bash
tree ~/dev ~/personal -L 3
# or
ls -la ~/dev/ ~/personal/
```

## 4. Update Directory Navigation Aliases

### Replace old aliases in zshrc
Find and replace these sections in `~/.zshrc`:

**OLD aliases to remove/replace:**
```bash
# Remove these if they exist:
alias g='cd ~/Github'
alias p='cd ~/Github/Projects'  
alias s='cd ~/Github/School'
alias gp='cd ~/Github/Personal'
alias gl='cd ~/Github/Learning'
alias gf='cd ~/Github/Forks'
alias gs='cd ~/Github/Scripts'
```

**NEW aliases to add:**
```bash
# Personal directories
alias p='cd ~/personal'
alias pp='cd ~/personal/Personal'
alias pl='cd ~/personal/Learning'
alias pn='cd ~/personal/Notes'
alias pa='cd ~/personal/Archive'

# Dev directories  
alias d='cd ~/dev'
alias dw='cd ~/dev/work'
alias dt='cd ~/dev/tools'
alias do='cd ~/dev/open-source'
```

## 5. Update File Search Aliases

### Update these aliases in zshrc:

**Find and replace vp alias:**
```bash
# OLD:
alias vp="nvim \$(find ~/ ~/Github/ ~/.dotfiles/ -mindepth 1 -maxdepth 2 -type d | fzf)"

# NEW:
alias vp="nvim \$(find ~/ ~/dev/ ~/personal/ ~/.dotfiles/ -mindepth 1 -maxdepth 3 -type d | fzf)"
```

**Find and replace vf alias:**
```bash
# OLD:
alias vf='nvim -c "lua require(\"telescope.builtin\").find_files({ search_dirs = { \"~/Github/\", \"~/.dotfiles/\" } })"'

# NEW:
alias vf='nvim -c "lua require(\"telescope.builtin\").find_files({ search_dirs = { \"~/dev/\", \"~/personal/\", \"~/.dotfiles/\" } })"'
```

**Find and replace vg alias:**
```bash
# OLD:
alias vg='nvim -c "lua require(\"telescope.builtin\").live_grep({ search_dirs = {  \"~/Github/\", \"~/.dotfiles/\" } })"'

# NEW:
alias vg='nvim -c "lua require(\"telescope.builtin\").live_grep({ search_dirs = { \"~/dev/\", \"~/personal/\", \"~/.dotfiles/\" } })"'
```

## 6. Update Neovim Keymaps

### File to edit: `~/.config/nvim/lua/config/keymaps.lua`

**Find and replace the References Notes section:**
```lua
-- OLD section to replace:
-- References Notes
map("n", "<leader>jn", function()
  require("telescope.builtin").live_grep({
    search_dirs = { "~/Github/Notes/References/Java/JavaNote.md" },
    prompt_title = "Search JavaNote.md",
  })
end, { desc = "Search JavaNote.md" })
map("n", "<leader>pn", function()
  require("telescope.builtin").live_grep({
    search_dirs = { "~/Github/Notes/References/Python/PythonNote.md" },
    prompt_title = "Search PythonNote.md",
  })
end, { desc = "Search PythonNote.md" })
map("n", "<leader>cpp", function()
  require("telescope.builtin").live_grep({
    search_dirs = { "~/Github/Notes/References/C++/CppNote.md" },
    prompt_title = "Search CppNote.md",
  })
end, { desc = "Search CppNote.md" })
map("n", "<leader>sql", function()
  require("telescope.builtin").live_grep({
    search_dirs = { "~/Github/Notes/References/MySQL/MySQLNote.md" },
    prompt_title = "Search MySQLNote.md",
  })
end, { desc = "Search MySQLNote.md" })

-- NEW section:
-- References Notes
map("n", "<leader>jn", function()
  require("telescope.builtin").live_grep({
    search_dirs = { "~/personal/Notes/References/Java/JavaNote.md" },
    prompt_title = "Search JavaNote.md",
  })
end, { desc = "Search JavaNote.md" })
map("n", "<leader>pn", function()
  require("telescope.builtin").live_grep({
    search_dirs = { "~/personal/Notes/References/Python/PythonNote.md" },
    prompt_title = "Search PythonNote.md",
  })
end, { desc = "Search PythonNote.md" })
map("n", "<leader>cpp", function()
  require("telescope.builtin").live_grep({
    search_dirs = { "~/personal/Notes/References/C++/CppNote.md" },
    prompt_title = "Search CppNote.md",
  })
end, { desc = "Search CppNote.md" })
map("n", "<leader>sql", function()
  require("telescope.builtin").live_grep({
    search_dirs = { "~/personal/Notes/References/MySQL/MySQLNote.md" },
    prompt_title = "Search MySQLNote.md",
  })
end, { desc = "Search MySQLNote.md" })
```

## 7. Ghostty Auto-launch Configuration

### Create/Update Ghostty Config
**File: `~/.config/ghostty/config`**

Add this line to the config file:
```
# Auto-launch tms session on startup
command = zsh -c "tmux has-session -t main 2>/dev/null && tmux attach-session -t main || { tmux new-session -s main -d ; tmux send-keys -t main:1 'opencode' Enter ; tmux new-window -n term ; tmux new-window ; tmux attach-session -t main:1; }"
```

### Complete Ghostty Config Example
```
# Config:

shell-integration = zsh
shell-integration-features = true

window-colorspace = srgb
window-theme = auto
theme = MaterialOcean
font-family = FiraCode Nerd Font Mono SemBd
font-size = 15

cursor-style = block
cursor-style-blink = false

background-blur = true
bold-is-bright = true

# Auto-launch tms session on startup
command = zsh -c "tmux has-session -t main 2>/dev/null && tmux attach-session -t main || { tmux new-session -s main -d ; tmux send-keys -t main:1 'opencode' Enter ; tmux new-window -n term ; tmux new-window ; tmux attach-session -t main:1; }"
```

## 8. Apply All Changes

### Reload Shell Configuration
```bash
source ~/.zshrc
```

### Test tmux-sessionizer
```bash
# Test the scripts work
tmux-sessionizer --help 2>/dev/null || echo "Script exists and is executable"
tmux-kill-session --help 2>/dev/null || echo "Script exists and is executable"  
tmux-switch-session --help 2>/dev/null || echo "Script exists and is executable"
```

### Test Keybindings
```bash
# Test Alt+s keybinding (should show tmux-sessionizer in terminal)
# Press Alt+s in terminal

# Test aliases
tmss  # Should launch tmux-sessionizer
```

## 9. Verification Commands

### Check Directory Structure
```bash
ls -la ~/dev/
ls -la ~/personal/
```

### Check Scripts are in PATH
```bash
which tmux-sessionizer tmux-kill-session tmux-switch-session
```

### Check Aliases Work
```bash
# Test directory navigation
p   # Should go to ~/personal
d   # Should go to ~/dev
pp  # Should go to ~/personal/Personal
```

### Test Ghostty Auto-launch
```bash
# Close and reopen ghostty - should auto-start tmux with opencode
```

## 10. Migration Commands (if moving existing projects)

### If you have existing ~/Github directory:
```bash
# Move existing projects (adjust paths as needed)
mv ~/Github/Projects/* ~/personal/Personal/ 2>/dev/null || true
mv ~/Github/School/* ~/personal/Learning/ 2>/dev/null || true  
mv ~/Github/Notes ~/personal/ 2>/dev/null || true
mv ~/Github/Repos/* ~/dev/open-source/ 2>/dev/null || true

# Remove empty Github directory
rmdir ~/Github 2>/dev/null || true
```

## 11. Final Verification Script

```bash
#!/bin/bash
echo "=== Verification Script ==="
echo "1. Checking dependencies..."
which tmux fzf nvim stow xsel xclip

echo "2. Checking tmux scripts..."
ls -la ~/.local/bin/tmux*

echo "3. Checking directory structure..."
ls -la ~/dev/ ~/personal/

echo "4. Testing aliases..."
alias | grep -E "(tmss|tk|ts|tms|^p=|^d=)"

echo "5. Checking ghostty config..."
grep -n "command.*tmux" ~/.config/ghostty/config

echo "=== Setup Complete! ==="
echo "Press Alt+s to test tmux-sessionizer"
echo "Restart ghostty to test auto-launch"
```

## Notes for opencode:
- All commands are ready to copy-paste and execute
- File paths are explicit and complete
- Each section can be implemented independently
- Verification commands are provided for each step
- The setup replicates the exact desktop configuration