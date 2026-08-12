# Progressive Disclosure

Token-efficient agent design through staged guidance.

## Three-Tier Loading Model

```
Tier 1: Metadata (~100 tokens)
├── name + description
├── Loaded at agent startup for all skills
└── Used to decide: "Is build-agent relevant?"

Tier 2: SKILL.md (<2000 tokens)
├── Agent-vs-skill decision
├── Quick start
├── Navigation to deeper references
└── Loaded when build-agent is triggered

Tier 3: References (on-demand)
├── anatomy.md
├── frontmatter.md
├── permissions.md
├── modes.md
├── patterns.md
└── gotchas.md
```

## Why This Matters

Agent prompts should stay small and role-specific.

- Put agent architecture guidance in this skill
- Put domain knowledge in separate skills
- Put only the agent's role, scope, and quality bar in the agent file

If an agent prompt tries to be both persona and handbook, it becomes noisy and brittle.

## When to Split

Keep guidance in one file when:

- The choice is simple
- A single example is enough
- No deep tradeoff exists

Split into references when:

- Mode choice changes behavior materially
- Permissions need examples
- Multiple agent patterns are plausible
- The same mistakes recur

## Reading Order By Task

| Task | Read |
| ---- | ---- |
| Create first agent | anatomy.md → frontmatter.md |
| Choose access model | permissions.md |
| Choose interaction model | modes.md |
| Start from a template | patterns.md |
| Debug behavior | gotchas.md |

## Navigation Pattern

Top-level skill should answer:

- Is this actually an agent?
- What mode should it use?
- Which reference should be loaded next?

Detailed references should answer:

- Exact field syntax
- Permission examples
- Archetype templates
- Known mistakes

## Anti-Patterns

| Pattern | Problem | Fix |
| ------- | ------- | --- |
| Giant agent prompt | Context rot | Move reusable guidance to a skill |
| Vague description | Bad routing | Add what + when |
| Defaulting everything to `all` | Confusing UX | Pick mode intentionally |
| Copying legacy `tools:` | Drift | Prefer `permission:` |
| Loading every reference | Waste | Read only the relevant file |

## See Also

- [anatomy.md](./anatomy.md) - File structure
- [patterns.md](./patterns.md) - Archetype templates
- [gotchas.md](./gotchas.md) - Failure modes
