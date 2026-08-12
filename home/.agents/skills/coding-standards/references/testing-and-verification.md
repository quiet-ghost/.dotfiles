# Testing and Verification

Tests should verify observable behavior through public interfaces or real seams. Refactors should not break tests when behavior stays the same.

## Rules

- Prefer integration-style tests over implementation-detail unit tests.
- Avoid module patching and method spies (`vi.mock`, `jest.mock`, `vi.spyOn`, `jest.spyOn`) unless the repo already requires them and no real seam exists.
- Replace behavior through production seams: constructor-injected dependency, Effect layer, recording fake adapter, local DB, local filesystem, runtime binding.
- Test parsed boundary behavior, important failure paths, domain invariants, and high-consequence flows.
- Property-test parsers, validators, transformations, state transitions, and combinator-heavy logic when practical.
- Use the smallest relevant verification: test, typecheck, lint, or build.

## Test Smells

- Test imports private/internal helpers only exported for tests.
- Test asserts call order on internal collaborators instead of observable outcome.
- Test passes by constructing states that production parsers forbid.
- Test checks database directly when public API should prove behavior.
- Mock shape changes break tests while behavior is unchanged.

## Review Checks

- Does each changed behavior have risk-matched evidence?
- Are failure paths and parser rejections covered?
- Are tests coupled to implementation details?
- Is the seam used in tests the same seam production callers use?
