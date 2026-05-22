# Agent Modes

Mode determines how the agent is surfaced and invoked.

## primary

Use `primary` when the user should switch into the agent directly as the main session persona.

**Good fit:**
- Writing-focused main workflow
- Dedicated debugging session
- Ongoing specialist mode the user will stay in

## subagent

Use `subagent` when the agent is a specialist helper invoked by `@mention` or the Task tool.

**Good fit:**
- Reviewer
- Writer
- Researcher
- Security auditor
- Internal helper

This is the safest default for most custom agents.

## all

Use `all` only when the same agent genuinely works well both as a primary agent and a subagent.

**Avoid when:**
- The role is mainly internal
- The role is mainly user-facing
- The prompt assumes one specific invocation style

If unsure, do not use `all`.

## hidden

```yaml
mode: subagent
hidden: true
```

Hide a subagent from `@` autocomplete. Useful for internal helpers.

**Important:**
- Only meaningful for subagents
- Not a security boundary
- Does not stop programmatic task use when permissions allow it

## steps and Bounded Work

```yaml
steps: 6
```

Use `steps` when:

- The agent should stay bounded
- Orchestrator cost needs control
- You want a forced summary after a limited number of actions

Do not set `steps` so low that the agent cannot complete normal work.

## Decision Guide

| Need | Mode |
| ---- | ---- |
| User should switch into it directly | `primary` |
| Specialist helper for one kind of work | `subagent` |
| Useful in both roles | `all` |
| Internal-only helper | `subagent` + `hidden: true` |

## Heuristics

- Default to `subagent`
- Use `primary` only when the user will actively choose it
- Use `all` rarely
- Pair `hidden` only with narrow internal helpers

## See Also

- [permissions.md](./permissions.md) - Access design
- [patterns.md](./patterns.md) - Example agent types
- [gotchas.md](./gotchas.md) - Mode mistakes
