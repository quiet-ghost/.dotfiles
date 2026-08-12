# Errors

Use this for typed failures, defects, recovery, and failure diagnostics.

## Expected Errors vs Defects

Expected errors go in the `E` channel:

- Validation failed.
- Entity not found.
- Permission denied.
- Rate limited.
- External service returned a known failure.

Defects are unrecoverable bugs or impossible states:

- Broken invariant.
- Programming error.
- Startup config failure when app cannot proceed.
- Unexpected exception at a boundary after wrapping context has been logged or modeled.

Do not hide domain failures as defects. Do not overuse `orDie`.

## Tagged Domain Errors

When supported, prefer `Schema.TaggedErrorClass` for serializable errors.

```ts
import { Schema } from "effect"

class UserNotFound extends Schema.TaggedErrorClass<UserNotFound>()(
  "UserNotFound",
  { id: UserId }
) {}

class ApiError extends Schema.TaggedErrorClass<ApiError>()(
  "ApiError",
  {
    endpoint: Schema.String,
    statusCode: Schema.Number,
    error: Schema.Defect
  }
) {}
```

If the project uses `Data.TaggedError`, continue that pattern unless migrating.

## Raising Errors

Use `Effect.fail` for expected errors:

```ts
return yield* Effect.fail(new UserNotFound({ id }))
```

Some tagged errors are yieldable in newer versions:

```ts
yield* new UserNotFound({ id })
```

Verify yieldable error support against installed types before using it.

## Wrapping External Failures

Use `Effect.try` and `Effect.tryPromise` to convert exceptions or rejected promises into typed errors.

```ts
const fetchUser = (id: UserId) =>
  Effect.tryPromise({
    try: () => fetch(`/api/users/${id}`),
    catch: (error) => new ApiError({
      endpoint: `/api/users/${id}`,
      statusCode: 500,
      error
    })
  })
```

Use `Schema.Defect` for unknown underlying errors that need to be serializable.

## Recovery

Common recovery APIs:

- `Effect.catch`: handle all expected errors.
- `Effect.catchTag`: handle one tagged error.
- `Effect.catchTags`: handle multiple tagged errors.
- `Effect.orElse`: fallback with another effect.
- `Effect.match` / `Effect.matchEffect`: fold success and failure.
- `Effect.exit`: inspect success, expected failure, defects, and interruption as data.

Example:

```ts
const result = loadUser(id).pipe(
  Effect.catchTag("UserNotFound", () => Effect.succeed(GuestUser))
)
```

## Retrying and Timeouts

Retry only failures that are safe to retry. Do not retry validation or authorization failures.

```ts
const call = request.pipe(
  Effect.timeout("2 seconds"),
  Effect.retry(retryTransientFailures),
  Effect.timeout("10 seconds")
)
```

Use a per-attempt timeout before retry, then an overall timeout after retry.

## Cause and Exit

Use `Exit` and `Cause` for diagnostics, tests, and sandboxing.

- `Exit.Success`: success value.
- `Exit.Failure`: cause of failure.
- `Cause.Fail`: expected error.
- `Cause.Die`: defect.
- `Cause.Interrupt`: fiber interruption.

Avoid catching defects except at system boundaries such as plugin sandboxes, job supervisors, and crash reporting.

## Error Design Checklist

- Error type names describe what happened, not who handles them.
- Error fields include useful recovery context: ids, endpoint, status, provider, operation.
- Errors are serializable when crossing process/network boundaries.
- Expected errors are handled near the boundary that can recover.
- Unknown external errors are wrapped with operational context.
- Defects remain visible and observable.
