# Core Effect

Use this for basic Effect construction, composition, and execution.

## Effect Type

`Effect<A, E, R>` means:

- `A`: success value.
- `E`: expected recoverable error.
- `R`: required services from `Context`.

Rules:

- Effects are lazy descriptions.
- Effects are values; compose them freely.
- Do not call `Effect.runPromise`, `Effect.runSync`, or runtime runners inside business logic.
- Run once at a boundary: app main, route adapter, queue consumer, CLI, or test helper.

## Constructors

Common constructors:

```ts
import { Effect } from "effect"

const value = Effect.succeed(42)
const failed = Effect.fail(new Error("recoverable"))
const sync = Effect.sync(() => Date.now())

const maybeThrowing = Effect.try({
  try: () => JSON.parse('{"ok":true}') as unknown,
  catch: (error) => new Error(`Parse failed: ${String(error)}`)
})

const asyncMaybeRejects = Effect.tryPromise({
  try: () => fetch("https://example.com"),
  catch: (error) => new Error(`Request failed: ${String(error)}`)
})
```

Use `Effect.promise` only when the promise is guaranteed not to reject. Otherwise use `Effect.tryPromise`.

## Generators

Use `Effect.gen` for sequential workflows.

```ts
import { Effect } from "effect"

const program = Effect.gen(function* () {
  const user = yield* loadUser("user-1")
  yield* Effect.logInfo(`Loaded user ${user.id}`)
  return yield* sendWelcomeEmail(user)
})
```

Inside `Effect.gen`:

- Use `yield* effect` for effects and service tags.
- Use normal `if`, `for`, `while`, and early returns.
- A failed yielded effect short-circuits the generator.

## Effect.fn

`Effect.fn` names an effectful function and improves tracing when supported by the installed version.

```ts
import { Effect } from "effect"

const processUser = Effect.fn("processUser")(function* (userId: string) {
  const user = yield* loadUser(userId)
  yield* Effect.logInfo(`Processing ${user.id}`)
  return yield* saveUser(user)
})
```

Use it for exported operations and service methods when local types confirm support. If unavailable, use a normal function returning `Effect.gen` and add `Effect.withSpan` where tracing is needed.

## Pipes and Instrumentation

Use `.pipe()` for cross-cutting operators:

```ts
import { Effect, Schedule } from "effect"

const retryPolicy = Schedule.exponential("100 millis").pipe(
  Schedule.both(Schedule.recurs(3))
)

const result = callExternalApi.pipe(
  Effect.timeout("2 seconds"),
  Effect.retry(retryPolicy),
  Effect.tap((response) => Effect.logInfo(`status=${response.status}`)),
  Effect.withSpan("callExternalApi")
)
```

Prefer explicit lambdas over tacit usage when passing functions into Effect combinators. It preserves inference and avoids overload surprises.

## Running Effects

Boundary runners:

```ts
Effect.runPromise(program)
Effect.runSync(syncProgram)
Effect.runPromiseExit(program)
Effect.runFork(backgroundProgram)
```

For real apps, prefer platform `runMain` helpers for graceful interruption. See [resources-runtime.md](./resources-runtime.md).

## Common Composition APIs

- `Effect.map`: transform success value.
- `Effect.flatMap` / `Effect.andThen`: sequence dependent effects.
- `Effect.tap`: run an effect without changing the value.
- `Effect.all`: combine multiple effects, optionally in parallel depending on options and version.
- `Effect.provide`: satisfy service requirements with a layer.
- `Effect.provideService`: satisfy one service directly, mostly for small tests or adapters.

## Design Guidance

- Let return types infer unless exported API clarity needs annotation.
- Annotate service contract methods so `A`, `E`, and `R` are explicit.
- Avoid `any`, unsafe casts, and non-null assertions. Use Schema, Option, Either, or typed errors.
- Keep pure calculations pure; wrap only real effects in `Effect`.
