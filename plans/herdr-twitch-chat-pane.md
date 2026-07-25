# Herdr persistent Twitch chat pane + stow herdr config

## Context

Migrating tmux muscle memory into herdr. Two related outcomes:

1. **Twitch chat toggle** matching tmux `Alt+Shift+C` (`tmux/.config/tmux/scripts/twitch-chat-pane.sh`)
2. **Herdr config in dotfiles** via a new `herdr/` stow package (today it only lives at `~/.config/herdr/config.toml`)

Tmux behavior to mimic exactly:

- Persistent chat process (`bun run dev` in `~/dev/projects/TwitchChat`)
- Parked in dedicated session `tui_chat` when hidden
- Joined into current window as **left** ~20% pane when shown
- Same bind reopens the **same** process after session/workspace switches

## Approach

### 1. Stow package for herdr (mirror tmux layout)

```
herdr/
  .config/
    herdr/
      config.toml              # current live config, plus new bind
      scripts/
        twitch-chat-pane.sh    # toggle script (tmux twin)
```

**Stow only user-managed files.** Leave herdr runtime state alone in `~/.config/herdr/`:

- Do **not** stow: `*.log`, `*.sock`, `session.json`, `session-history.json`, `plugins/`, `plugins.json`, `.plugins.lock`, `release-notes.json`

Migration (safe order):

1. Create package tree under `herdr/.config/herdr/`
2. Copy live `~/.config/herdr/config.toml` → repo file; add twitch keybind
3. Add `scripts/twitch-chat-pane.sh`
4. Back up live config: `cp ~/.config/herdr/config.toml ~/.config/herdr/config.toml.bak`
5. Remove live `config.toml` only (so stow can link)
6. `cd ~/.dotfiles && stow herdr`
7. Confirm `~/.config/herdr/config.toml` → symlink into the repo
8. `herdr server reload-config`

Also touch docs lightly:

- `README.md` — note herdr as multiplexer alongside/instead of only tmux
- Optional: `.gitignore` unchanged (runtime files already stay untracked outside the package)

### 2. Toggle script (tmux-faithful)

`herdr/.config/herdr/scripts/twitch-chat-pane.sh`

| tmux | herdr |
|------|-------|
| pane option `@twitchchat=1` | `herdr pane rename … twitchchat` → PaneInfo.`label` |
| session `tui_chat` | workspace label `tui_chat` |
| `join-pane` | `herdr pane move` (terminal process survives) |
| `join-pane -hb -l 20%` | move `--split right --ratio 0.2` then `pane swap --direction left` |
| bind `M-C` | `[[keys.command]]` key `alt+shift+c` type `shell` |

**Toggle algorithm**

1. Resolve active tab/pane from `HERDR_ACTIVE_TAB_ID` / `HERDR_ACTIVE_PANE_ID` (custom-command env); fallback `herdr api snapshot` focused ids.
2. Find chat: `herdr pane list` → first pane with `.label == "twitchchat"`. Always re-list after moves (cross-workspace move **changes pane id**; keep using returned `.result.move_result.pane.pane_id`).
3. **Missing** → create parking workspace:
   - `herdr workspace create --cwd "$DIR" --label tui_chat --no-focus`
   - rename root pane `twitchchat`
   - `herdr pane run <id> "exec bun run dev"`
4. **Chat on active tab** → **hide**:
   - Ensure parking workspace exists (create empty parking if needed)
   - `herdr pane move "$chat" --new-tab --workspace "$parking" --label chat --no-focus`
   - (If parking missing entirely: `--new-workspace --label tui_chat --tab-label chat`)
5. **Else** → **show** (left 20%, match tmux `-hb`):
   - If chat is sole pane in its tab, `herdr pane split` a placeholder in that tab first (`ensure_placeholder`)
   - Move onto active tab targeting focused pane:

```bash
herdr pane move "$chat" \
  --tab "$active_tab" \
  --target-pane "$active_pane" \
  --split right \
  --ratio 0.2 \
  --no-focus
# ratio = first-child share → original@20% left, chat@80% right
herdr pane swap --pane "$new_chat_id" --direction left
# swap keeps geometry → chat@20% left, original@80% right
herdr pane rename "$new_chat_id" twitchchat
```

6. If move no-ops (zoomed tab / same tab), print a short message via stderr (herdr shell commands are detached — best-effort; prefer `herdr notification` if trivial, else no-op quietly like tmux display-message).

**Why not `type = "pane"`?** That opens a temp overlay killed on exit. Chat must be a normal pane relocated with `pane move`.

**Keybind** (in stowed config.toml, near other tool overlays):

```toml
[[keys.command]]
key = "alt+shift+c"
type = "shell"
command = "$HOME/.config/herdr/scripts/twitch-chat-pane.sh"
description = "toggle twitch chat pane"
```

Use `$HOME/...` path (same style as tmux bind) so it works whether or not `bin` is involved. Prefer `HERDR_BIN_PATH` inside the script when invoking herdr.

## Files to modify

| Path | Action |
|------|--------|
| `herdr/.config/herdr/config.toml` | **New** — migrate from live config + twitch bind |
| `herdr/.config/herdr/scripts/twitch-chat-pane.sh` | **New** — toggle script |
| `~/.config/herdr/config.toml` | Replace with stow symlink (backup first) |
| `README.md` | Mention herdr package / multiplexer |
| `tmux/.config/tmux/scripts/twitch-chat-pane.sh` | **Reference only** (no change required) |

## Reuse

- Logic twin: `tmux/.config/tmux/scripts/twitch-chat-pane.sh`
- Stow layout twin: `tmux/.config/tmux/{tmux.conf,scripts/}`
- Live keybind patterns already in herdr config (`type = "shell"` / `type = "pane"`)
- CLI: `herdr pane list|rename|run|split|move|swap|close`, `herdr workspace list|create`, `herdr api snapshot`
- Custom command env: `HERDR_ACTIVE_*`, `HERDR_BIN_PATH`, `HERDR_SOCKET_PATH`
- Herdr SKILL rule: parse JSON ids; after move use new pane id; `--no-focus` for background layout ops

## Steps

- [ ] Create `herdr/.config/herdr/` stow tree
- [ ] Copy current `~/.config/herdr/config.toml` into the package (preserve all existing binds/theme/ui)
- [ ] Add `scripts/twitch-chat-pane.sh` (tmux-equivalent toggle, left 20%)
- [ ] Add `alt+shift+c` shell keybind pointing at the stowed script path
- [ ] Backup live config → remove file → `stow herdr` → verify symlink
- [ ] `herdr server reload-config`
- [ ] `bash -n` / `shellcheck` the script
- [ ] Update `README.md` components list for herdr
- [ ] Manual toggle verification (below)

## Verification

1. `readlink -f ~/.config/herdr/config.toml` points inside `~/.dotfiles/herdr/`
2. Runtime files (`session.json`, logs, plugins) still present and untouched beside the symlink
3. In herdr, `Alt+Shift+C`:
   - Shows chat as **left ~20%** pane; focus stays on prior pane
   - Second press hides it; `bun`/chat process still alive in parking `tui_chat`
   - Switch workspace, press again → **same** process returns (stable `terminal_id` or pid)
4. Kill chat process, press bind → recreates via `exec bun run dev`
5. Zoomed tab: toggle should not corrupt layout (no-op / message)

## Notes / constraints

- Split API is only `right`/`down`; left 20% **requires** move@ratio `0.2` + swap left (ratio clamped 0.1–0.9)
- `pane run` goes through the shell → use `exec bun run dev`
- Script must not `herdr server stop` or close unrelated workspaces/tabs
- Parking workspace may flash in the sidebar (acceptable; matches dedicated tmux session tradeoff)
