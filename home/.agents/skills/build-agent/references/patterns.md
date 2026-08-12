# Real-World Agent Patterns

Concrete agent archetypes with recommended defaults.

## Pattern 1: Read-Only Reviewer

**When to use:**
- Review code, docs, configs, or plans
- Primary task is finding issues, not editing

**Recommended defaults:**

```yaml
---
description: Reviews code changes for bugs, regressions, and maintainability risks. Use when asked to review diffs, pull requests, or suspicious implementations.
mode: subagent
temperature: 0.1
permission:
  edit: deny
  bash: ask
---
```

**Prompt shape:** direct, evidence-seeking, context-aware.

## Pattern 2: Professional Writer

**When to use:**
- Draft or revise prose
- Improve tone, clarity, structure, and audience fit

**Recommended defaults:**

```yaml
---
description: Writes polished, professional prose for documents, proposals, emails, and long-form content. Use when drafting, rewriting, or refining writing for tone, clarity, and audience fit.
mode: subagent
temperature: 0.3
permission:
  edit: allow
  bash: deny
---
```

**Prompt shape:** audience-first, concise, revision-minded, no fluff.

## Pattern 3: Docs Writer

**When to use:**
- README work
- Guides, API docs, onboarding docs
- Documentation maintenance

**Recommended defaults:**

```yaml
---
description: Writes and maintains technical documentation. Use when creating or revising README files, guides, onboarding docs, or API documentation.
mode: subagent
temperature: 0.2
permission:
  edit: allow
  bash: deny
  webfetch: allow
steps: 6
---
```

**Prompt shape:** clear structure, examples, accuracy over flourish.

## Pattern 4: Research / Explore Agent

**When to use:**
- Investigate codebases or docs
- Gather context before implementation
- Answer architecture questions

**Recommended defaults:**

```yaml
---
description: Explores code, docs, and related context to answer implementation questions. Use when researching behavior, architecture, or unfamiliar code paths.
mode: subagent
temperature: 0.1
permission:
  edit: deny
  bash: deny
  webfetch: allow
---
```

**Prompt shape:** read-first, grounded, no speculative edits.

## Pattern 5: Hidden Helper

**When to use:**
- Internal subtask with narrow scope
- Not intended for manual user selection

**Recommended defaults:**

```yaml
---
description: Performs a narrow internal transformation for parent agents. Use only for task delegation inside larger workflows.
mode: subagent
hidden: true
permission:
  edit: deny
  bash: deny
steps: 4
---
```

**Prompt shape:** narrow contract, deterministic output, no wandering.

## Pattern 6: Orchestrator

**When to use:**
- Break large work into subtasks
- Correlate outputs from specialist agents
- Keep direct edits secondary to coordination

**Recommended defaults:**

```yaml
---
description: Coordinates work across specialist agents. Use when a request spans planning, validation, analysis, and synthesis across multiple domains.
mode: subagent
permission:
  task:
    "*": deny
    "review-*": allow
    "docs-*": allow
steps: 8
---
```

**Prompt shape:** decompose, delegate, verify, synthesize.

## Pattern 7: Primary Specialist

**When to use:**
- User should switch into it directly for a whole session
- Persistent tone and workflow differ materially from build/plan

**Recommended defaults:**

```yaml
---
description: Serves as a direct writing-focused primary agent for polished business and technical prose. Use when the main session is centered on drafting or revising written material.
mode: primary
permission:
  edit: allow
  bash: deny
---
```

**Prompt shape:** broader workflow guidance, not just one-shot specialization.

## Pattern Selection

| Need | Pattern |
| ---- | ------- |
| Analyze without editing | Read-only reviewer |
| Improve prose | Professional writer |
| Write project docs | Docs writer |
| Research unfamiliar systems | Research / explore |
| Internal-only subtask | Hidden helper |
| Coordinate multiple specialists | Orchestrator |
| Main session persona | Primary specialist |

## See Also

- [permissions.md](./permissions.md) - Access presets
- [modes.md](./modes.md) - Invocation model
