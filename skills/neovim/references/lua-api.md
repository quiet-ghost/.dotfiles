# Neovim Lua API

Prefer Neovim's Lua APIs for new config unless the repo intentionally uses Vimscript.

## Runtime Basics

- Neovim embeds Lua 5.1; avoid Lua 5.2+ syntax in shared config.
- Modules under `lua/foo/bar.lua` load with `require("foo.bar")` via `runtimepath`.
- `require()` caches modules after first load.
- Use `vim.print(value)` or `vim.inspect(value)` while debugging.

## Options And Variables

Use `vim.opt` for option values that are lists, maps, or flags.

```lua
vim.opt.number = true
vim.opt.listchars = { tab = "> ", trail = "-" }
vim.opt.wildignore:append({ "node_modules", "dist" })
```

Use scoped variants when scope matters:

```lua
vim.opt_local.wrap = true
vim.opt_global.clipboard = "unnamedplus"
vim.g.mapleader = " "
vim.b.my_flag = true
```

## Keymaps

Prefer `vim.keymap.set`.

```lua
vim.keymap.set("n", "<leader>x", function()
  vim.diagnostic.open_float()
end, { desc = "Line diagnostics" })
```

Use `buffer = bufnr` for buffer-local mappings. Add `silent = true` only when command output is not useful. Add `expr = true` only when the mapping returns keys.

## Autocmds

Create named augroups and callbacks.

```lua
local group = vim.api.nvim_create_augroup("my_feature", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.highlight.on_yank()
  end,
})
```

For buffer events, prefer `event.buf` over current-buffer assumptions.

## User Commands

Prefer `vim.api.nvim_create_user_command`.

```lua
vim.api.nvim_create_user_command("Format", function(args)
  vim.lsp.buf.format({ async = args.bang })
end, { bang = true, desc = "Format current buffer" })
```

## Async And Fast Events

Most `vim.api` calls are unsafe inside fast event callbacks like `vim.uv` callbacks. Schedule editor work back onto the main loop.

```lua
timer:start(1000, 0, vim.schedule_wrap(function()
  vim.api.nvim_command("checktime")
end))
```

Close libuv handles when done to avoid leaks.

## API Indexing

Most Neovim API ranges are 0-based and end-exclusive.

Exceptions include cursor and mark APIs using 1-based rows and 0-based columns:

- `nvim_win_get_cursor()`
- `nvim_win_set_cursor()`
- `nvim_buf_get_mark()`
- `nvim_buf_set_mark()`

Extmarks use 0-based positions with their own gravity rules. Check `:help api-indexing` before changing buffer-position logic.

## Diagnostics And LSP

- Use `vim.diagnostic.config()` for diagnostic display behavior.
- Use `vim.lsp.config`/`vim.lsp.enable` when the repo already uses modern core LSP config.
- Use existing `nvim-lspconfig` patterns when the repo owns server setup there.
- Keep server-specific settings in language/server modules when present.
