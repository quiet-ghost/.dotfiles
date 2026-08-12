# Refactoring

Refactor only while tests are green.

## Good Refactor Targets

- Duplicate behavior or policy across callers.
- Parser or invariant logic scattered outside its domain module.
- Shallow wrappers that can be removed or deepened.
- Poor names revealed by tests.
- Hidden dependency that should become an explicit seam.
- Implementation detail exported only for tests.

## Rules

- Preserve behavior; tests should not need changes for pure refactors.
- Run focused tests after each refactor step.
- Stop when clarity and locality improve enough; do not chase perfect architecture.
