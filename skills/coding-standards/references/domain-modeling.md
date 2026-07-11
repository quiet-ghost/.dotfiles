# Domain Modeling

Make illegal states unrepresentable where practical. Put domain rules in the module that owns the concept, not in scattered callers.

## Rules

- Prefer discriminated unions for finite states, lifecycle phases, and mutually exclusive shapes.
- Prefer domain-specific values over strings, booleans, nullable bags, and loose option objects.
- Use smart constructors or parsers for values with invariants.
- Keep optionality meaningful: absent, unknown, unavailable, and intentionally empty are different states.
- Avoid `Partial<T>` as operation input unless the operation truly accepts any subset.
- Avoid boolean flag combinations when variants communicate intent better.
- Make state transitions explicit functions with typed inputs and failures.
- Persist canonical state, not caller convenience shapes.

## Strong Defaults

- Name domain operations by the domain transition: `activate`, `expire`, `recordPayment`, not generic `update` when rules exist.
- Keep parsing and constructors near the primary domain type.
- In TypeScript, prefer the namespaced module pattern when the repo permits it: `export type UserId = ...` plus `export const UserId = { parse, unsafeFromTrusted }`.

## Review Checks

- Can invalid state be constructed from changed code?
- Are invariants repeated across callers?
- Does a persistence/API DTO leak inward where a domain value should exist?
- Is a boolean or nullable field hiding several cases?
- Does test data bypass constructors/parsers and create impossible states?
