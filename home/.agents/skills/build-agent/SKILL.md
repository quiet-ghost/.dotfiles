---
name: build-agent
description: Create effective OpenCode agents for specific tasks. Load FIRST before writing any custom agent definition. Provides agent structure, frontmatter guidance, permission patterns, mode selection, and validation. Use when building, reviewing, or debugging agents.
---

# Building Agents

Agents give OpenCode specialized prompts, permissions, and operating modes for repeatable work.

Author for OpenCode V2. Read the current [agents guide](https://opencode.ai/v2/docs/agents) and [permissions guide](https://opencode.ai/v2/docs/permissions) before changing definitions. For conversions, also read the [migration guide](https://opencode.ai/v2/docs/migrate-v1#agent-files); preserve behavior and unrelated settings.

## Quick Start

Minimal viable agent in 30 seconds:

```bash
mkdir -p .opencode/agents && cat > .opencode/agents/professional-writer.md << 'EOF'
---
description: Writes polished, professional prose for documents, proposals, emails, and long-form content. Use when drafting, rewriting, or refining writing for tone, clarity, and audience fit.
mode: subagent
permissions:
  - action: edit
    resource: "*"
    effect: allow
  - action: shell
    resource: "*"
    effect: deny
---

You are a professional writer.

Write with a clear sense of audience, purpose, structure, and tone. Improve clarity and precision without adding fluff.
EOF
```

Place new agents in `.opencode/agents/` (project) or `~/.config/opencode/agents/` (global). Existing singular directories remain supported; moving existing files is optional.

## Agent Type Decision Tree

```
What are you building?
├─ Reusable persona with custom prompt/permissions → Agent
│  Example: professional writer, debugger, reviewer
│
├─ Large reusable knowledge/workflow → Skill
│  Example: Cloudflare guidance, release process, internal API docs
│
├─ One-shot entrypoint that loads instructions → Command
│  Example: /build-agent, /code-review
│
└─ Deterministic executable capability → Tool/script
   Example: formatter, validator, file converter

If Agent:
├─ User should switch into it directly → primary
├─ Specialist helper launched through the subagent tool → subagent
├─ Truly useful in both roles → all
└─ Helper intentionally omitted from listings and the model catalog → subagent + hidden
```

## When to Create an Agent

Create an agent when:

- Same specialized role is needed across conversations
- A task needs a distinct prompt/persona, not just extra knowledge
- The work needs a different permission profile than build/plan
- A primary agent needs a reusable specialist subagent
- The agent should be discoverable by description in the subagent catalog

## When NOT to Create an Agent

| Scenario | Do Instead |
| -------- | ---------- |
| One-off prompt | Inline instructions in conversation |
| Mostly domain knowledge | Skill with references/ |
| Deterministic automation | Script or custom tool |
| Tiny variation on existing agent | Reuse existing agent + tighter prompt |
| Large procedural handbook | Skill, not giant agent prompt |

## Reading Order

| Task | Files to Read |
| ---- | ------------- |
| New agent from scratch | anatomy.md → frontmatter.md |
| Choose mode | modes.md |
| Choose permissions | permissions.md |
| Find agent pattern | patterns.md |
| Keep prompts lean | progressive-disclosure.md |
| Debug/fix agent | gotchas.md |

## In This Reference

| File | Purpose |
| ---- | ------- |
| [anatomy.md](./references/anatomy.md) | Agent file structures and placement |
| [frontmatter.md](./references/frontmatter.md) | Markdown agent fields and validation |
| [progressive-disclosure.md](./references/progressive-disclosure.md) | Keep prompts small and focused |
| [permissions.md](./references/permissions.md) | Permission design and presets |
| [modes.md](./references/modes.md) | `primary` vs `subagent` vs `all` |
| [patterns.md](./references/patterns.md) | Real-world agent archetypes |
| [gotchas.md](./references/gotchas.md) | Common mistakes and fixes |

## Pre-Flight Checklist

Before using an agent:

- [ ] New file is in `agents/` and uses a stable lowercase-hyphen name
- [ ] `description:` states what the agent does and when to use it
- [ ] `mode:` is intentional, not just left at default
- [ ] `permissions:` uses ordered `action`/`resource`/`effect` rules
- [ ] Legacy fields are not mixed into native V2 frontmatter
- [ ] `hidden: true` is intentional; hidden agents are omitted from the model catalog
- [ ] `steps:` is set when bounded work or cost control matters
- [ ] Prompt defines role, scope, and quality bar without bloating context

## Agent Locations

| Scope | Preferred location |
| ----- | ------------------ |
| Project | `.opencode/agents/<name>.md` |
| Global | `~/.config/opencode/agents/<name>.md` |

Paths determine agent IDs: `agents/team/reviewer.md` becomes `team/reviewer`. V2 also reads legacy `agent/`, `mode/`, and `modes/` directories. A new custom agent defaults to `primary`; choose `mode` explicitly.

Config and definition changes reload automatically. Use `/reload` to force a reload; do not restart the service just to apply edits.

## See Also

- [OpenCode V2 Agents](https://opencode.ai/v2/docs/agents) - User-facing reference
