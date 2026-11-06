---
name: build-skill
description: Create effective skills for OpenCode agents. Load FIRST before writing any SKILL.md. Provides required format, naming conventions, progressive disclosure patterns, and validation. Use when building, reviewing, or debugging skills.
---

# Building Skills

Skills extend agent capabilities with specialized knowledge, workflows, and tools.

Use the current [OpenCode V2 skills guide](https://opencode.ai/v2/docs/skills) for runtime behavior and the [Agent Skills specification](https://agentskills.io/specification) for portable format rules. Read both before changing discovery, IDs, frontmatter, or invocation guidance.

## Quick Start

Minimal viable skill in 30 seconds:

```bash
mkdir my-skill && cat > my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: Does X when Y happens. Use for Z tasks.
---

# My Skill

Instructions go here.
EOF
```

Place in `.agents/skills/` (project) or `~/.agents/skills/` (global).

In this dotfiles repo, edit `home/.agents/skills/`; Stow supplies the shared global directory for OpenCode and Pi. Use `.opencode/skills/` for an OpenCode-only project skill.

## Skill Type Decision Tree

```
What are you building?
├─ Instructions only → Simple skill (SKILL.md only)
│   Example: code-review guidelines, commit message format
│
├─ Domain knowledge → Reference-heavy skill (+ references/)
│   Example: API docs, database schemas, company policies
│
├─ Repeatable automation → Script-heavy skill (+ scripts/)
│   Example: PDF processing, data validation, file conversion
│
├─ Complex multi-step workflow → Multi-file skill (all directories)
│   Example: release process, deployment pipeline
│
└─ Large platform → Progressive skill
    Example: AWS, GCP, Cloudflare (60+ products)
```

## When to Create a Skill

Create a skill when:

- Same instructions repeated across conversations
- Domain knowledge model lacks (schemas, internal APIs, company policies)
- Workflow requires 3+ steps with specific order
- Code rewritten repeatedly for same task
- Team needs shared procedural knowledge

## When NOT to Create a Skill

| Scenario                   | Do Instead                          |
| -------------------------- | ----------------------------------- |
| Single-use instructions    | AGENTS.md or inline in conversation |
| Model already knows domain | Don't add redundant context         |
| < 3 steps, no reuse        | Inline instructions                 |
| Highly variable workflow   | Higher-freedom guidelines           |
| Just want to store files   | Use regular directories             |

## Reading Order

| Task                    | Files to Read               |
| ----------------------- | --------------------------- |
| New skill from scratch  | anatomy.md → frontmatter.md |
| Optimize existing skill | progressive-disclosure.md   |
| Add scripts/resources   | bundled-resources.md        |
| Find skill pattern      | patterns.md                 |
| Debug/fix skill         | gotchas.md                  |

## In This Reference

| File                                                                | Purpose                        |
| ------------------------------------------------------------------- | ------------------------------ |
| [anatomy.md](./references/anatomy.md)                               | Skill directory structures     |
| [frontmatter.md](./references/frontmatter.md)                       | YAML spec, naming, validation  |
| [progressive-disclosure.md](./references/progressive-disclosure.md) | Token-efficient design         |
| [bundled-resources.md](./references/bundled-resources.md)           | scripts/, references/, assets/ |
| [patterns.md](./references/patterns.md)                             | Real-world skill patterns      |
| [gotchas.md](./references/gotchas.md)                               | Common mistakes + fixes        |

## Scripts

| Script                      | Purpose                  |
| --------------------------- | ------------------------ |
| `scripts/init_skill.sh`     | Scaffold new skill       |
| `scripts/validate_skill.sh` | Validate skill structure |
| `scripts/package_skill.sh`  | Create distributable zip |

## Pre-Flight Checklist

Before using a skill:

- [ ] SKILL.md starts with `---` (line 1, no blank lines)
- [ ] `name:` field present, matches directory name
- [ ] `description:` includes what + when to use
- [ ] Closing `---` after frontmatter
- [ ] SKILL.md stays focused (target roughly 200 lines; this is not a runtime limit)
- [ ] All internal links resolve
- [ ] Skill calls use the exact path-derived ID: `skill({ id: 'my-skill' })`
- [ ] Required reference reads are stated in the body, not assumed from frontmatter

Run: `./scripts/validate_skill.sh ./my-skill`

This validator checks local portable conventions, not the complete V2 runtime contract. Its current line-based description check misreads YAML block scalars such as `>`; inspect those warnings against a YAML-aware loader rather than rewriting valid descriptions.

## Skill Locations

OpenCode V2 registers sources from lower to higher precedence:

1. Built-in skills.
2. `.claude/skills`, global then project ancestors.
3. `.agents/skills`, global then project ancestors.
4. `~/.config/opencode/skills`.
5. Project `.opencode/skills`, from the project root toward the current directory.
6. Explicit `skills` config entries, in config priority and array order.

Project discovery walks from the working directory to the project root. Later sources replace earlier definitions with the same ID. Avoid duplicates unless an override is intentional; this is OpenCode precedence, not a promise about other harnesses.

V2 derives IDs from paths: `teams/release/SKILL.md` has ID `release`. Frontmatter `name` is a display label. Keep directory, ID, and `name` aligned in lowercase kebab-case for portable skills.

Explicit sources use an ordered `skills` array in `opencode.json(c)`. Relative source paths resolve from the active working directory, not the config file. Custom storage paths such as `~/dev/skills` require an explicit source or a symlink into a discovered directory.

OpenCode reloads skill edits automatically; `/reload` forces a reload. In Pi, use `/reload` after edits. Keep the shared directory rather than copying the same skill into both harnesses.

## See Also

- [OpenCode V2 Skills](https://opencode.ai/v2/docs/skills) - Discovery, loading, and permissions
- [Agent Skills Specification](https://agentskills.io/specification) - Portable format
