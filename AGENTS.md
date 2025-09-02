# Coding Agent Guidelines for Ghost's Dotfiles

## Build/Test Commands
- Shell scripts: Run directly with `bash script.sh` or `./script.sh` (ensure executable)
- Lint shell: `shellcheck *.sh` (if installed)
- Test single script: `bash -n script.sh` for syntax check
- Go modules: `cd bin/.local/bin && go build && go test`
- Neovim config: `nvim --headless -c "checkhealth" -c "q"`

## Code Style & Conventions
- **Shell Scripts**: Use `#!/usr/bin/env bash` or `#!/bin/bash`, set -e for error handling
- **Variables**: UPPERCASE for constants/env vars, lowercase for local vars
- **Functions**: log_info(), log_success(), log_warning() for consistent output
- **Colors**: Use predefined color codes (RED, GREEN, YELLOW, BLUE, PURPLE, NC)
- **File Organization**: Config in `.config/`, binaries in `.local/bin/` or `usr/bin/`
- **Stow Structure**: Each tool in its own directory with proper stow layout
- **Error Handling**: Always check command success, use set -e, provide fallbacks
- **Lua (Neovim)**: Follow LazyVim patterns, modular plugin configs in lua/plugins/
- **Imports**: Source scripts with absolute paths or $HOME references
- **Testing**: Create timeshift snapshots before major changes (Arch Linux)