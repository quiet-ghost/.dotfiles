# Async and Workflows

Async code must make ownership, cancellation, concurrency, retries, and side effects explicit.

## Rules

- Promises are awaited, returned, collected, or explicitly detached with ownership and error handling.
- Propagate `AbortSignal` or the repo's cancellation mechanism through dependency calls.
- Bound concurrency when processing unbounded input.
- Do not retry mutations unless idempotency or durable de-duplication is clear.
- Preserve transaction boundaries around invariants that must change together.
- Keep durable workflow state explicit; do not hide multi-step state in ad hoc flags.
- Prefer `Promise.allSettled` when every task must run and failures are aggregated.

## Review Checks

- Is there a floating promise or swallowed rejection?
- Is async work accidentally sequential or accidentally unbounded?
- Can cancellation stop all reachable dependency work?
- Can retries duplicate side effects?
- Is there a race between read/check/write steps?
- Are workflow transitions persisted and resumable where required?
