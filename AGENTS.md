# Repository Guide

## Repository Model

- This is an Arch/Omarchy dotfiles repo. Top-level directories are independent GNU Stow packages whose contents mirror paths under `$HOME`.
- There is no root workspace or repo-wide build, lint, test, or CI command. Verify only the component changed.
- Prefer `stow <package>` from the repo root. `stow */` links every top-level package, including non-obvious packages such as templates and skills. Unlink with `stow -D <package>`.

## Key Boundaries

- Hyprland starts at `hypr/.config/hypr/hyprland.conf`; it imports Omarchy defaults before local overrides and generated Omarchy toggle files.
- Neovim starts at `nvim/.config/nvim/init.lua`, then loads `lua/config/lazy.lua`; local LazyVim overrides belong under `lua/plugins/`.
- Herdr starts at `herdr/.config/herdr/config.toml`. Reload it with `herdr server reload-config`.
- Active OpenCode config is `opencode/.config/opencode/`, not root-level `opencode/opencode.jsonc`.
- `skills/` is canonical. `opencode/.config/opencode/skill` is a symlink to it; do not maintain two copies.
- User services live in `systemd/.config/systemd/user/`; several units call scripts outside this repo, so inspect each unit before changing assumptions about deployment.
- Utility entrypoints live in `bin/.local/bin/`. `templates/` is input to `repo-init`, not active configuration for this repo.

## Focused Checks

- Herdr attach proxy: `python3 herdr/.config/herdr/scripts/test_herdr_attach_proxy.py`
- Pi TypeScript extensions: run `npm run check` in `pi/.pi` (`npm ci` installs its locked dependencies).
- Career Ops commands run only in `opencode/.config/opencode/career-ops`; see its `package.json` scripts. They are not repo-wide checks.
- No active repository CI or pre-commit hooks exist. Workflows below `templates/` and vendored plugin trees validate generated or third-party projects, not this repo.

## Traps

- Do not inspect, expose, or commit ignored secret/session files such as `.env*`, `.dev.vars`, or `pi/.pi/agent/{auth,mcp-*,sessions}`.
- Ignore generated/runtime material (`node_modules/`, `.worktrees/`, caches, logs, session state) unless the task explicitly targets it.
- `opencode/.config/opencode/plugins/herdr-agent-state.js` is Herdr-managed and may be overwritten; put custom hooks beside it instead of editing it.
- Do not run dependency installation blindly under `opencode/`: its root manifest and lock are out of sync, while `.config/opencode/` has conflicting npm and Bun lock state. Reconcile the intended package manager and manifest first.
- `cloudflared/install.sh` is privileged, stateful deployment: it creates tunnels/routes, installs a system service, and writes a symlink. Do not treat it as an idempotent Stow package install.
