# Common Agent Mistakes

Issues, causes, and fixes for agent creation.

## Description Errors

| Error | Bad | Good |
| ----- | --- | ---- |
| Too vague | `Writer` | `Writes polished professional prose for documents and emails.` |
| No trigger | `Reviews code` | `Reviews code changes when asked to inspect diffs or pull requests.` |
| Wrong POV | `I help with docs` | `Writes and maintains technical documentation.` |
| Too broad | `Helps with engineering` | Narrow to the actual role |

## Mode Errors

| Mistake | Fix |
| ------- | --- |
| Defaulting everything to `all` | Pick `primary` or `subagent` intentionally |
| Making a helper `primary` | Use `subagent` |
| Using `hidden: true` on a primary agent | Remove `hidden` or switch to subagent |

## Permission Errors

| Mistake | Fix |
| ------- | --- |
| Granting broad bash access by default | Start with `deny` or `ask` |
| Using legacy `tools:` in new files | Prefer `permission:` |
| Forgetting `permission.task` for orchestrators | Add explicit task rules |
| Assuming first match wins | Last matching rule wins |

## Steps Errors

| Mistake | Fix |
| ------- | --- |
| `steps: 1` for non-trivial work | Raise to a realistic cap |
| No step cap on an expensive orchestrator | Add `steps` |
| Tiny cap causing premature summaries | Increase `steps` or narrow scope |

## Placement / Naming Errors

| Mistake | Fix |
| ------- | --- |
| Putting files outside `agent/` | Use `.opencode/agent/` or `~/.config/opencode/agent/` |
| Unstable names like `writer-final-v3` | Use stable names like `professional-writer` |
| Overgeneric names like `helper` | Use descriptive role names |

## Prompt Errors

| Mistake | Fix |
| ------- | --- |
| Prompt only describes tone | Add task boundaries and quality bar |
| Prompt is a huge handbook | Move reusable knowledge to a skill |
| Prompt mixes multiple roles | Split into separate agents |

## Quick Reference

| Symptom | Likely Fix |
| ------- | ---------- |
| Agent triggers for wrong work | Tighten `description` |
| Agent is too risky | Reduce permissions |
| Agent is missing from `@` menu | Check `mode` and `hidden` |
| Agent stops too early | Increase `steps` |
| Agent feels bloated | Move guidance to a skill |

## See Also

- [frontmatter.md](./frontmatter.md) - Field syntax
- [permissions.md](./permissions.md) - Access design
- [modes.md](./modes.md) - Invocation model
