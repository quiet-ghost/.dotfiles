# Error Handling

Expected failures are part of the contract. Defects are exceptional.

## Rules

- Model expected failures as typed values with stable tags.
- Reserve throws for defects, impossible states, framework boundaries, or truly unrecoverable startup failures.
- Classify caught `unknown` values before reading fields or logging.
- Preserve cause safely for debugging without leaking secrets.
- Keep caller-relevant failure cases distinguishable; avoid broad string errors.
- State what happened, impact, preserved state, and recovery action in user-facing errors.

## Expected Failures

Examples: not found, permission denied, invalid input, conflict, dependency unavailable, timeout, cancellation, quota exceeded, duplicate, stale version.

These belong in return channels such as `Result`, `Effect<A, E, R>`, or an established project equivalent.

## Error Type Shape

```ts
type SaveUserError =
  | { readonly tag: "UserAlreadyExists"; readonly email: EmailAddress }
  | { readonly tag: "UserStoreUnavailable"; readonly cause: SafeCause };
```

## Review Checks

- Can normal operation fail via throw/rejection with no typed contract?
- Are callers forced to parse error strings?
- Are dependency failures classified at the correct layer?
- Can secret or raw payload data enter errors or diagnostics?
