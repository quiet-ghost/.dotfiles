# DOTFILES

**Generated:** 2026-08-12
**Commit:** 6000c8a

Arch Linux + Omarchy via GNU Stow. Zsh + Neovim + Hyprland + Herdr + OpenCode + Pi.

## STRUCTURE

```
.dotfiles/
├── home/                       # ONLY Stow package — mirrors $HOME
│   ├── .zshrc / .zshenv        # Interactive shell + login env
│   ├── .aliases.zsh            # Aliases (sourced last from .zshrc)
│   ├── .gitconfig              # Git + delta
│   ├── .ssh/config             # SSH (keys gitignored)
│   ├── .stow-local-ignore      # Runtime/cache/secrets stay unstowed
│   ├── .agents/skills/         # Canonical skills → ~/.agents/skills/
│   ├── .local/bin/             # desktop-integrated scripts and wrappers
│   ├── .pi/                    # Pi TS workspace + extensions
│   └── .config/
│       ├── hypr/               # Hyprland Lua: Omarchy defaults then local overrides
│       ├── omarchy/            # shell.json, Quickshell plugins, rose-pine-dark
│       ├── nvim/               # LazyVim — overrides in lua/plugins/
│       ├── herdr/              # Terminal mux (config.toml + scripts)
│       ├── opencode/           # Active OpenCode config (not root manifests)
│       ├── tmux/               # Legacy mux + plugin submodules
│       ├── ghostty/            # Terminal
│       ├── systemd/user/       # User units (enablement is host-local)
│       ├── starship.toml       # Prompt
│       ├── atuin/              # Shell history
│       └── (mise is host-local, not stowed)
├── extras/                     # Source-only. NEVER Stow
│   ├── keyboard/               # Programmer QWERTY XKB source
│   └── cloudflared/            # Existing stream-dev tunnel installer
├── skills-lock.json            # Hashed skill pin
└── .gitmodules                 # herdr-splits, Omarchy themes/plugins, tmux plugins
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Deploy / unlink | `stow home` / `stow -D home` (validate: `stow --simulate home`) |
| Stow ignore | `home/.stow-local-ignore` |
| Shell alias | `home/.aliases.zsh` |
| Shell function / PATH / bindkey | `home/.zshrc` |
| Private env | `~/.env.private` (not in repo) |
| Prompt | `home/.config/starship.toml` |
| Git alias / identity | `home/.gitconfig` |
| Neovim plugin | `home/.config/nvim/lua/plugins/<name>.lua` |
| Neovim keymap | `home/.config/nvim/lua/config/keymaps/` |
| Neovim options / leader | `home/.config/nvim/lua/config/options.lua` |
| Hyprland start | `home/.config/hypr/hyprland.lua` |
| Hyprland binding | `home/.config/hypr/bindings.lua` |
| Monitors / keyboard | `home/.config/hypr/monitors.lua`, `input.lua` |
| Omarchy shell / bar | `home/.config/omarchy/shell.json` + `plugins/` |
| Omarchy theme source | `home/.config/omarchy/themes/` (live theme: `~/.local/state/omarchy/current`) |
| Herdr keys / UI | `home/.config/herdr/config.toml` |
| Herdr scripts / popups | `home/.config/herdr/scripts/` |
| OpenCode start | `home/.config/opencode/opencode.json` |
| OpenCode agent / command | `home/.config/opencode/agent/`, `command/` |
| OpenCode plugin | `home/.config/opencode/plugins/` (V2 only; helpers in `lib/`, CLI hooks in `plugins/tui/`) |
| OpenCode identity | `home/.config/opencode/AGENTS.md` |
| Skill | `home/.agents/skills/<name>/SKILL.md` |
| Pi settings / MCP | `home/.pi/agent/settings.json`, `mcp.json` |
| Pi extension | `home/.pi/agent/extensions/` |
| Desktop utility script | `home/.local/bin/` |
| Development workflows | `~/dev/tools/dev-tools/` |
| Worktree paths | `~/dev/tools/dev-tools/lib/wt-paths.sh` | `~/dev/worktrees/<bucket>/<repo>/<branch>` |
| New-repo bootstrap | `~/dev/tools/project-bootstrap/` |
| Keyboard layout source | `extras/keyboard/` (Hypr uses it via `input.lua`) |
| User service | `home/.config/systemd/user/` |
| Tmux (legacy) | `home/.config/tmux/tmux.conf` |

## CONVENTIONS

- One Stow package: `home/` mirrors `~`. Edit here, never `~/.config/*` directly.
- `extras/` is source-only. Never Stow it.
- Syncthing transports working files between trusted machines; `.git/` and other repository metadata stay local.
- `.stignore` is machine-local and includes the synchronized `.stignore-shared` rules.
- Clone/update recursively: `git submodule update --init --recursive`.
- No root build, lint, test, or CI. Verify only the component changed.
- Neovim: LazyVim. `init.lua` → `lua/config/lazy.lua`. One spec per file in `lua/plugins/`.
- Skills live in `home/.agents/skills/`. OpenCode and Pi discover that path natively.

## Key Boundaries

- Hyprland starts at `home/.config/hypr/hyprland.lua`; it bootstraps and loads package-owned Omarchy defaults before local Lua overrides and generated toggle modules.
- Neovim starts at `home/.config/nvim/init.lua`, then loads `lua/config/lazy.lua`; local LazyVim overrides belong under `lua/plugins/`.
- Herdr starts at `home/.config/herdr/config.toml`. Reload it with `herdr server reload-config`.
- Active OpenCode config is `home/.config/opencode/`, not root-level legacy manifests.
- Mise is host-local Omarchy state: `~/.config/mise/config.toml` plus `omarchy-mise-install` wrappers in `~/.local/bin`. Do not stow either.

## ANTI-PATTERNS

- Edit live `~/.config/*` (lost on restow; edit `home/` instead)
- Stow or hand-edit `~/.config/mise/` or Omarchy mise wrappers in `~/.local/bin`
- Stow `extras/`
- Inspect, expose, or commit secrets/sessions: `.env*`, `.dev.vars`, `home/.pi/agent/{auth,mcp-*,sessions}`, `calendar-ics.json`, `calendar-sync.json`, `home/.config/omarchy/linear/accounts.json`
- Commit generated/runtime: `node_modules/`, caches, logs, socks, `plugins.json`, Omarchy `current/`
- Reinstall Herdr's V1 OpenCode integration; V2 pane reporting lives in `home/.config/opencode/plugins/tui/herdr.ts`
- Blind `npm/bun install` under `home/.config/opencode/` (lock must match the intended package manager)
- Hand-edit `home/.config/herdr/plugins/config/herdr-splits/herdr-splits.conf` (generated by nvim setup)
- Treat vendored plugin trees as this repo's CI
- Commit, push, or open a PR unless explicitly asked

## COMMANDS

```bash
stow --simulate home                          # dry-run deploy
stow home                                     # deploy
stow -R home                                  # restow after pull
stow -D home                                  # unlink
omarchy-mise-install <pkg> [cmd [bin]]        # add a mise tool + live wrapper
omarchy update mise                           # Mise tools only; mup also refreshes OpenCode's beta tag and plugins
git submodule update --init --recursive       # themes, tmux, herdr-splits
herdr server reload-config                    # after herdr/config.toml
hyprctl reload && hyprctl configerrors        # after hypr changes
systemctl --user daemon-reload                # after unit edits
python3 home/.config/herdr/scripts/test_herdr_attach_proxy.py
(cd home/.pi && npm run check)                # Pi TS extensions
(cd home/.config/opencode && npm run check && npm test) # V2 plugins
```

Career Ops commands run only in `home/.config/opencode/career-ops` when that package exists.

## KEY CONFIGS

| Tool | Entry | Notes |
|------|-------|-------|
| Zsh | `.zshrc` | OMZ + mise/direnv/fzf/atuin; aliases last |
| Starship | `starship.toml` | Prompt; `ZSH_THEME=""` |
| Neovim | `init.lua` | 1 line → `config.lazy`; leader `<Space>` |
| Hyprland | `hyprland.lua` | Omarchy defaults → local Lua overlays → generated toggles |
| Herdr | `config.toml` | Prefix `ctrl+space`; reload via CLI |
| OpenCode | `opencode.json` | Default agent `plan` |
| Pi | `settings.json` | `PLANNOTATOR_PORT=19432` via `.zshenv` / `uwsm/default` |
| Git | `.gitconfig` | `pull.rebase`, delta rose-pine, worktrees via `wt`/`wd`/`wl` |
| Ghostty | `ghostty/config` | Tight padding so herdr fills the surface |
| Tmux | `tmux.conf` | Prefix `C-Space`; still bound from zsh |
| Mise | `~/.config/mise/config.toml` | Host-local. Wrappers from `omarchy-mise-install`; upgrades via `mup` |

## UNIQUE STYLES

- Theme: rose-pine across herdr, nvim (`rose-pine-moon`), ghostty, fzf, delta
- Keyboard: Programmer QWERTY (`kb_layout = programmer,us`)
- herdr prefix: `ctrl+space`
- herdr vim nav/resize: `ctrl+h/j/k/l`, `alt+h/j/k/l` via `herdr-splits` (Herdr plugin + nvim plugin)
- herdr popups: `alt+o` OpenCode 2, `alt+shift+o` Pi, `alt+g` lazygit, `alt+w` mux-sesh
- nvim: `jj`/`JJ` leave insert; arrows disabled; herdr-splits only when `HERDR_ENV=1`, else vim-tmux-navigator
- git default branch: `master`
- Browser: Helium (`BROWSER=helium-browser`)
- `cat` → bat, `ls` → eza, `v` → nvim, `oc` → opencode, `nr`/`ginit` → repo-init

## NOTES

- Herdr plugin registry (`~/.config/herdr/plugins.json`) is runtime and stow-ignored. If vim-pane nav dies, `herdr plugin list` is empty → reinstall `lmilojevicc/herdr-splits.nvim` then `herdr server reload-config`.
- Hypr sources Omarchy from `~/.local/share/omarchy/` and toggles from `~/.local/state/omarchy/toggles/`. Do not edit those defaults; override in `home/.config/hypr/`.
- Do not ship `~/.config/uwsm/env`. Quattro owns session env via `/usr/share/uwsm/env.d/10-omarchy`; user overrides stay in `uwsm/default` or `uwsm/env.d/`.
- Several user units call scripts outside this repo (`ghost-server` audio helpers, Omarchy bins). Inspect each unit before changing deploy assumptions.
- `extras/cloudflared/install.sh` validates the Stowed config, verifies the host-local `stream-dev` credentials, and enables its user service.
- Public diffs can still leak usernames, hosts, domains, ports, project names. Review before publish.
- Nested projects (`home/.pi/`, `home/.config/opencode/`) have their own locks. Component-local checks only.
- Tmux config remains for non-herdr sessions; zsh still binds `tmux-sessionizer`.
