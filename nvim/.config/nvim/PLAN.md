# Fix `<leader>jf` for tmux + herdr

## Context

`<leader>jf` (`lua/config/keymaps/lang.lua`) dispatches to language runners:

- `utils.javafx` / `utils.cpp` / `utils.python` / `utils.rust` / `utils.typescript`

Each runner:

1. Gates on `os.getenv("TMUX")` and errors with **"Not in tmux!"**
2. Opens output via `tmux split-window -h ...` with a shell that runs the command and waits on Enter

After migrating to herdr, Neovim runs with:

- `HERDR_ENV=1`
- `HERDR_PANE_ID=...`
- no `TMUX`

So every `<leader>jf` path fails before it can run. Goal: same run UX in **either** tmux or herdr, detected dynamically.

## Approach

Add a small shared multiplexer helper `lua/utils/mux.lua` and route all runners through it.

### Detection

Prefer herdr, then tmux (same pattern as plugin conds in `herdr-splits.lua` / `tmux-navigator.lua`):

```lua
if vim.env.HERDR_ENV == "1" then
  return "herdr"
elseif vim.env.TMUX and vim.env.TMUX ~= "" then
  return "tmux"
end
return nil
```

Error copy becomes: **"Not in tmux or herdr! Run from a multiplexer terminal instead."**

### Shared API

```lua
local mux = require("utils.mux")

mux.backend()            -- "herdr" | "tmux" | nil
mux.ensure()             -- notify + return false if neither
mux.run_in_split({
  command = "...",       -- shell command body (no trailing read)
  cwd = optional_path,
  title = optional_title,
  percent = 35,          -- new pane size as % of current pane
  direction = "right",   -- "right" | "down"
  focus = true,          -- match tmux split focus behavior
  wait_for_enter = true, -- append Press Enter / read
})
-- Low-level helpers for Jakarta dual-pane:
mux.current_pane_id()
mux.split({ direction, percent, cwd, focus, target_pane }) -> pane_id|nil
mux.run(pane_id, command)   -- herdr: pane run; tmux: send-keys / initial cmd
mux.focus_pane(pane_id)
```

### Backend mapping

| Concern | tmux | herdr |
|---|---|---|
| Detect | `$TMUX` | `$HERDR_ENV == "1"` |
| Split right | `tmux split-window -h -p <percent>` | `herdr pane split --current --direction right --ratio <percent/100> [--cwd] [--focus\|--no-focus]` |
| Split down | `tmux split-window -v -p <percent>` | `herdr pane split ... --direction down --ratio ...` |
| Run command as pane program | pass shell string to `split-window` | parse split JSON → `.result.pane.pane_id` → `herdr pane run <id> <cmd>` |
| Keep open | `; echo ''; echo 'Press Enter to close...'; read` | same suffix via `pane run` |
| Cwd | `cd` in shell and/or `-c` | `--cwd` on split + `cd` in command when needed |
| Focus restore (Jakarta) | `tmux select-pane -t <id>` | create both splits with `--no-focus` (keeps Neovim focused); optional best-effort focus if needed |

**Size normalization:** existing callers mix columns (`-l 40`) and percents (`-l 30%`). The shared API standardizes on **percent**. Call-site mapping:

- java/javafx: keep 20 / 30
- python comment already intends 40% → `percent = 40`
- ts/rust/cpp column sizes (~40–45) → `percent = 35` / `40` (close visual match)

**Herdr command notes:**

- CLI returns JSON on stdout (confirmed via `herdr pane current` / `layout`)
- Split response pane id: `.result.pane.pane_id` (per herdr docs)
- `herdr pane run <pane_id> <command>` submits command + Enter atomically
- After split, shell may need a brief moment before `pane run`; if flaky, short poll/`vim.wait` retry (no busy loop)

### Files to modify

- **New:** `lua/utils/mux.lua`
- `lua/utils/typescript.lua` — replace `run_in_tmux` + TMUX gate
- `lua/utils/rust.lua` — same
- `lua/utils/python.lua` — same
- `lua/utils/cpp.lua` — same
- `lua/utils/javafx.lua` — simple runner + `run_jakarta_tomcat_in_tmux` dual-pane path

No keymap change needed; `<leader>jf` already delegates correctly.

### Out of scope

- `lua/config/keymaps/navigation.lua` tmux-sessionizer (`<C-f>`)
- `lua/config/keymaps/commands.lua` tmux session switch
- Replacing `vim-tmux-navigator` (already gated off under herdr)

## Reuse

- Existing runner command construction stays as-is (maven/cargo/bun/python/cmake logic untouched)
- Detection pattern already used by:
  - `lua/plugins/herdr-splits.lua` → `vim.env.HERDR_ENV == "1"`
  - `lua/plugins/tmux-navigator.lua` → `vim.env.HERDR_ENV ~= "1"`
- Herdr env already present in this session: `HERDR_ENV`, `HERDR_PANE_ID`, `HERDR_SOCKET_PATH`
- Herdr layout width available via `herdr pane layout --current` if we ever need column→ratio conversion

## Steps

- [x] 1. Add `lua/utils/mux.lua` with `backend`, `ensure`, `run_in_split`, and low-level `split` / `run` / `current_pane_id`
- [x] 2. Implement tmux backend using percent splits (`-p`) + existing "Press Enter to close" shell wrapper
- [x] 3. Implement herdr backend: `pane split` → parse pane id → `pane run`; handle cwd/title/focus
- [x] 4. Wire `typescript.lua`, `rust.lua`, `python.lua`, `cpp.lua` to `mux.ensure` + `mux.run_in_split`
- [x] 5. Wire `javafx.lua` simple path the same way
- [x] 6. Rewrite Jakarta dual-pane helper on mux primitives (horizontal compile pane, vertical server pane off it, keep nvim focused)
- [x] 7. Smoke-test in herdr (current env) and sanity-check tmux code path still correct

## Verification

1. **Herdr (current):** open a TS/Python/Rust/Java/C++ file inside Neovim under herdr, press `<leader>jf`
   - Should open a right split (not error "Not in tmux")
   - Command runs, pane shows title + output
   - Enter closes / returns to shell as before
2. **Jakarta (if applicable):** WAR project still gets compile + server panes without stealing focus permanently from Neovim
3. **tmux:** under a tmux session (`TMUX` set, no `HERDR_ENV`), same `<leader>jf` still splits and runs
4. **Neither:** plain terminal Neovim still gets a clear error naming both multiplexers
5. Quick Lua check (optional): `:lua print(require("utils.mux").backend())` → `herdr` inside herdr

## Implementation sketch (`mux.run_in_split`)

```lua
function M.run_in_split(opts)
  local backend = M.backend()
  if not backend then
    vim.notify("Not in tmux or herdr! Run from a multiplexer terminal instead.", vim.log.levels.ERROR)
    return false
  end

  local body = opts.command
  if opts.title then
    body = string.format("echo %s && echo '' && %s", vim.fn.shellescape("--- " .. opts.title .. " ---"), body)
  end
  if opts.cwd then
    body = string.format("cd %s && %s", vim.fn.shellescape(opts.cwd), body)
  end
  if opts.wait_for_enter ~= false then
    body = body .. "; echo ''; echo 'Press Enter to close...'; read"
  end

  if backend == "tmux" then
    -- tmux split-window -h/-v -p percent body
  else
    -- herdr pane split --current --direction ... --ratio percent/100 [--cwd] [--focus]
    -- herdr pane run <new_pane_id> body
  end
  return true
end
```
