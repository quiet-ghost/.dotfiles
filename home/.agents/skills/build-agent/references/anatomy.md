# Agent Anatomy

Agent file structures from minimal to specialized.

## Directory Patterns

### Minimal Subagent

```
.opencode/
└── agents/
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
└── agents/
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
permissions:
  - action: edit
    resource: "*"
    effect: deny
  - action: shell
    resource: "*"
    effect: ask
---
```

### Hidden Helper

```
.opencode/
└── agents/
    └── internal-helper.md
```

**When to use:**
- Helper intentionally omitted from normal listings and the model's subagent catalog
- Not meant for automatic specialist selection
- Narrow purpose inside a larger workflow

**Typical frontmatter:**

```yaml
---
description: Performs a narrow internal transformation. Use only for internal task delegation.
mode: subagent
hidden: true
permissions:
  - action: edit
    resource: "*"
    effect: deny
---
```

### Primary Specialist

```
.opencode/
└── agents/
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
permissions:
  - action: edit
    resource: "*"
    effect: allow
  - action: shell
    resource: "*"
    effect: deny
---
```

### Orchestrator / Delegator

```
.opencode/
└── agents/
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
permissions:
  - action: subagent
    resource: "*"
    effect: deny
  - action: subagent
    resource: "release-*"
    effect: allow
steps: 8
---
```

## Placement

| Scope | Path |
| ----- | ---- |
| Project | `.opencode/agents/<name>.md` |
| Global | `~/.config/opencode/agents/<name>.md` |

Prefer `agents/` for new V2 files. Existing `agent/`, `mode/`, and `modes/` directories remain supported. When moving a legacy mode into `agents/`, preserve its primary behavior with `mode: primary`.

## File Naming

| Rule | Good | Bad |
| ---- | ---- | --- |
| Lowercase + hyphens | `professional-writer.md` | `ProfessionalWriter.md` |
| Descriptive | `security-auditor.md` | `helper.md` |
| Stable identifier | `docs-writer.md` | `writer-v2-final.md` |

The relative path determines the agent ID: `agents/team/reviewer.md` becomes `team/reviewer`. Choose names that will still make sense months later.

## File Size Guidelines

| File Type | Target | Max |
| --------- | ------ | --- |
| Agent file | 40-120 lines | 200 lines |
| Prompt body | 20-80 lines | 150 lines |

Large domain knowledge belongs in a skill, not in the agent file.

## Example Layout

```
.opencode/
└── agents/
    ├── code-reviewer.md
    ├── docs-writer.md
    ├── internal-helper.md
    └── release-orchestrator.md
```

## See Also

- [frontmatter.md](./frontmatter.md) - Field-by-field guide
- [modes.md](./modes.md) - How agents are surfaced
- [permissions.md](./permissions.md) - Access design
