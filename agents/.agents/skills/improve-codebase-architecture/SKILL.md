---
name: improve-codebase-architecture
description: Architecture scan workflow for refactor opportunities. Use when the user asks how to improve a codebase, find refactors, assess architecture, reduce complexity, improve boundaries, or identify high-leverage technical debt.
---

# Improve Codebase Architecture

Scan for standards-backed architecture improvement opportunities. Planning-only: do not edit code, run refactors, create ADRs, run tests, or run static checks unless the user asks after the scan.

## Principles

- Evidence beats vibes.
- Rank by architecture leverage: safer invariants, clearer boundaries, smaller caller burden, better seams, stronger locality, better verification.
- Do not estimate effort unless asked.
- Do not produce a full tech spec; prepare candidates the user can choose from.
- Do not add migration/backwards-compatibility concerns unless requested.

## Workflow

1. Establish scan scope from the user or repo structure. Ask one question only when scope remains unclear.
2. Load `coding-standards/SKILL.md`, `vocabulary.md`, and relevant topic refs.
3. Inspect code only: files, tests, modules, adapters, parsers, errors, entrypoints, and call paths.
4. Form candidates with concrete evidence and a refactor direction.
5. Rank globally by leverage and prune aesthetic-only ideas.
6. Suggest context or ADR updates only when durable and specific.
7. Ask which candidate to explore with `tech-spec`.

## Look For

- Domain invariants scattered across callers.
- Boundary data validated but not parsed, cast, or leaked inward.
- Storage rows, protocol DTOs, or runtime-hop payloads crossing into core logic.
- Expected failures hidden as throws/rejections or broad strings.
- Secrets or raw payloads reaching diagnostics.
- Pass-through modules, accidental interfaces, dependency bags, hidden globals.
- Repeated orchestration or duplicated policy across entrypoints.
- Missing cancellation, floating promises, retry-unsafe mutation, unclear workflow state.
- Tests reaching past interfaces or forcing bad seams.
- Type escape hatches, mutable exported contracts, broad shapes.
- Cloudflare binding leakage or Durable Object topology friction.
- Effect code bypassing Services/Layers, typed channels, Schema, or Effect-aware tests.

## Candidate Card

```md
### <Candidate title> - <Strong | Worth exploring | Speculative>

- **Standards areas:** <topics>
- **Files/modules:** `<path>`, `<path>`
- **Current friction:** <caller burden, risk, duplicated policy, poor seam, or test friction>
- **Evidence:** <concrete files, call path, leaked representation, invalid state path, or test contortion>
- **Refactor direction:** <architecture-level change, not full implementation>
- **Expected leverage:** <what callers, maintainers, tests, or runtime behavior gain>
- **Likely test strategy:** <public interface or real seam>
- **Context/ADR note:** <optional>
```

End with:

```md
Top recommendation: <candidate title> - <why highest leverage>

Which candidate would you like to explore with a tech-spec brief?
```
