# TypeScript Contracts

TypeScript should preserve proof obligations instead of erasing them. Keep contracts precise, immutable by default, documented at exports, and enforced by boring checks.

## Rules

- Do not use `any`, non-`as const` assertions, or non-null assertions to erase unproven obligations.
- Permitted type escape hatches are local, hidden behind precise interfaces, and justified with `SAFETY:`.
- Catch variables and rejection reasons are `unknown` until classified.
- Expose fields and collections as `readonly` unless caller mutation is part of the contract.
- Use `??` for absent defaults; use `||` only when all falsy values should fall back.
- Avoid `filter(Boolean)` when `0`, `false`, or `""` may be valid.
- Avoid object spread on class instances, errors, dates, maps, sets, branded wrappers, or domain values with behavior.
- Prefer explicit projection over `delete` for public response shapes.
- Preserve strict compiler/lint settings; do not weaken config to admit changed code.

## Escape Hatch Shape

```ts
// SAFETY: parseUserId established the UserId invariant; callers cannot construct UserId directly.
return input as UserId;
```

## Review Checks

- `as Type` on decoded JSON, SDK responses, or database rows.
- `!` after indexing or optional fields instead of refining.
- Spread-in-reduce accumulation on unbounded collections.
- Exports added only for tests.
- New barrels, `utils.ts`, `helpers.ts`, or broad optional bags.
