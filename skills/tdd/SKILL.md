---
name: tdd
description: Red-green-refactor test-driven development workflow. Use when building features or fixing bugs test-first, when the user says TDD, red-green-refactor, tracer bullet, or asks for integration-style tests.
---

# Test-Driven Development

Use this skill for test-first implementation. Tests should verify behavior through public interfaces or real seams, not implementation details.

## Core Rule

Do vertical slices, not horizontal batches.

```txt
Wrong: write all tests -> write all implementation
Right: one failing behavior test -> minimal implementation -> repeat
```

## Workflow

1. Identify the public interface or real seam callers use.
2. List behavior slices in priority order.
3. Write one failing test for the first behavior.
4. Implement only enough code to pass it.
5. Repeat one behavior at a time.
6. Refactor only while green.
7. Run the smallest relevant verification after each meaningful step.

## Test Rules

- Test behavior, not private structure.
- Prefer integration-style tests using real code paths.
- Replace dependencies through production seams, not module mocks or method spies.
- Keep test names in project vocabulary.
- Do not export internals just for tests.
- Use property tests for parsers, validators, state transitions, and transformations when practical.

## Reading Order

| Task | Files to Read |
|------|---------------|
| Behavior test design | [tests.md](./references/tests.md) |
| Dependency replacement | [mocking.md](./references/mocking.md) |
| Refactor after green | [refactoring.md](./references/refactoring.md) |

## Per-Cycle Checklist

- Test describes one observable behavior.
- Test uses the public interface or a real seam.
- Test fails for the expected reason.
- Code is minimal for this behavior.
- No speculative future behavior added.
- Suite returns green before refactor.
