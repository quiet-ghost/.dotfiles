# Agent Permissions

Use permissions to control what an agent can do.

## Permission Levels

| Value | Meaning |
| ----- | ------- |
| `allow` | Run without approval |
| `ask` | Prompt before running |
| `deny` | Do not allow |

Prefer the smallest set of permissions that still lets the agent do its job.

## Common Permission Keys

| Key | Typical Use |
| --- | ----------- |
| `edit` | File creation and modification |
| `bash` | Terminal commands |
| `webfetch` | Reading docs and URLs |
| `task` | Invoking subagents |
| `skill` | Loading skills |
| `read` | File reads if explicitly configured |

You may also encounter environment-level safeguards such as `external_directory` or loop controls. Do not broaden them casually.

## Preferred Format

```yaml
permission:
  edit: deny
  bash:
    "*": ask
    "git status*": allow
    "git diff*": allow
  webfetch: allow
```

Prefer `permission:` over legacy `tools:`.

## Bash Pattern Rules

Permission rules for `bash` use glob matching.

```yaml
permission:
  bash:
    "*": ask
    "git status*": allow
    "git diff*": allow
```

**Important:** last matching rule wins.

## Task Permissions

Use `permission.task` for orchestrators or delegators.

```yaml
permission:
  task:
    "*": deny
    "docs-*": allow
    "code-reviewer": ask
```

This controls which subagents the agent can invoke via the Task tool.

## Recommended Profiles

### Reviewer

```yaml
permission:
  edit: deny
  bash:
    "*": ask
    "git status*": allow
    "git diff*": allow
  webfetch: allow
```

### Docs Writer

```yaml
permission:
  edit: allow
  bash: deny
  webfetch: allow
```

### Cautious Debugger

```yaml
permission:
  edit: ask
  bash:
    "*": ask
    "npm test*": allow
    "bun test*": allow
    "git status*": allow
  webfetch: deny
```

### Orchestrator

```yaml
permission:
  edit: deny
  bash: deny
  task:
    "*": deny
    "review-*": allow
    "docs-*": allow
```

## Design Rules

- Start with deny/ask, then open only what is necessary
- Avoid broad `bash: allow` unless the role truly requires it
- Keep write access off for reviewer/researcher roles
- Use `task` only when delegation is central to the agent's purpose

## See Also

- [modes.md](./modes.md) - Invocation model
- [gotchas.md](./gotchas.md) - Permission mistakes
