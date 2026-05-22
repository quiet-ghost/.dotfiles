---
name: neovim
description: Configure and troubleshoot core Neovim config, Lua runtime APIs, options, keymaps, autocmds, providers, LSP, diagnostics, and headless health checks. Use when editing init.lua, lua/, vim.opt, vim.keymap.set, vim.api.*, :checkhealth, or non-LazyVim Neovim setups.
references:
  - references/routing.md
  - references/lua-api.md
  - references/troubleshooting.md
---

# Neovim

Use this skill for core Neovim config and runtime behavior.

## When To Use

Use this skill when the task involves:

- `init.lua`, `init.vim`, `lua/`, runtimepath, or filetype behavior
- Lua config APIs: `vim.opt`, `vim.g`, `vim.keymap.set`, `vim.api.*`, `vim.diagnostic.*`
- Keymaps, options, autocmds, user commands, providers, health checks, LSP, or diagnostics
- Plain Neovim setups, custom plugin managers, or unknown Neovim frameworks

If the repo uses `LazyVim/LazyVim` or the LazyVim starter layout, use the `lazyvim` skill first and this skill only for core API details.

## Default Approach

1. Detect the config framework before changing file layout.
2. Read `init.lua` and the smallest owning `lua/` files before editing.
3. Change the narrowest file that owns the behavior.
4. Prefer official Lua APIs over Vimscript or plugin-specific wrappers unless the repo already chose otherwise.
5. Verify with the smallest safe headless command, health check, or focused startup test.

## Guardrails

- Prefer `vim.opt`, `vim.opt_local`, and `vim.opt_global` for options.
- Prefer `vim.keymap.set` with `desc`, explicit modes, and buffer scope when relevant.
- Prefer `vim.api.nvim_create_augroup`, `vim.api.nvim_create_autocmd`, and callbacks for autocmds.
- Keep keymaps, options, autocmds, and plugin config in existing owner files.
- Avoid plugin install/update/sync actions unless the user asks.
- Treat generated config output like `.jdtls-out/` as read-only unless explicitly targeted.

## Reading Order

| Task | Files To Read |
|------|---------------|
| Route unknown Neovim config | `references/routing.md` |
| Lua API or config edit | `references/lua-api.md` |
| Startup, provider, or health issue | `references/troubleshooting.md` |

## Primary Docs

- https://neovim.io/doc/
- https://neovim.io/doc/user/lua/
- https://neovim.io/doc/user/api/

## In This Reference

| File | Purpose |
|------|---------|
| `references/routing.md` | Config detection and file ownership |
| `references/lua-api.md` | Preferred Neovim Lua APIs and sharp edges |
| `references/troubleshooting.md` | Startup, provider, LSP, and health triage |
