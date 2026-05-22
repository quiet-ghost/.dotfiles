# LazyVim Plugin Specs

LazyVim plugin customization uses lazy.nvim plugin specs in `lua/plugins/*.lua`.

## Add Plugins

Add a spec under `lua/plugins/*.lua`:

```lua
return {
  {
    "simrat39/symbols-outline.nvim",
    cmd = "SymbolsOutline",
    keys = {
      { "<leader>cs", "<cmd>SymbolsOutline<cr>", desc = "Symbols Outline" },
    },
    opts = {
      position = "right",
    },
  },
}
```

Use one file per feature/plugin or follow existing repo grouping.

## Disable Plugins

Disable an included plugin with `enabled = false`:

```lua
return {
  { "folke/trouble.nvim", enabled = false },
}
```

Do not remove upstream specs from LazyVim. Override from user config.

## Merge Rules

LazyVim follows lazy.nvim spec merge rules:

| Property | Behavior |
|----------|----------|
| `cmd` | Extends defaults |
| `event` | Extends defaults |
| `ft` | Extends defaults |
| `keys` | Extends defaults |
| `opts` | Merges with default opts |
| `dependencies` | Extends defaults |
| Other properties | Override defaults |

For `ft`, `event`, `keys`, `cmd`, and `opts`, use a function when you need to inspect or mutate defaults.

## Customize Options

Use table merge for simple changes:

```lua
return {
  {
    "folke/trouble.nvim",
    opts = {
      use_diagnostic_signs = true,
    },
  },
}
```

Use function form for list mutation:

```lua
return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },
    opts = function(_, opts)
      table.insert(opts.sources, { name = "emoji" })
    end,
  },
}
```

## Keymaps

Add or override plugin keymaps in the plugin spec:

```lua
return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
    },
  },
}
```

Disable a default keymap by setting it to `false`:

```lua
return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      { "<leader>/", false },
    },
  },
}
```

When disabling a non-normal-mode keymap, specify the exact same mode:

```lua
return {
  {
    "folke/flash.nvim",
    keys = {
      { "s", mode = { "n", "x", "o" }, false },
    },
  },
}
```

Return `{}` from `keys = function()` only when disabling all plugin keymaps is intended.

## Version Policy

LazyVim recommends leaving `version = false` for many plugins because outdated releases can break installs. Do not change version policy unless the task asks for pinning or update behavior.

## Docs

- https://www.lazyvim.org/configuration/plugins
- https://www.lazyvim.org/configuration/lazy.nvim
- https://github.com/folke/lazy.nvim
