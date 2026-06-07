# Gotchas

Use this when Effect code fails to typecheck, behaves oddly, leaks resources, or mixes patterns.

## Fast Diagnostic Checklist

1. Check installed `effect` and related package versions.
2. Search current code for service, schema, error, and runtime patterns.
3. Read the exact failing type: `A`, `E`, or `R` usually points to the problem.
4. Inspect layer composition for missing requirements.
5. Inspect boundary decoding and error wrapping.
6. Verify runtime entrypoint and finalizers.
7. Run the smallest typecheck or test after fixing.

## Version Mismatch

Symptom: examples from docs fail to compile.

Cause: stable docs, beta docs, Effect Solutions, and installed package version differ.

Fix:

- Follow installed types for current code.
- Use project-local examples first.
- Only use beta/v4 patterns during explicit migration.
- Verify `Context.Service`, `Effect.fn`, `Schema.TaggedErrorClass`, and `effect/unstable/*` before using.

## Effect.promise Swallows Rejections as Defects

Symptom: expected async failures appear as fiber defects.

Cause: `Effect.promise` was used for a promise that can reject.

Fix: use `Effect.tryPromise` and map the rejection to a typed error.

## Requirement Leakage

Symptom: service method requires unrelated services, tests need extra layers, or `R` grows everywhere.

Cause: dependencies are used inside service methods instead of layer construction.

Fix: acquire dependencies in `Layer.effect`; return methods with `R = never`.

## Missing Layer

Symptom: runner rejects `Effect<A, E, SomeService>` where `R = never` is required.

Cause: service requirement was not provided.

Fix: provide an app/test layer at the boundary. Do not hide it with unsafe casts.

## Scattered provide Calls

Symptom: dependency graph is hard to follow and tests are brittle.

Cause: `Effect.provide` appears throughout business logic.

Fix: provide layers once near entrypoints and tests.

## Duplicate Resource Layers

Symptom: duplicate database pools, extra clients, connection limits hit.

Cause: parameterized layer constructors called multiple times.

Fix: store the layer in a constant and reuse the same reference.

## Running Too Early

Symptom: hard-to-test functions, lost error types, unexpected promises.

Cause: `Effect.runPromise` or `runSync` inside library/business code.

Fix: return `Effect` values and run only at boundaries.

## Boundary Casts

Symptom: runtime crashes despite TypeScript types.

Cause: external `unknown` data cast to a domain type.

Fix: decode with `Schema.decodeUnknownEffect` and keep Schema as source of truth.

## Untyped Errors

Symptom: `E` is `unknown`, `Error`, or a broad union everywhere.

Cause: external failures not wrapped into domain-specific errors.

Fix: use tagged errors with operation context and recovery-relevant fields.

## Defect Overuse

Symptom: recoverable user/API failures crash fibers.

Cause: `orDie`, `die`, or thrown exceptions used for expected errors.

Fix: keep recoverable failures in `E`; convert to defects only at deliberate boundaries.

## Tacit Function Inference Bugs

Symptom: generics disappear, overload errors, odd inference.

Cause: point-free/tacit combinator usage with overloaded functions.

Fix: use explicit lambdas such as `Effect.map((x) => fn(x))`.

## Unbounded Concurrency

Symptom: rate limits, memory pressure, too many open handles.

Cause: large arrays processed in parallel without a concurrency bound.

Fix: pass bounded concurrency where supported, or use queues/workers.

## Stream Collection Blowup

Symptom: memory grows or process hangs.

Cause: `runCollect` on large or infinite stream.

Fix: use sinks, `runForEach`, chunked writes, or bounded collection.

## TestClock Confusion

Symptom: delayed effects never finish or tests wait real time unexpectedly.

Cause: test clock vs live clock mismatch.

Fix: use `TestClock.adjust` in `it.effect`; use live helpers only when real time is required.

## Platform Imports in Domain Code

Symptom: domain code tied to Node/Bun/browser.

Cause: direct imports from `@effect/platform-*` in core modules.

Fix: move platform access to live layers/adapters and keep domain modules runtime-neutral.

## Unsafe Escape Hatches

Avoid these unless there is a clear, reviewed reason:

- `as any` or broad unsafe assertions.
- Non-null assertions.
- Swallowing errors with success-shaped fallbacks.
- Casting away `R` requirements.
- Catching all defects without reporting.

## Minimal Fix Strategy

- Fix the type where it first widens, not at the final runner.
- Prefer a small new Schema/error/service type over casts.
- Add or adjust one layer rather than passing dependencies manually.
- Add one focused test for the behavior or type boundary.
