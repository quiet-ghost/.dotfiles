# Effect Standards

Use with the existing `effect` skill for API details. This file covers local architecture taste for Effect systems.

## Rules

- Keep `Effect` values lazy; run them only at app, framework, CLI, or test boundaries.
- Prefer `Effect.gen` for readable sequential workflows.
- Use Services/Tags/Layers for dependencies; avoid ad hoc dependency bags.
- Model recoverable failures in the `E` channel with stable tags.
- Use `Schema` for HTTP, CLI, config, files, queues, database rows, and external APIs.
- Provide layers near entrypoints and tests; avoid scattered `Effect.provide` in business logic.
- Use `Redacted` or equivalent for secrets and prevent secret diagnostics.
- Test through Effect-aware real seams and test layers.

## Review Checks

- Are expected failures thrown as defects?
- Does external data bypass `Schema` parsing?
- Are layers/services bypassed with hidden globals?
- Does test code mock internals instead of providing a layer?
- Are Effects run inside core functions instead of at boundaries?
