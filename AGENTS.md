# Repository Guide

## Repository Model

- `home/` is the only GNU Stow package. Its contents mirror paths under `$HOME`.
- Validate with `stow --simulate home`, deploy with `stow home`, and unlink with `stow -D home`.
- `home/.stow-local-ignore` keeps runtime state, caches, dependencies, and generated Omarchy paths out of deployment.
- `extras/` is source-only. Never Stow it.
- Git submodules provide the Herdr plugin, Omarchy themes, and Tmux plugins. Clone recursively and update with `git submodule update --init --recursive`.
- There is no root build, lint, test, or CI command. Verify only the component changed.

## Key Boundaries

- Hyprland starts at `home/.config/hypr/hyprland.conf`; it imports Omarchy defaults before local overrides and generated Omarchy toggle files.
- Neovim starts at `home/.config/nvim/init.lua`, then loads `lua/config/lazy.lua`; local LazyVim overrides belong under `lua/plugins/`.
- Herdr starts at `home/.config/herdr/config.toml`. Reload it with `herdr server reload-config`.
- Active OpenCode config is `home/.config/opencode/`, not root-level legacy manifests.
- `home/.agents/skills/` is canonical and deploys to `~/.agents/skills/`. OpenCode and Pi discover it natively.
- User services live in `home/.config/systemd/user/`; several units call scripts outside this repo, so inspect each unit before changing deployment assumptions.
- Utility entrypoints live in `home/.local/bin/`.
- `extras/templates/` is input to `repo-init`, not active configuration.
- `extras/keyboard/` contains keyboard source and installation notes; `extras/cloudflared/` contains stateful deployment tooling.

## Focused Checks

- Herdr attach proxy: `python3 home/.config/herdr/scripts/test_herdr_attach_proxy.py`
- Pi TypeScript extensions: run `npm run check` in `home/.pi` (`npm ci` installs its locked dependencies).
- Career Ops commands run only in `home/.config/opencode/career-ops`; see its `package.json` scripts.
- Hyprland changes require `hyprctl reload` followed by `hyprctl configerrors`.
- User-service changes require `systemctl --user daemon-reload` and a focused unit status check.
- Stow/layout changes require `stow --simulate --restow home`.
- No active repository CI or pre-commit hooks exist. Workflows below `extras/templates/` and vendored plugin trees validate generated or third-party projects, not this repo.

## Traps

- Do not inspect, expose, or commit ignored secret/session files such as `.env*`, `.dev.vars`, or `home/.pi/agent/{auth,mcp-*,sessions}`.
- Ignore generated/runtime material (`node_modules/`, `.worktrees/`, caches, logs, session state) unless the task explicitly targets it.
- `home/.config/opencode/plugins/herdr-agent-state.js` is Herdr-managed and may be overwritten; put custom hooks beside it instead of editing it.
- Do not run dependency installation blindly under `home/.config/opencode/`; its lock state must match the intended package manager first.
- `extras/cloudflared/install.sh` is privileged and stateful: it creates tunnels/routes, installs a system service, and writes a symlink.
- Review public changes for usernames, hosts, domains, ports, project names, and other topology even when no credential is present.
- Do not commit, push, or create a pull request unless explicitly requested.
