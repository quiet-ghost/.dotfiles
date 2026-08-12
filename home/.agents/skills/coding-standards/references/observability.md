# Observability

Diagnostics should explain failures without leaking secrets or coupling callers to raw internals.

## Rules

- Logs, traces, metrics, error messages, snapshots, and panic summaries must not include secrets or raw sensitive payloads.
- Prefer stable tags and safe summaries over arbitrary object serialization.
- Preserve correlation identifiers across async and runtime boundaries.
- Log at the layer that has enough context to classify impact and recovery.
- Do not replace actionable failures with generic messages.
- Redact before values cross diagnostic seams.

## Safe Context

Good diagnostic context includes operation name, safe identifiers, dependency name, expected vs actual state, and likely remediation.

Avoid tokens, passwords, cookies, authorization headers, private keys, raw request bodies, PII unless explicitly safe and required.

## Review Checks

- Can a sensitive value reach a log/error/trace/metric/snapshot?
- Is a caught unknown logged directly?
- Does an error message say what happened and what to do next?
- Are correlation hooks preserved through changed paths?
