# Agent Frontmatter Specification

Markdown agents use YAML frontmatter followed by the prompt body.

## Required Format

```yaml
---
description: What this agent does and when to use it.
mode: subagent
permission:
  edit: deny
---
```

**Critical:** Frontmatter must start at line 1. No blank lines before `---`.

## Required Field

### description

| Constraint           | Value           |
| -------------------- | --------------- |
| Required in practice | Yes             |
| Max length           | 1024 characters |
| Min recommended      | 50 characters   |

**Rules:**

- State WHAT the agent does
- State WHEN to use it
- Use task words other agents can match on
- Keep it concrete and narrow enough to avoid bad routing

**Good descriptions:**

```yaml
description: Writes polished, professional prose for documents, proposals, emails, and long-form content. Use when drafting, revising, or refining writing for clarity, tone, and audience fit.

description: Reviews code changes for bugs, regressions, and maintainability risks. Use when asked to review diffs, pull requests, or suspicious implementations.
```

**Bad descriptions:**

```yaml
description: Writer
description: Helps with code
description: I can review things
description: Useful agent
```

## Common Optional Fields

### mode

```yaml
mode: primary
# or
mode: subagent
# or
mode: all
```

Default is `all`, but do not rely on the default. Choose intentionally.

### permission

```yaml
permission:
  edit: allow
  bash: deny
  webfetch: ask
```

Prefer `permission:` for new agents. It is more explicit and current than `tools:`.

### hidden

```yaml
hidden: true
```

Hide a subagent from `@` autocomplete. This is not a security boundary.

### steps

```yaml
steps: 6
```

Caps agentic iterations before the model must respond with text only. Useful for cost and scope control.

### model

```yaml
model: openai/gpt-5.5
```

Set only when the role materially benefits from a specific model. Otherwise inherit defaults.

### temperature

```yaml
temperature: 0.2
```

Lower for review, auditing, or analysis. Higher only for brainstorming-heavy roles.

### color, top_p, disable

```yaml
color: accent
top_p: 0.9
disable: true
```

Use sparingly. Most custom agents do not need them.

## Deprecated Field

### tools

```yaml
tools:
  bash: false
  edit: false
```

`tools:` still works, but prefer `permission:` for all new agent definitions and revisions.

## Complete Example

```yaml
---
description: Drafts and edits technical documentation. Use when writing README files, guides, onboarding docs, or API documentation.
mode: subagent
model: openai/gpt-5.5
temperature: 0.2
permission:
  edit: allow
  bash: deny
  webfetch: allow
steps: 6
---
You are a technical writer.

Write documentation that is accurate, structured, easy to navigate, and useful to the intended reader. Prefer plain language, clear examples, and explicit assumptions.
```

## Validation Checklist

| Check                    | Requirement                        |
| ------------------------ | ---------------------------------- |
| Starts with `---`        | Line 1, no preceding blank lines   |
| Has `description:`       | Required in practice               |
| Description quality      | Includes what + when               |
| Has `mode:`              | Explicitly chosen                  |
| Uses `permission:`       | Preferred for new agents           |
| Uses `hidden:` correctly | Only meaningful for subagents      |
| Uses `steps:` correctly  | Optional, but realistic if present |
| Prompt body is focused   | Role, method, quality bar          |

## See Also

- [modes.md](./modes.md) - Mode selection
- [permissions.md](./permissions.md) - Permission patterns
- [gotchas.md](./gotchas.md) - Common mistakes
