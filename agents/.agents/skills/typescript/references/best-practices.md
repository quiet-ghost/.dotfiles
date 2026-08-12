# TypeScript Best Practices

Use this when writing, reviewing, or refactoring TypeScript for safety, readability, and maintainability.

## Contents

- Safe defaults
- Boundary validation
- Domain modeling
- API design
- Assertions and escape hatches
- Testing and verification

## Safe Defaults

- Prefer `strict` TypeScript and fix errors with better models, not assertions.
- Prefer inference for local variables and explicit types for exported APIs, public object shapes, and boundary results.
- Prefer `unknown` over `any` for untrusted values.
- Prefer discriminated unions over boolean flags or objects with many optional fields.
- Prefer literal unions over enums unless runtime enum objects are required.
- Prefer `readonly` for data that should not be mutated through an API.
- Prefer `satisfies` when checking an object against a type while preserving literal inference.
- Prefer `as const` for fixed literals, tuples, and discriminants.

## Boundary Validation

TypeScript cannot validate runtime input. Validate at these boundaries:

- HTTP requests and responses
- JSON files and `JSON.parse`
- CLI args and environment variables
- Database rows and query results
- Message queues, storage, caches, and browser APIs
- Untyped or loosely typed third-party libraries

Boundary pattern:

```ts
type User = {
  id: string
  role: "admin" | "member"
}

function isUser(value: unknown): value is User {
  return (
    typeof value === "object" &&
    value !== null &&
    "id" in value &&
    "role" in value
  )
}
```

Prefer the repo's existing schema library when one exists.

## Domain Modeling

- Make illegal states unrepresentable with tagged unions.
- Put discriminants on every variant and keep them stable.
- Use `never` for exhaustive switch checks.
- Avoid `Partial<T>` as a domain model; it usually means the lifecycle needs explicit states.
- Avoid broad index signatures on domain objects; they hide misspelled keys.
- Keep generic parameters meaningful. If a generic is only used once, it may not be needed.

## API Design

- Export named domain types near the functions that use them.
- Prefer narrow input types and precise result types.
- Avoid returning large structural unions that callers cannot reasonably narrow.
- Use overloads for APIs with distinct call shapes; use union parameters when implementation and return type are uniform.
- Use `readonly T[]` for array inputs that are not mutated.
- Avoid exposing deep conditional types unless they materially improve caller experience.
- For libraries, treat generated `.d.ts` output as part of the public API.

## Assertions and Escape Hatches

Avoid by default:

- `any`
- Non-null assertion (`value!`)
- Double assertion (`value as unknown as T`)
- Broad object assertions (`{} as T`)
- Ambient global declarations for local convenience
- `// @ts-ignore` without a short reason

Prefer:

- `unknown` plus a guard or parser
- Control-flow narrowing
- `satisfies`
- Local helper functions with precise types
- `// @ts-expect-error` for intentional negative type tests

## Verification

- Run the repo's typecheck after type behavior changes.
- Add runtime tests when validation, parsing, or narrowing changes behavior.
- Add type-level tests only when the repo already has a pattern for them or library API types are the deliverable.
- When fixing a compiler error, verify no new `any` or assertion hides the same problem elsewhere.

## Official Docs

- Everyday Types: https://www.typescriptlang.org/docs/handbook/2/everyday-types.html
- Narrowing: https://www.typescriptlang.org/docs/handbook/2/narrowing.html
- Creating Types from Types: https://www.typescriptlang.org/docs/handbook/2/types-from-types.html
- Utility Types: https://www.typescriptlang.org/docs/handbook/utility-types.html
- Declaration Do's and Don'ts: https://www.typescriptlang.org/docs/handbook/declaration-files/do-s-and-don-ts.html
