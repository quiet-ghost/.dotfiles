# Resources and Runtime

Use this for resource safety, finalization, scopes, and application entrypoints.

## Resource Principles

- Every acquisition needs a release path.
- Finalizers must run on success, expected failure, defects, and interruption.
- Prefer scoped resources and `Layer.scoped` for long-lived services.
- Use platform `runMain` helpers for real apps so interruption triggers cleanup.

## Finalizers

Common finalizer operators:

- `Effect.ensuring(finalizer)`: always runs a finalizer.
- `Effect.onExit((exit) => ...)`: runs with the full `Exit`.
- `Effect.onError((cause) => ...)`: runs for failure/interruption causes.

Example:

```ts
const program = useResource.pipe(
  Effect.ensuring(Effect.logInfo("cleanup complete"))
)
```

Use `onExit` when cleanup needs to inspect success vs failure.

## Acquire, Use, Release

For one-off resources, use the installed acquire/use/release API. Official docs show `Effect.acquireUseRelease`; some codebases also use scoped acquire/release helpers.

```ts
const program = Effect.acquireUseRelease(
  acquireConnection,
  (connection) => query(connection),
  (connection) => closeConnection(connection)
)
```

Check local types for argument order and helper names.

## Scope

`Scope` lets multiple resources share a lifetime.

Typical uses:

- Temporary files and directories.
- Database pools.
- Servers and sockets.
- Background fibers tied to a parent operation.

Use `Effect.scoped` to open and close a scope around scoped effects.

Use scoped constructors in tests so cleanup happens automatically.

## Resource Layers

Use `Layer.scoped` for services with lifecycle.

```ts
class Database extends Context.Service<Database, DatabaseApi>()("@app/Database") {
  static readonly layer = Layer.scoped(
    Database,
    Effect.gen(function* () {
      const pool = yield* openPool
      yield* Effect.addFinalizer(() => closePool(pool))
      return makeDatabaseApi(pool)
    })
  )
}
```

If `Context.Service` is unavailable, use the project service pattern and the same `Layer.scoped` idea.

## Running Apps

Use platform runtimes for long-running apps:

```ts
import { NodeRuntime } from "@effect/platform-node"

NodeRuntime.runMain(main)
```

For Bun:

```ts
import { BunRuntime } from "@effect/platform-bun"

BunRuntime.runMain(main)
```

For browser apps, check the installed `@effect/platform-browser` API.

## Runner Selection

| Runner | Use Case |
|--------|----------|
| `runMain` | App/CLI/server boundary with graceful shutdown |
| `Effect.runPromise` | Promise adapter or script boundary |
| `Effect.runPromiseExit` | Need structured result instead of rejection |
| `Effect.runSync` | Purely synchronous and non-failing effects only |
| `Effect.runFork` | Background fiber from a boundary or supervisor |

Do not use `runSync` for async or failing effects. It can throw fiber failures.

## Interruption

Effect fibers are interruptible. On interruption:

- Finalizers run.
- Scoped resources release.
- Child fibers can be interrupted depending on how they were forked.
- `runMain` handles common shutdown signals.

Use scoped or child forks for background work that must not leak past the parent lifetime.

## Smells

- Database pool constructed at module top level with no release.
- Server started with `Effect.runPromise` and no graceful shutdown.
- `runSync` used around unknown or async effects.
- Finalizers manually duplicated instead of using scope/layers.
- Background fibers created without a supervisor, scope, or interruption path.
