---
name: coding-standards
description: TypeScript coding standards and design taste. Use when working on TypeScript code, domain models, modules, adapters, parsers, typed errors, async workflows, tests, Cloudflare Workers, or Effect code.
---

# Coding Standards

Use these standards while designing, editing, reviewing, or planning TypeScript work. They encode the default taste: correctness first, precise domain modeling, typed failures, explicit boundaries, real seams, strict TypeScript, and boring operational safety.

This skill is a routing layer. Load the topic files that match the code being touched.

## Core Tenets

- Correctness, safety, debuggability, boundary integrity, and test integrity beat convenience.
- Local conventions matter when compatible with these standards.
- Parse boundary input before it reaches core logic; pass refined/domain values inward.
- Model invariants in types, constructors, parsers, and transitions.
- Model expected failures in typed return channels; reserve throws for defects or framework boundaries.
- Design deep modules with intentional seams, small interfaces, and explicit dependencies.
- Verify observable behavior through public interfaces or real seams.
- Keep TypeScript contracts strict, local, documented, and boring.
- Improve changed paths without forcing broad migrations unless explicitly requested.
- Do not add backwards-compatibility, rollout, migration, backfill, or dual-write paths unless requested.

## Non-Negotiables

- Untrusted, serialized, persisted, or framework-shaped input is parsed before service/domain logic sees it.
- Decoded JSON, storage rows, and protocol payloads are not trusted with `as SomeType`.
- Expected failures are visible in typed return channels, not hidden throws or rejected promises.
- Secrets do not enter errors, logs, traces, metrics, snapshots, or panic summaries.
- Raw platform bindings and framework types stay at composition seams or local adapter modules.
- Dependencies are explicit; hidden globals and ambient time/randomness/IDs do not drive service behavior.
- Tests prove observable behavior through module interfaces or real seams; avoid module mocks and spies.
- Type escape hatches are local, justified with `SAFETY:`, and hidden behind precise interfaces.
- Promises are owned: awaited, returned, collected, or handed to explicit detached-work machinery.

## Reading Order

| Task | Files to Read |
|------|---------------|
| Shared vocabulary | [vocabulary.md](./references/vocabulary.md) |
| Domain values, invariants, states | [domain-modeling.md](./references/domain-modeling.md) |
| HTTP/RPC/storage/env parsing | [boundaries-and-parsing.md](./references/boundaries-and-parsing.md) |
| Expected failures and classification | [error-handling.md](./references/error-handling.md) |
| Modules, adapters, seams, dependencies | [designing-modules.md](./references/designing-modules.md) |
| Async, retries, cancellation | [async-and-workflows.md](./references/async-and-workflows.md) |
| Logs, traces, redaction | [observability.md](./references/observability.md) |
| Tests and verification | [testing-and-verification.md](./references/testing-and-verification.md) |
| TypeScript contracts | [typescript-contracts.md](./references/typescript-contracts.md) |
| Cloudflare runtime architecture | [cloudflare-architecture.md](./references/cloudflare-architecture.md) |
| Effect systems | [effect.md](./references/effect.md) |
| Persistence | [persistence.md](./references/persistence.md) |
| Transactions, retries, idempotency | [workflows-transactions-and-idempotency.md](./references/workflows-transactions-and-idempotency.md) |
| Configuration and resource lifecycle | [configuration-and-resources.md](./references/configuration-and-resources.md) |
| Imports, exports, file organization | [imports-exports-and-files.md](./references/imports-exports-and-files.md) |
| Comments and JSDoc | [comments-and-jsdoc.md](./references/comments-and-jsdoc.md) |

## Apply Standards

1. Audit the local codebase for existing choices around libraries, schemas, errors, testing, observability, adapters, and module layout.
2. Classify the concerns touched.
3. Load every relevant topic file.
4. Follow local architecture where compatible; isolate compatibility at boundaries when old code violates a non-negotiable.
5. Make the smallest coherent improvement.
6. Verify through the seam callers actually use.
7. State trade-offs when a standard cannot fully apply without broad migration.

## Rejected Framings

- "Validation is enough." Parsing must return the refined value and pass it inward.
- "A wrapper is architecture." A wrapper earns its keep only when it hides policy, complexity, or boundary translation.
- "Mocks make tests isolated." Prefer behavior replacement through real seams.
- "Types are proof." Runtime data must be parsed.
- "Future flexibility justifies an interface." A seam is real only when behavior varies, a boundary translates, or tests substitute through an intentional seam.
