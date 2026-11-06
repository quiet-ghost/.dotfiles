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
| Granting broad shell access by default | Start with `deny` or `ask` |
| Using legacy fields in new files | Use ordered `permissions:` rules |
| Forgetting delegation rules for orchestrators | Add `subagent` action rules |
| Assuming first match wins | Last matching rule wins |
| Denying `edit` but permitting shell writes | Restrict shell too when strict read-only access is required |
| Mixing V1 and V2 fields | Convert the whole frontmatter; legacy fields in a V2 file are ignored with warnings |

## Steps Errors

| Mistake | Fix |
| ------- | --- |
| `steps: 1` for non-trivial work | Raise to a realistic cap |
| No step cap on an expensive orchestrator | Add `steps` |
| Tiny cap causing premature summaries | Increase `steps` or narrow scope |

## Placement / Naming Errors

| Mistake | Fix |
| ------- | --- |
| Teaching singular directories for new V2 files | Prefer `.opencode/agents/` or `~/.config/opencode/agents/`; legacy locations remain supported |
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
| Parent cannot discover a helper | Remove `hidden: true` if catalog discovery is needed |
| Agent's sampling setting does nothing | Configure the provider/model variant; agent request overlays are currently not sent |
| Agent stops too early | Increase `steps` |
| Agent feels bloated | Move guidance to a skill |

## See Also

- [frontmatter.md](./frontmatter.md) - Field syntax
- [permissions.md](./permissions.md) - Access design
- [modes.md](./modes.md) - Invocation model
