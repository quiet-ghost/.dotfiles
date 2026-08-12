---
name: herdr
description: Control Herdr terminal workspaces, tabs, panes, agents, and commands. Use when the user explicitly mentions Herdr or asks to inspect or control a Herdr session; requires HERDR_ENV=1.
---

# Herdr

Before any control command, verify the current process is inside a Herdr-managed pane:

```bash
test "${HERDR_ENV:-}" = 1
```

If it fails, say you are not inside Herdr and stop. Never inspect or control a focused session from outside Herdr.

## Discover syntax

The installed binary is authoritative. Run `herdr --help`, then the relevant group without a mutating subcommand: `herdr agent`, `pane`, `workspace`, `tab`, `worktree`, `terminal`, `notification`, `integration`, or `session`. Do not run bare `herdr`; it launches or attaches the TUI.

## Inspect and target

Use JSON responses and parse returned opaque IDs; never predict them. Prefer `--current` or an explicit pane/agent ID over UI focus, and preserve the caller's working directory.

```bash
herdr workspace list
herdr tab list --workspace "$HERDR_WORKSPACE_ID"
herdr pane current --current
herdr pane list --workspace "$HERDR_WORKSPACE_ID"
herdr agent list
```

Workspaces, tabs, and panes organize terminals. Pane commands control shells, tests, servers, input, and output; agent commands additionally validate identity and lifecycle state.

## Start work

Default to a sibling pane in the current tab and cwd. Use `--no-focus` for background work and inspect layout before repeated splits:

```bash
herdr pane layout --pane "$HERDR_PANE_ID"
herdr pane split --current --direction right --cwd "$PWD" --no-focus
herdr agent start reviewer --kind codex --pane <returned-pane-id>
herdr agent prompt reviewer "Inspect the current change and report actionable findings." --wait --timeout 120000
```

Use agent commands for recognized agents and pane commands for ordinary processes. Read lifecycle state before sending input; `unknown` does not prove completion.

## Run and read commands

```bash
herdr pane run <pane-id> "just test"
herdr pane wait-output <pane-id> --match "test result" --timeout 120000
herdr pane read <pane-id> --source recent-unwrapped --lines 120
```

Use `visible` for the viewport, `recent` for rendered output, `recent-unwrapped` for logs, and `detection` for agent detection. If alternate-screen output is unavailable, ask the agent to write its response to a temporary Markdown file and read that file.

## Safety

Do not close resources you did not create. Never stop the server or main Herdr process unless explicitly requested. Use named experimental sessions for isolated servers.
