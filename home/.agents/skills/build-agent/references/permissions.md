# Agent Permissions

Use permissions to control what an agent can do.

## Permission Levels

| Value | Meaning |
| ----- | ------- |
| `allow` | Run without approval |
| `ask` | Prompt before running |
| `deny` | Do not allow |

Prefer the smallest set of permissions that still lets the agent do its job.

## Common Permission Actions

| Action | Typical Use |
| --- | ----------- |
| `edit` | File creation and modification |
| `shell` | Terminal commands |
| `webfetch` | Reading docs and URLs |
| `subagent` | Invoking child agents |
| `skill` | Loading skills |
| `read`, `glob`, `grep` | File reads and searches |

`external_directory` controls access outside the active location and worktree. V2 allows it by default; add an explicit `ask` or `deny` rule when needed. Do not assume a child inherits its parent's restrictions: a custom subagent uses its own permissions.

## Preferred Format

```yaml
permissions:
  - action: edit
    resource: "*"
    effect: deny
  - action: shell
    resource: "*"
    effect: ask
  - action: shell
    resource: "git status *"
    effect: allow
  - action: shell
    resource: "git diff *"
    effect: allow
  - action: webfetch
    resource: "*"
    effect: allow
```

Each rule requires `action`, `resource`, and `effect`. V2 starts with a permissive base policy and appends global and agent rules; an agent's array does not replace earlier rules. See the [current permission defaults](https://opencode.ai/v2/docs/permissions#defaults).

## Shell Pattern Rules

Actions and resources use whole-value `*` and `?` wildcards. A shell resource ending in ` *` also matches the command without arguments.

```yaml
permissions:
  - action: shell
    resource: "*"
    effect: ask
  - action: shell
    resource: "git status *"
    effect: allow
  - action: shell
    resource: "git diff *"
    effect: allow
```

**Important:** last matching rule wins.

## Subagent Permissions

Use the `subagent` action with the exact agent ID or an intentional wildcard.

```yaml
permissions:
  - action: subagent
    resource: "*"
    effect: deny
  - action: subagent
    resource: "docs-*"
    effect: allow
  - action: subagent
    resource: "code-reviewer"
    effect: ask
```

This controls which agents the parent can launch through the `subagent` tool, not which tools the child may use.

## Recommended Profiles

### Reviewer

```yaml
permissions:
  - action: edit
    resource: "*"
    effect: deny
  - action: shell
    resource: "*"
    effect: ask
  - action: shell
    resource: "git status *"
    effect: allow
  - action: shell
    resource: "git diff *"
    effect: allow
  - action: webfetch
    resource: "*"
    effect: allow
```

### Docs Writer

```yaml
permissions:
  - action: edit
    resource: "*"
    effect: allow
  - action: shell
    resource: "*"
    effect: deny
  - action: webfetch
    resource: "*"
    effect: allow
```

### Cautious Debugger

```yaml
permissions:
  - action: edit
    resource: "*"
    effect: ask
  - action: shell
    resource: "*"
    effect: ask
  - action: shell
    resource: "npm test *"
    effect: allow
  - action: shell
    resource: "bun test *"
    effect: allow
  - action: shell
    resource: "git status *"
    effect: allow
  - action: webfetch
    resource: "*"
    effect: deny
```

### Orchestrator

```yaml
permissions:
  - action: edit
    resource: "*"
    effect: deny
  - action: shell
    resource: "*"
    effect: deny
  - action: subagent
    resource: "*"
    effect: deny
  - action: subagent
    resource: "review-*"
    effect: allow
  - action: subagent
    resource: "docs-*"
    effect: allow
```

## Design Rules

- Start with deny/ask, then open only what is necessary
- Avoid broadly allowing `shell` unless the role truly requires it
- Keep write access off for reviewer/researcher roles
- Use `subagent` only when delegation is central to the agent's purpose
- Denying `edit` does not prevent shell commands from writing files. Deny shell access too when strict read-only behavior is required; approved test scripts also run with the host user's authority.

## See Also

- [modes.md](./modes.md) - Invocation model
- [gotchas.md](./gotchas.md) - Permission mistakes
