# LazyVim Troubleshooting

LazyVim failures usually come from file placement, plugin spec merge behavior, plugin state, or upstream default changes.

## Confirm LazyVim

Before applying LazyVim conventions, confirm at least one marker:

- `lua/config/lazy.lua` imports `{ "LazyVim/LazyVim", import = "lazyvim.plugins" }`
- A plugin spec depends on `LazyVim/LazyVim`
- Starter layout exists with `lua/config/` and `lua/plugins/`
- LazyVim docs, extras, or defaults are explicitly referenced by the user

## Startup Triage

1. Capture exact startup error and first failing Lua file.
2. Read `init.lua` and `lua/config/lazy.lua`.
3. Find the user spec that owns the failing plugin or setting.
4. Prefer removing or narrowing the user override before touching core bootstrap.

Potentially useful command after inspecting config:

```bash
nvim --headless "+qa"
```

Fresh LazyVim clones can bootstrap or install plugins during startup. Avoid this command if mutation would be surprising.

## Plugin State

Use Lazy UI commands interactively when needed:

```vim
:Lazy
:Lazy log
:Lazy profile
:Lazy health
```

Do not run these without user intent:

```vim
:Lazy sync
:Lazy update
:Lazy restore
```

Those commands can change installed plugin state or lockfiles.

## Extras

LazyVim extras are managed with:

```vim
:LazyExtras
```

Do not enable or disable extras unless the user asks. For existing extras issues, inspect imports and plugin specs before changing extras state.

## Keymap Conflicts

LazyVim uses which-key and plugin spec `keys`. Check both general config and plugin specs:

- `lua/config/keymaps.lua` for user global maps
- `lua/plugins/*.lua` for plugin keymaps
- LazyVim keymap docs for defaults

To disable a default plugin keymap, add the disable entry in the plugin spec with exact mode. To override it, add the same `lhs` with a new right-hand side.

## Autoformat Issues

Check these layers in order:

1. `vim.g.autoformat` in `lua/config/options.lua`
2. Plugin formatter spec, often `conform.nvim`
3. Buffer-local disable toggles or autocmds
4. LSP server formatting capability settings

Avoid disabling formatting globally when only one language/server is wrong.

## Health Checks

Use focused checks:

```vim
:checkhealth
:checkhealth lazy
:checkhealth vim.lsp
:checkhealth provider
```

Health warnings are not automatically blockers. Tie each warning to the reported symptom.

## Docs

- https://www.lazyvim.org/keymaps
- https://www.lazyvim.org/extras
- https://www.lazyvim.org/configuration/general
- https://www.lazyvim.org/configuration/plugins
