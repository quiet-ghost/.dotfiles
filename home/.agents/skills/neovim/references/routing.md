# Neovim Routing

Use this reference to decide where a Neovim change belongs.

## Framework Detection

Check for these markers before editing:

| Marker | Meaning | Next Step |
|--------|---------|-----------|
| `lua/config/lazy.lua` imports `lazyvim.plugins` | LazyVim starter | Use `lazyvim` skill first |
| Plugin spec contains `LazyVim/LazyVim` | LazyVim-based config | Use `lazyvim` skill first |
| `lazy-lock.json` only | lazy.nvim, not necessarily LazyVim | Inspect plugin specs |
| `packer_compiled.lua` or `use { ... }` | packer.nvim config | Follow existing packer layout |
| `init.vim` with Vimscript | Vimscript-first config | Preserve style unless migrating is requested |
| `init.lua` plus custom `lua/` modules | Plain Lua config | Use this skill |

Ignore generated or cache-like output unless the user targets it directly, including `.jdtls-out/`, plugin lock output, logs, and build artifacts.

## File Ownership

Prefer existing owner files over new files.

| Change | Usual Owner |
|--------|-------------|
| Global options | `lua/config/options.lua`, `lua/options.lua`, or option module |
| Keymaps | `lua/config/keymaps.lua`, `lua/keymaps.lua`, or mapping module |
| Autocmds | `lua/config/autocmds.lua`, `lua/autocmds.lua`, or autocmd module |
| Plugin config | Existing plugin spec/config module |
| LSP servers | Existing `lsp`, `nvim-lspconfig`, or language module |
| Diagnostics UI | Existing diagnostics, LSP, or UI module |
| Filetype behavior | `ftplugin/`, `after/ftplugin/`, autocmd module, or plugin spec |

## Edit Strategy

1. Search exact mapping, option, command, autocmd group, plugin name, or LSP server first.
2. Read the owner file plus one adjacent pattern file.
3. Preserve module return shape: table spec, setup function, or side-effect module.
4. Add new files only when existing layout already groups by feature/plugin and no owner exists.
5. Avoid broad rewrites during small behavior fixes.

## Quick Commands

Use these only when they fit the repo and are safe:

```bash
nvim --headless -u NONE "+qa"
nvim --headless --clean "+qa"
nvim --headless "+qa"
nvim --headless "+checkhealth" "+qa"
```

`-u NONE` isolates Neovim itself. `--clean` isolates user config. Full startup can load plugins and may install missing dependencies in some setups; inspect config first.
