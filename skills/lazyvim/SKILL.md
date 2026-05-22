---
name: lazyvim
description: Customize and debug LazyVim-based Neovim setups, including lua/config, lua/plugins, LazyVim defaults, extras, lazy.nvim plugin specs, keymaps, and loading behavior. Use when a repo depends on LazyVim/LazyVim or follows the LazyVim starter layout.
references:
  - references/configuration.md
  - references/plugin-specs.md
  - references/troubleshooting.md
---

# LazyVim

Use this skill for LazyVim distribution conventions on top of Neovim.

## When To Use

Use this skill when the task involves:

- `LazyVim/LazyVim`, the LazyVim starter, or `lazyvim.plugins`
- `lua/config/options.lua`, `lua/config/keymaps.lua`, `lua/config/autocmds.lua`, or `lua/config/lazy.lua`
- `lua/plugins/*.lua` plugin specs, overrides, disable rules, or keymaps
- LazyVim extras, defaults, news, root detection, picker/completion choices, or autoformat behavior

For raw Neovim Lua API details, also use the `neovim` skill.

## Default Approach

1. Confirm the repo is actually LazyVim-based.
2. Read `init.lua`, `lua/config/lazy.lua`, and the smallest owning `lua/config` or `lua/plugins` file.
3. Put options, keymaps, and autocmds under `lua/config/`.
4. Put plugin additions, overrides, dependencies, and disabled plugins under `lua/plugins/*.lua`.
5. Use lazy.nvim merge rules instead of copying upstream LazyVim defaults.
6. Verify with the smallest safe startup or health check; avoid sync/update unless requested.

## Guardrails

- Do not manually `require` `autocmds`, `keymaps`, `lazy`, or `options` under `lua/config/`; LazyVim loads them automatically.
- Do not use `LazyVim.safe_keymap_set` in user config; use `vim.keymap.set`.
- Disable plugins with `{ "plugin/name", enabled = false }` in a user plugin spec.
- Disable default plugin keymaps with the exact same `lhs` and mode.
- Prefer `opts = { ... }` or `opts = function(_, opts) ... end` over replacing full plugin config.
- Do not run `:Lazy sync`, `:Lazy update`, or `:LazyExtras` changes unless the user asks.

## Reading Order

| Task | Files To Read |
|------|---------------|
| File placement or default behavior | `references/configuration.md` |
| Add, disable, or override plugin | `references/plugin-specs.md` |
| Startup, extras, or plugin loading issue | `references/troubleshooting.md` |

## Primary Docs

- https://www.lazyvim.org/
- https://www.lazyvim.org/configuration
- https://www.lazyvim.org/configuration/general
- https://www.lazyvim.org/configuration/plugins
- https://www.lazyvim.org/extras

## In This Reference

| File | Purpose |
|------|---------|
| `references/configuration.md` | LazyVim file layout and auto-loading rules |
| `references/plugin-specs.md` | lazy.nvim spec merge, keys, disable, and override patterns |
| `references/troubleshooting.md` | Startup, plugin state, extras, and health triage |
