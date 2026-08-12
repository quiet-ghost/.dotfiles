---
name: domain-modeling
description: Build and sharpen a project's domain model, glossary, and architectural decisions. Use when terminology, boundaries, invariants, or durable design trade-offs need resolution.
---

# Domain Modeling

Actively sharpen domain language while designing: challenge terms, test edge cases, compare claims with code, and record resolved language immediately. Reading an existing context for vocabulary is routine; use this skill when changing the model.

## File structure

Most repositories use a root `CONTEXT.md` and `docs/adr/` directory. If `CONTEXT-MAP.md` exists, read it to locate context-specific `CONTEXT.md` and ADR directories.

Create files lazily. Create the relevant context file only when the first term is resolved, and create `docs/adr/` only when the first ADR is needed. Use [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md) and [ADR-FORMAT.md](./ADR-FORMAT.md).

## During the session

- Call out terms that conflict with the existing glossary; distinguish overloaded concepts such as Customer and User.
- Propose precise canonical terms for vague language and list rejected synonyms under `_Avoid_`.
- Stress-test relationships with concrete scenarios, especially edge cases and context boundaries.
- Check stated behavior against the code and surface contradictions immediately.
- Keep `CONTEXT.md` a glossary only: no implementation details, specs, scratch notes, or decisions.

## ADRs

Offer an ADR only when the decision is hard to reverse, surprising without context, and the result of a real trade-off. Record architecture, context integration, technology lock-in, ownership boundaries, deliberate deviations, hidden constraints, or non-obvious rejected alternatives.

Number ADRs sequentially by scanning the target `docs/adr/` directory. A short decision and reason is better than a filled template.
