# Testing Effect Code

Use this for unit, integration, and time-dependent tests.

## Prefer @effect/vitest

`@effect/vitest` runs Effect tests natively and provides better fiber failure output, layers, scoped cleanup, and test services.

Install if absent and the project uses Vitest:

```bash
pnpm add -D vitest @effect/vitest
```

Use `vitest`, not `bun test`, for `@effect/vitest` tests.

## Basic Test

```ts
import { Effect } from "effect"
import { describe, expect, it } from "@effect/vitest"

describe("Calculator", () => {
  it.effect("adds numbers", () =>
    Effect.gen(function* () {
      const result = yield* Effect.succeed(1 + 1)
      expect(result).toBe(2)
    })
  )
})
```

Use regular `it` for pure tests and `it.effect` for tests returning Effects.

## Layers in Tests

Provide test layers inline for per-test isolation.

```ts
const testLayer = Users.layer.pipe(
  Layer.provideMerge(Database.testLayer)
)

it.effect("finds a user", () =>
  Effect.gen(function* () {
    const users = yield* Users
    const user = yield* users.findById(UserId.make("user-1"))
    expect(user.id).toBe(UserId.make("user-1"))
  }).pipe(Effect.provide(testLayer))
)
```

Prefer fresh layers per test. Use shared `it.layer` only for expensive resources that can safely share state.

## Test Doubles

Use small layers:

- `Layer.succeed` for static values.
- `Layer.sync` for local mutable test state.
- `Layer.effect` for setup effects.
- `Layer.scoped` for resources that need cleanup.

Keep test doubles faithful to service contracts. Do not add helper methods to production contracts just for tests.

## Time

`it.effect` usually provides test services, including a test clock. Use `TestClock.adjust` for deterministic time.

```ts
import { Effect, Fiber } from "effect"
import { TestClock } from "effect/testing"

it.effect("delays deterministically", () =>
  Effect.gen(function* () {
    const fiber = yield* Effect.delay(Effect.succeed("done"), "10 seconds").pipe(
      Effect.fork
    )
    yield* TestClock.adjust("10 seconds")
    expect(yield* Fiber.join(fiber)).toBe("done")
  })
)
```

If a test needs real time, use the `it.live` helper when available.

## Randomness

Use test random services or deterministic generators for random-dependent code. Do not assert probabilistic behavior with real randomness.

## Scoped Resources

Scoped resources should close automatically at the end of an Effect test. This is useful for temp directories, servers, database transactions, and background workers.

## Error Assertions

Prefer inspecting typed failures with `Effect.exit` or `Effect.flip` over catching thrown fiber failures.

Example pattern:

```ts
const exit = yield* program.pipe(Effect.exit)
expect(exit._tag).toBe("Failure")
```

Use exact helpers available in the installed version.

## Running Tests

```bash
pnpm test
pnpm exec vitest run tests/user.test.ts
pnpm exec vitest run -t "Users.findById"
```

Use the repo's existing scripts when present.

## Smells

- Tests call `Effect.runPromise` inside `it.effect`.
- Shared mutable test layer leaks state across tests unintentionally.
- Time tests wait in real time instead of adjusting TestClock.
- Expected failures are asserted through thrown exceptions instead of the error channel.
- Test code uses non-null assertions instead of explicit guards.
