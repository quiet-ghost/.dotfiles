# Agent Anatomy

Agent file structures from minimal to specialized.

## Directory Patterns

### Minimal Subagent

```
.opencode/
└── agent/
    └── professional-writer.md
```

**When to use:**
- Single focused role
- Prompt fits in one file
- No extra references needed

**Example:** Writer, reviewer, debugger, docs editor.

### Read-Only Specialist

```
.opencode/
└── agent/
    └── code-reviewer.md
```

**When to use:**
- Analysis without modification
- Review, research, auditing
- Should not edit files directly

**Typical frontmatter:**

```yaml
---
description: Reviews code for bugs and maintainability. Use when analyzing diffs or pull requests.
mode: subagent
permission:
  edit: deny
  bash: ask
---
```

### Hidden Helper

```
.opencode/
└── agent/
    └── internal-helper.md
```

**When to use:**
- Internal helper used via Task
- Not meant to appear in `@` autocomplete
- Narrow purpose inside a larger workflow

**Typical frontmatter:**

```yaml
---
description: Performs a narrow internal transformation. Use only for internal task delegation.
mode: subagent
hidden: true
permission:
  edit: deny
---
```

### Primary Specialist

```
.opencode/
└── agent/
    └── writing-studio.md
```

**When to use:**
- User should switch into it directly
- Main session persona is materially different from build/plan
- Role needs a persistent operating style

**Typical frontmatter:**

```yaml
---
description: Handles direct writing sessions for polished business and technical prose. Use when the main task is drafting or revising written material.
mode: primary
permission:
  edit: allow
  bash: deny
---
```

### Orchestrator / Delegator

```
.opencode/
└── agent/
    └── release-orchestrator.md
```

**When to use:**
- Work spans multiple specialist agents
- Main value is decomposition, sequencing, and correlation
- Direct file edits are secondary to task routing

**Typical frontmatter:**

```yaml
---
description: Coordinates release work across specialist agents. Use when planning, validating, and documenting a release spans multiple domains.
mode: subagent
permission:
  task:
    "*": deny
    "release-*": allow
steps: 8
---
```

## Placement

| Scope | Path |
| ----- | ---- |
| Project | `.opencode/agent/<name>.md` |
| Global | `~/.config/opencode/agent/<name>.md` |
| Legacy/supported | `.opencode/agents/<name>.md` |

Prefer `agent/` for consistency with the OpenCode CLI.

## File Naming

| Rule | Good | Bad |
| ---- | ---- | --- |
| Lowercase + hyphens | `professional-writer.md` | `ProfessionalWriter.md` |
| Descriptive | `security-auditor.md` | `helper.md` |
| Stable identifier | `docs-writer.md` | `writer-v2-final.md` |

The filename becomes the default agent name. Choose names that will still make sense months later.

## File Size Guidelines

| File Type | Target | Max |
| --------- | ------ | --- |
| Agent file | 40-120 lines | 200 lines |
| Prompt body | 20-80 lines | 150 lines |

Large domain knowledge belongs in a skill, not in the agent file.

## Example Layout

```
.opencode/
└── agent/
    ├── code-reviewer.md
    ├── docs-writer.md
    ├── internal-helper.md
    └── release-orchestrator.md
```

## See Also

- [frontmatter.md](./frontmatter.md) - Field-by-field guide
- [modes.md](./modes.md) - How agents are surfaced
- [permissions.md](./permissions.md) - Access design
