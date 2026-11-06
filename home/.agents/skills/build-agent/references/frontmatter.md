# Agent Frontmatter Specification

Markdown agents use YAML frontmatter followed by the prompt body.

Use the [V2 agents guide](https://opencode.ai/v2/docs/agents) as the runtime contract. The Markdown body supplies the agent's `system` prompt; project instructions and skills are still added separately.

## Required Format

```yaml
---
description: What this agent does and when to use it.
mode: subagent
permissions:
  - action: edit
    resource: "*"
    effect: deny
---
```

**Critical:** Frontmatter must start at line 1. No blank lines before `---`.

## Required Field

### description

| Constraint           | Value           |
| -------------------- | --------------- |
| Required in practice | Yes             |
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

The runtime default for a new custom agent is `primary`. Choose explicitly; `subagent` is usually appropriate for specialist helpers.

### permissions

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
    effect: ask
```

Each rule has `action`, `resource`, and `effect`. Rules are ordered; the last match wins. Use `shell` for commands and `subagent` for child-agent launch permissions.

### hidden

```yaml
hidden: true
```

Hide an agent from normal listings, interactive discovery, and the model's subagent catalog. Keep helpers visible when the parent must discover them automatically. This is not a security boundary.

### steps

```yaml
steps: 6
```

Positive maximum number of model steps. The final step is text-only; new user input resets the allowance. Useful for cost and scope control.

### model

```yaml
model: provider/model#variant
```

Replace this placeholder with a verified configured model ID; `#variant` is optional. Set only when the role needs a specific model. Otherwise a subagent inherits its parent's model. Selecting a primary agent alone does not change the session's stored model.

### color and disabled

```yaml
color: "#ff6b6b"
disabled: true
```

Use a six-digit hex color. `disabled: true` removes the agent at that point in configuration loading.

### request

```yaml
request:
  headers:
    x-agent: documentation
```

V2 currently preserves per-agent request headers/body overlays but does not send them to model requests. Configure active sampling or provider options on the provider, model, or model variant instead. Do not add inert request options to tune an agent.

## Legacy Compatibility

Legacy agent frontmatter remains supported, but new V2 files use `permissions`, `disabled`, and `provider/model#variant`. Do not use legacy `permission`, `tools`, `temperature`, `top_p`, `disable`, `maxSteps`, or separate `variant` fields in new definitions.

Convert each file's frontmatter as a whole. Fields such as `permissions`, `request`, `system`, or `disabled` select V2 parsing, so mixing legacy fields into that file causes them to be ignored with warnings. Read the [migration guide](https://opencode.ai/v2/docs/migrate-v1#agent-files) before converting existing definitions.

## Complete Example

```yaml
---
description: Drafts and edits technical documentation. Use when writing README files, guides, onboarding docs, or API documentation.
mode: subagent
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
| Uses `permissions:`      | Ordered V2 rules                   |
| Uses `hidden:` correctly | Catalog visibility is intentional  |
| Uses `steps:` correctly  | Optional, but realistic if present |
| Prompt body is focused   | Role, method, quality bar          |

## See Also

- [modes.md](./modes.md) - Mode selection
- [permissions.md](./permissions.md) - Permission patterns
- [gotchas.md](./gotchas.md) - Common mistakes
