# Effect Overview

Effect is a TypeScript effect system for describing lazy, typed workflows with structured errors, dependency injection, concurrency, resource safety, and observability.

## Mental Model

- `Effect<A, E, R>` describes a program that can succeed with `A`, fail with expected error `E`, and require services `R`.
- Effects are immutable descriptions. They do not execute until interpreted by a runtime.
- `never` means there are no possible values: `E = never` cannot fail; `R = never` needs no services.
- Business logic composes effects; entrypoints run effects.
- Services live in a `Context`; `Layer` values build services and wire dependencies.
- `Schema<A, I, R>` describes data and can decode/encode, validate, pretty-print, generate JSON Schema, and integrate with Standard Schema.

## Version Detection

Always determine the installed version before writing Effect code.

1. Inspect `package.json` and the lockfile for `effect`, `@effect/platform-*`, `@effect/vitest`, and related packages.
2. If dependencies are installed, inspect `node_modules/effect/package.json` and relevant `.d.ts` files for exact APIs.
3. Search the project for imports like `from "effect"`, `effect/Schema`, `effect/unstable/*`, `@effect/platform-node`, or `@effect/vitest`.
4. If docs and installed types disagree, follow installed types unless the task is an upgrade.

## Stable vs Beta Notes

- Official docs at `effect.website/docs` are the main source of truth.
- Effect Solutions is prescriptive and often tracks current beta/v4 idioms.
- APIs such as `Context.Service`, `Effect.fn`, `Schema.TaggedErrorClass`, and `effect/unstable/*` should be verified against the installed version.
- Existing projects may use older `Context.Tag`, `Data.TaggedError`, or hand-rolled service classes. Continue those patterns unless migration is requested.

## Architecture Workflow

Use this shape for serious Effect systems:

1. Model domain data with `Schema`, brands, and tagged variants.
2. Model recoverable failures as tagged expected errors.
3. Define service contracts before implementations.
4. Keep service method requirements `R = never`; implementation dependencies belong in layers.
5. Compose app layers once near the entrypoint.
6. Decode external input at the boundary, run typed business effects internally, encode output at the boundary.
7. Use runtime entrypoints (`NodeRuntime.runMain`, `BunRuntime.runMain`, framework adapters) for graceful execution.
8. Test with `@effect/vitest` and test layers.

## Agent Workflow

- Read enough project code to identify local style before editing.
- Prefer small changes that improve type information rather than broad rewrites.
- For unknown APIs, query Context7 or inspect local source/types.
- For failures, read the typed error channel, layer requirements, and runtime boundary before guessing.
- After edits, run a relevant typecheck, test, or file-specific validation.

## Next File Routing

- Setup and tooling: [setup.md](./setup.md)
- Core Effect usage: [core.md](./core.md)
- Services and layers: [services-layers.md](./services-layers.md)
- Schema and data: [schema-data.md](./schema-data.md)
- Errors: [errors.md](./errors.md)
- Runtime and resources: [resources-runtime.md](./resources-runtime.md)
- Concurrency and schedules: [concurrency.md](./concurrency.md)
- Streams and sinks: [streams.md](./streams.md)
- Config and observability: [config-observability.md](./config-observability.md)
- Testing: [testing.md](./testing.md)
- Platform and CLI: [platform-cli.md](./platform-cli.md)
- Troubleshooting: [gotchas.md](./gotchas.md)
