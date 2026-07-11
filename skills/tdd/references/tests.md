# Tests

Good tests describe capabilities. They should survive internal refactors.

## Prefer

- Public API, CLI command, route handler, service module, Effect program, or adapter seam that callers use.
- Real parsers, real domain constructors, real persistence substitutes when practical.
- Explicit assertions on observable outputs, state, emitted events, or typed failures.
- Test data created through production constructors or valid builders.

## Avoid

- Private helper imports.
- Assertions about internal call order when output proves behavior.
- Snapshotting broad objects with volatile or sensitive fields.
- Tests that pass with impossible production states.
- Large test batches before any implementation exists.

## Behavior Slice Shape

```txt
Given <realistic state/input>
When <public action>
Then <observable result or typed failure>
```
