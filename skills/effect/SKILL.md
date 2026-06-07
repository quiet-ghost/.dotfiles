---
name: effect
description: "Builds and troubleshoots Effect TypeScript systems: Effect, Effect.gen, Effect.fn, Schema, Context.Service, Layer, Config, Stream, Schedule, @effect/platform, and @effect/vitest. Use when writing, reviewing, migrating, debugging, or testing Effect-based TypeScript code."
references:
  - references/README.md
  - references/setup.md
  - references/core.md
  - references/services-layers.md
  - references/schema-data.md
  - references/errors.md
  - references/resources-runtime.md
  - references/concurrency.md
  - references/streams.md
  - references/config-observability.md
  - references/testing.md
  - references/platform-cli.md
  - references/gotchas.md
---

# Effect Skill

Use this skill for Effect TypeScript systems: application architecture, service/layer design, typed errors, Schema validation, resource safety, concurrency, streams, platform integrations, and tests.

## Critical Rules

- First inspect the installed `effect` version and current project import style. Stable docs, beta docs, and Effect Solutions examples can differ.
- Do not invent API signatures. If unclear, inspect `node_modules/effect`, local source, Context7, or official docs before editing.
- Preserve existing project conventions unless a migration/refactor is requested.
- Keep Effect values lazy. Run them only at app, framework, CLI, or test boundaries.
- Prefer `Effect.gen` for readable sequential workflows.
- Prefer `Effect.fn` for exported or service methods when available and already compatible with the installed version.
- Use `Schema` at untrusted boundaries: HTTP, CLI, config, files, queues, databases, and external APIs.
- Model recoverable domain failures in `E`. Use defects only for unrecoverable bugs or impossible states.
- Provide layers near entrypoints and tests. Avoid scattered `Effect.provide` calls in business logic.
- Verify changed Effect code with the smallest relevant typecheck or test.

## Quick Router

```text
Need Effect help?
|- New project, install, tsconfig, language service -> setup.md
|- Effect type, gen, fn, construction, running -> core.md
|- Services, dependency injection, Layers -> services-layers.md
|- Domain data, parsing, brands, JSON, Standard Schema -> schema-data.md
|- Typed errors, defects, recovery, retry classification -> errors.md
|- Resource safety, Scope, finalizers, runtime entrypoints -> resources-runtime.md
|- Fibers, queues, pubsub, semaphore, schedules, cache -> concurrency.md
|- Streams, sinks, resourceful streaming -> streams.md
|- Config, logging, metrics, tracing, supervisors -> config-observability.md
|- @effect/vitest, TestClock, test layers -> testing.md
|- @effect/platform, CLI, filesystem, terminal, HTTP -> platform-cli.md
|- Bug, migration, weird types, failures -> gotchas.md
```

## Reading Order

| Task | Files to Read |
|------|---------------|
| New Effect work | [README.md](./references/README.md) -> [setup.md](./references/setup.md) -> task file |
| Implement business flow | [core.md](./references/core.md) -> [services-layers.md](./references/services-layers.md) -> [errors.md](./references/errors.md) |
| Model/validate data | [schema-data.md](./references/schema-data.md) -> [errors.md](./references/errors.md) |
| Wire an app | [services-layers.md](./references/services-layers.md) -> [resources-runtime.md](./references/resources-runtime.md) -> [config-observability.md](./references/config-observability.md) |
| Add concurrency/retry/streaming | [concurrency.md](./references/concurrency.md) -> [streams.md](./references/streams.md) |
| Test Effect code | [testing.md](./references/testing.md) -> [services-layers.md](./references/services-layers.md) |
| Debug or migrate | [gotchas.md](./references/gotchas.md) -> relevant topic file |

## In This Reference

| File | Purpose |
|------|---------|
| [README.md](./references/README.md) | Mental model, version detection, architecture workflow |
| [setup.md](./references/setup.md) | Packages, tsconfig, language service, docs/source lookup |
| [core.md](./references/core.md) | `Effect<A, E, R>`, constructors, `Effect.gen`, `Effect.fn`, running |
| [services-layers.md](./references/services-layers.md) | Service tags, Context.Service, Effect.Service, Layer composition |
| [schema-data.md](./references/schema-data.md) | Schema, data modeling, brands, variants, JSON, Standard Schema |
| [errors.md](./references/errors.md) | Expected errors, defects, Cause, Exit, typed recovery |
| [resources-runtime.md](./references/resources-runtime.md) | Scope, finalizers, acquire/release, runMain |
| [concurrency.md](./references/concurrency.md) | Fibers, coordination primitives, schedules, cache, batching |
| [streams.md](./references/streams.md) | Stream/Sink creation, transforms, resourceful streams |
| [config-observability.md](./references/config-observability.md) | Config, redaction, logging, metrics, tracing |
| [testing.md](./references/testing.md) | @effect/vitest, test layers, TestClock, deterministic tests |
| [platform-cli.md](./references/platform-cli.md) | @effect/platform runtimes, CLI, filesystem, terminal, HTTP |
| [gotchas.md](./references/gotchas.md) | Common mistakes, diagnostics, migration checks |

## External Sources

- Official docs: https://effect.website/docs/
- Prescriptive guide: https://www.effect.solutions/
- Context7 docs: `/websites/effect-ts_github_io_effect`
- Source and API reference: https://github.com/Effect-TS/effect
