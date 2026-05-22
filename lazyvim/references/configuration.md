# LazyVim Configuration

LazyVim is a Neovim distribution layered on lazy.nvim. Preserve its file layout and loading order.

## Starter Layout

LazyVim expects this shape:

```text
~/.config/nvim
├── init.lua
└── lua
    ├── config
    │   ├── autocmds.lua
    │   ├── keymaps.lua
    │   ├── lazy.lua
    │   └── options.lua
    └── plugins
        ├── spec1.lua
        └── spec2.lua
```

Files under `lua/config/` are automatically loaded at the right time. Files under `lua/plugins/` are automatically loaded by lazy.nvim.

## Auto-Loaded Config Files

| File | Purpose | Load Notes |
|------|---------|------------|
| `lua/config/options.lua` | User options and globals | Loaded before lazy.nvim startup |
| `lua/config/keymaps.lua` | User keymaps | Loaded on `VeryLazy` |
| `lua/config/autocmds.lua` | User autocmds | Loaded on `VeryLazy` |
| `lua/config/lazy.lua` | lazy.nvim bootstrap/setup | Owns LazyVim imports and lazy.nvim options |

LazyVim defaults load before user files. User files should override or extend, not copy defaults.

## Placement Rules

- Put `vim.opt`, `vim.g`, and editor globals in `lua/config/options.lua`.
- Put general keymaps in `lua/config/keymaps.lua`.
- Put general autocmds in `lua/config/autocmds.lua`.
- Put plugin setup, plugin keymaps, dependencies, options, and disable rules in `lua/plugins/*.lua`.
- Put colorscheme choice in a spec for `LazyVim/LazyVim` using `opts.colorscheme`.

Example colorscheme override:

```lua
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
```

## Root Lazy Setup

`lua/config/lazy.lua` normally imports LazyVim and local plugin specs:

```lua
require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },
  },
})
```

Avoid changing bootstrap unless the task is specifically about lazy.nvim setup, plugin source policy, or startup behavior.

## Defaults And Globals

LazyVim uses globals for several distro-level choices:

- `vim.g.mapleader`
- `vim.g.maplocalleader`
- `vim.g.autoformat`
- `vim.g.snacks_animate`
- `vim.g.lazyvim_picker`
- `vim.g.lazyvim_cmp`
- `vim.g.root_spec`

Set these in `lua/config/options.lua` unless the repo already has a dedicated owner.

## Do Not

- Do not manually `require("config.options")`, `require("config.keymaps")`, or `lazyvim.config.*`.
- Do not edit upstream LazyVim files in the plugin cache.
- Do not paste full upstream defaults into user config to change one value.

## Docs

- https://www.lazyvim.org/configuration
- https://www.lazyvim.org/configuration/general
- https://www.lazyvim.org/configuration/lazy.nvim
