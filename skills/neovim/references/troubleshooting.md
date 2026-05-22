# Neovim Troubleshooting

Start with exact symptoms and isolate whether failure is Neovim, user config, or plugin state.

## Startup Triage

1. Capture exact error text, command, Neovim version, and target config path.
2. Test clean Neovim if needed:

```bash
nvim --headless -u NONE "+qa"
nvim --headless --clean "+qa"
```

3. Test full config only after reading boot files:

```bash
nvim --headless "+qa"
```

If full startup mutates plugin state in that repo, avoid it unless the user asked.

## Health Checks

Use focused health when possible:

```vim
:checkhealth
:checkhealth provider
:checkhealth vim.lsp
```

In headless mode:

```bash
nvim --headless "+checkhealth" "+qa"
```

Health output can include warnings that are not task blockers. Tie findings to the reported failure.

## Provider Issues

Common provider checks:

- Python: `:checkhealth provider`, `vim.g.python3_host_prog`, `python -m pynvim`
- Node: `:checkhealth provider`, `node`, `npm`, `neovim` package
- Ruby: `:checkhealth provider`, `ruby`, `gem neovim`
- Clipboard: `:checkhealth provider`, `wl-copy`, `xclip`, `xsel`, `pbcopy`, SSH state

Prefer setting explicit provider paths only when detection is wrong or repo already pins them.

## LSP Issues

Collect state before editing server config:

```vim
:LspInfo
:lua vim.print(vim.lsp.get_clients({ bufnr = 0 }))
:lua vim.print(vim.lsp.get_log_path())
```

Check root detection, executable path, filetype, and server-specific settings. Avoid changing all servers to fix one server.

## Mapping Issues

Inspect existing maps before adding or overriding:

```vim
:verbose nmap <leader>x
:verbose imap <C-k>
:map <buffer>
```

Buffer-local plugin maps often win over global maps. Fix ownership instead of adding duplicate mappings.

## Autocmd Issues

Inspect groups and callbacks:

```vim
:autocmd
:autocmd my_group
```

Prefer a stable augroup name with `clear = true` to prevent duplicate autocmds after reload.

## Docs

- https://neovim.io/doc/
- https://neovim.io/doc/user/lua/
- https://neovim.io/doc/user/api/
- https://neovim.io/doc/user/diagnostic/
- https://neovim.io/doc/user/lsp/
