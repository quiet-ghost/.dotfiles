# Concurrency, Scheduling, and Coordination

Use this for fibers, parallelism, queues, retries, rate limits, state, and caching.

## Fibers

Fibers are lightweight Effect threads.

Common operations:

- `Effect.fork`: start a fiber.
- `Effect.forkScoped` or `Effect.forkChild`: tie lifetime to a scope or parent, depending on installed version.
- `Fiber.join`: wait for success or failure.
- `Fiber.interrupt`: stop a fiber and run finalizers.

Prefer scoped or child fibers for work that must not outlive the parent operation.

## Parallelism

Use `Effect.all` for multiple independent effects.

```ts
const result = yield* Effect.all(
  [loadUser(id), loadOrders(id)],
  { concurrency: 2 }
)
```

Verify exact options in installed types. Avoid unbounded concurrency for user-controlled input or large collections.

## Schedules

Schedules describe retry and repetition policies.

Common building blocks:

- `Schedule.recurs(n)`: limit attempts.
- `Schedule.spaced(duration)`: fixed delay.
- `Schedule.exponential(duration)`: exponential backoff.
- `Schedule.jittered`: avoid synchronized retries.
- `Schedule.both`: combine policies.

Pattern:

```ts
const retryPolicy = Schedule.exponential("100 millis").pipe(
  Schedule.both(Schedule.recurs(3))
)

const resilient = call.pipe(
  Effect.timeout("2 seconds"),
  Effect.retry(retryPolicy),
  Effect.timeout("10 seconds")
)
```

Retry only idempotent or otherwise safe operations.

## Coordination Primitives

Use the primitive that matches the concurrency problem.

| Need | Primitive |
|------|-----------|
| One producer/consumer handoff | `Queue` |
| Broadcast to many subscribers | `PubSub` |
| Complete once later | `Deferred` |
| Limit concurrent access | `Semaphore` |
| Wait for readiness/release | `Latch` when available |
| Mutable concurrent state | `Ref` |
| Effectful atomic state transitions | `SynchronizedRef` |
| State plus subscribers | `SubscriptionRef` |

## Queues

Use queues to decouple producers and consumers.

Design choices:

- Bounded vs unbounded.
- Backpressure vs dropping/sliding strategy.
- Worker count and shutdown behavior.
- Error handling per item.

Tie workers to a scope so they stop cleanly.

## Semaphores and Rate Limits

Use semaphores for resource limits:

```ts
const semaphore = yield* Effect.makeSemaphore(5)

const guarded = semaphore.withPermits(1)(callExternalApi)
```

Confirm helper names with installed types.

## Cache

Use Effect `Cache` for effectful memoization with capacity, TTL, and typed lookup failures.

Good uses:

- Read-through external API cache.
- Config or metadata lookup.
- Deduplicating concurrent identical requests.

Bad uses:

- Hiding mutation order problems.
- Caching unbounded user input.
- Storing secrets without redaction policy.

## Batching

Use batching/request resolver patterns when many small independent requests can be grouped into fewer backend calls.

Good signals:

- Repeated entity lookup by ID.
- Graph-style loading.
- N+1 query issues.

## Error and Interruption Notes

- Decide whether parallel failures should accumulate or fail fast.
- Ensure worker fibers are interrupted on shutdown.
- Put finalizers in scoped worker resources.
- Add spans/log annotations to background work so failures are traceable.

## Smells

- `Effect.all` over a large array with no concurrency bound.
- Retry policy applied to non-idempotent writes without safeguards.
- Worker fibers forked and forgotten.
- Queue consumers swallow item failures silently.
- Mutable state in plain variables shared by concurrent fibers instead of `Ref`/`SynchronizedRef`.
