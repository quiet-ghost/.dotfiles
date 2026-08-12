---
name: tech-spec
description: Typed call-stack architecture handoff workflow. Use when writing implementation-ready specs, ADR/RFC details, architecture handoffs, or code-shaped plans with interfaces, seams, data flow, and tests.
---

# Tech Spec

A tech spec is a typed call-stack architecture handoff: code-shaped contracts plus execution flows. Prefer TypeScript pseudocode over prose wherever precision matters.

Design-only unless the user asks to implement.

## Branch Selection

- Use **Path A: Convert context to spec** when conversation, docs, and codebase contain enough background.
- Use **Path B: Clarify first** when problem, constraints, affected code, design direction, or acceptance criteria are missing.

If a question can be answered by exploring code, inspect code instead of asking.

## Path A: Convert Context To Spec

1. Load `coding-standards/SKILL.md`, relevant topic refs, and `tdd/SKILL.md`.
2. Inspect local code for vocabulary, modules, adapters, parsers, error style, observability, and tests.
3. Extract current state, problem, users/callers, goals, non-goals, constraints, invariants, affected systems, risks, and open questions.
4. Compare materially different alternatives before recommending one.
5. Specify domain types, inputs/outputs, function signatures, interfaces, typed failures, adapters, DTOs, persistence projections, and runtime codecs.
6. Show entrypoint-to-side-effect call stacks and type/data flow.
7. Map each contract and call-stack step to files/modules.
8. Write a vertical red-green-refactor test plan.

## Path B: Clarify First

Ask only questions that materially change the design. Use the `question` tool when multiple-choice options help. Once enough context exists, switch to Path A.

## Required Outline

Use this shape unless the task is small enough to compress without losing contracts or call stacks:

```md
# <Title>

## Summary
## Context / Current State
## Goals
## Non-Goals
## Invariants
## Design Constraints
## Alternatives Considered
## Recommendation
## Proposed Design
## Domain Model and Types
## Types, Interfaces, and APIs
## Seams, Boundaries, Adapters, and Implementations
## Call Stacks and Data Flow
## Files to Add / Change / Delete
## RGR TDD Test Plan
## Risks and Open Questions
```

## Writing Rules

- Code first: types and call stacks define what changes; prose explains why.
- Unknowns stay open questions.
- Every new or changed boundary gets a concrete type/interface/API sketch or an explicit reason none is needed.
- Every affected behavior gets a data-flow trace from raw input to parsed value to service/domain to side effect to response.
- Do not invent product requirements, domain rules, APIs, migrations, or compatibility plans.
- Do not save a file unless the user requested a file or an existing planning workflow requires it.
