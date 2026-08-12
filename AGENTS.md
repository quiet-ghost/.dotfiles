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
│   ├── .local/bin/             # util scripts (wt/wd, repo-init, hypr-*)
│   ├── .local/lib/             # shared helpers (wt-paths.sh)
│   ├── .pi/                    # Pi TS workspace + extensions
│   └── .config/
│       ├── hypr/               # Hyprland: Omarchy defaults then local overrides
│       ├── omarchy/            # Themes (8 submodules + local rose-pine-dark)
│       ├── nvim/               # LazyVim — overrides in lua/plugins/
│       ├── herdr/              # Terminal mux (config.toml + scripts)
│       ├── opencode/           # Active OpenCode config (not root manifests)
│       ├── tmux/               # Legacy mux + plugin submodules
│       ├── waybar/             # Bar
│       ├── ghostty/            # Terminal
│       ├── walker/             # Launcher
│       ├── systemd/user/       # User units (enablement is host-local)
│       ├── starship.toml       # Prompt
│       ├── atuin/              # Shell history
│       └── mise/               # Runtime versions
├── extras/                     # Source-only. NEVER Stow
│   ├── keyboard/               # Programmer QWERTY XKB source
│   ├── templates/repo/         # repo-init inputs, not live config
│   └── cloudflared/            # Privileged tunnel installer
├── skills-lock.json            # Hashed skill pin
└── .gitmodules                 # herdr-splits, Omarchy themes, tmux plugins
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
| Hyprland start | `home/.config/hypr/hyprland.conf` |
| Hyprland binding | `home/.config/hypr/bindings.conf` |
| Monitors / keyboard | `home/.config/hypr/monitors.conf`, `input.conf` |
| Omarchy theme source | `home/.config/omarchy/themes/` (`current/` is generated, unstowed) |
| Waybar | `home/.config/waybar/config.jsonc` + `style.css` |
| Herdr keys / UI | `home/.config/herdr/config.toml` |
| Herdr scripts / popups | `home/.config/herdr/scripts/` |
| OpenCode start | `home/.config/opencode/opencode.json` |
| OpenCode agent / command | `home/.config/opencode/agent/`, `command/` |
| OpenCode plugin | `home/.config/opencode/plugins/` |
| OpenCode identity | `home/.config/opencode/AGENTS.md` |
| Skill | `home/.agents/skills/<name>/SKILL.md` |
| Pi settings / MCP | `home/.pi/agent/settings.json`, `mcp.json` |
| Pi extension | `home/.pi/agent/extensions/` |
| Utility script | `home/.local/bin/` |
| Worktree paths | `home/.local/lib/wt-paths.sh` | `~/dev/worktrees/<bucket>/<repo>/<branch>` |
| New-repo bootstrap | `home/.local/bin/repo-init` ← `extras/templates/repo/` |
| Keyboard layout source | `extras/keyboard/` (Hypr uses it via `input.conf`) |
| User service | `home/.config/systemd/user/` |
| Tmux (legacy) | `home/.config/tmux/tmux.conf` |

## CONVENTIONS

- One Stow package: `home/` mirrors `~`. Edit here, never `~/.config/*` directly.
- `extras/` is source-only. Never Stow it.
- Clone/update recursively: `git submodule update --init --recursive`.
- No root build, lint, test, or CI. Verify only the component changed.
- Neovim: LazyVim. `init.lua` → `lua/config/lazy.lua`. One spec per file in `lua/plugins/`.
- Skills live in `home/.agents/skills/`. OpenCode and Pi discover that path natively.
- Active OpenCode config is `home/.config/opencode/`, not root-level legacy manifests.
- `extras/templates/` is input to `repo-init`, not live configuration.

## ANTI-PATTERNS

- Edit live `~/.config/*` (lost on restow; edit `home/` instead)
- Stow `extras/`
- Inspect, expose, or commit secrets/sessions: `.env*`, `.dev.vars`, `home/.pi/agent/{auth,mcp-*,sessions}`
- Commit generated/runtime: `node_modules/`, caches, logs, socks, `plugins.json`, Omarchy `current/`
- Edit `home/.config/opencode/plugins/herdr-agent-state.js` (Herdr-managed; put hooks beside it)
- Blind `npm/bun install` under `home/.config/opencode/` (lock must match the intended package manager)
- Hand-edit `home/.config/herdr/plugins/config/herdr-splits/herdr-splits.conf` (generated by nvim setup)
- Treat `extras/templates/` workflows or vendored plugin trees as this repo's CI
- Commit, push, or open a PR unless explicitly asked

## COMMANDS

```bash
stow --simulate home                          # dry-run deploy
stow home                                     # deploy
stow -R home                                  # restow after pull
stow -D home                                  # unlink
git submodule update --init --recursive       # themes, tmux, herdr-splits
herdr server reload-config                    # after herdr/config.toml
hyprctl reload && hyprctl configerrors        # after hypr changes
systemctl --user daemon-reload                # after unit edits
python3 home/.config/herdr/scripts/test_herdr_attach_proxy.py
(cd home/.pi && npm run check)                # Pi TS extensions
```

Career Ops commands run only in `home/.config/opencode/career-ops` when that package exists.

## KEY CONFIGS

| Tool | Entry | Notes |
|------|-------|-------|
| Zsh | `.zshrc` | OMZ + mise/direnv/fzf/atuin; aliases last |
| Starship | `starship.toml` | Prompt; `ZSH_THEME=""` |
| Neovim | `init.lua` | 1 line → `config.lazy`; leader `<Space>` |
| Hyprland | `hyprland.conf` | Omarchy defaults → local overrides → generated toggles |
| Herdr | `config.toml` | Prefix `ctrl+space`; reload via CLI |
| OpenCode | `opencode.json` | Default agent `plan` |
| Pi | `settings.json` | Wrapper: `home/.local/bin/pi` |
| Git | `.gitconfig` | `pull.rebase`, delta rose-pine, worktrees via `wt`/`wd`/`wl` |
| Ghostty | `ghostty/config` | Tight padding so herdr fills the surface |
| Tmux | `tmux.conf` | Prefix `C-Space`; still bound from zsh |

## UNIQUE STYLES

- Theme: rose-pine across herdr, nvim (`rose-pine-moon`), ghostty, fzf, delta
- Keyboard: Programmer QWERTY (`kb_layout = programmer,us`)
- herdr prefix: `ctrl+space`
- herdr vim nav/resize: `ctrl+h/j/k/l`, `alt+h/j/k/l` via `herdr-splits` (Herdr plugin + nvim plugin)
- herdr popups: `alt+o` OpenCode, `alt+shift+o` Pi, `alt+g` lazygit, `alt+w` mux-sesh
- nvim: `jj`/`JJ` leave insert; arrows disabled; herdr-splits only when `HERDR_ENV=1`, else vim-tmux-navigator
- git default branch: `master`
- Browser: Helium (`BROWSER=helium-browser`)
- `cat` → bat, `ls` → eza, `v` → nvim, `oc` → opencode, `nr`/`ginit` → repo-init

## NOTES

- Herdr plugin registry (`~/.config/herdr/plugins.json`) is runtime and stow-ignored. If vim-pane nav dies, `herdr plugin list` is empty → reinstall `lmilojevicc/herdr-splits.nvim` then `herdr server reload-config`.
- Hypr sources Omarchy from `~/.local/share/omarchy/` and toggles from `~/.local/state/omarchy/toggles/`. Do not edit those defaults; override in `home/.config/hypr/`.
- Several user units call scripts outside this repo (`ghost-server` audio helpers, Omarchy bins). Inspect each unit before changing deploy assumptions.
- `extras/cloudflared/install.sh` is privileged and stateful: tunnel, routes, system service, symlink.
- Public diffs can still leak usernames, hosts, domains, ports, project names. Review before publish.
- Nested projects (`home/.pi/`, `home/.config/opencode/`) have their own locks. Component-local checks only.
- Tmux config remains for non-herdr sessions; zsh still binds `tmux-sessionizer`.
