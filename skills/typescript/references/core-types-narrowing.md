# Core Types and Narrowing

Use this for everyday types, unions, literals, `unknown`, `never`, and control-flow analysis.

## Contents

- Everyday types
- Special types
- Literal inference
- Narrowing tools
- Discriminated unions
- Exhaustiveness

## Everyday Types

- Primitives: `string`, `number`, `boolean`, `bigint`, `symbol`, `null`, `undefined`.
- Arrays: `T[]` or `Array<T>`; prefer the style already used by the repo.
- Tuples: fixed-position arrays, useful for stable pairs and return values.
- Objects: type by required and optional properties.
- Unions: values that can be one of several alternatives.
- Type aliases and interfaces: both name shapes; follow repo convention.

## Special Types

- `unknown`: safe top type. Must narrow before use.
- `any`: unsafe escape hatch. It disables checking and spreads quickly.
- `never`: impossible value. Useful for exhaustiveness and impossible states.
- `void`: usually a function return that callers should not use.
- `object`: any non-primitive. Usually too broad for APIs.
- `{}`: any non-nullish value. Rarely what a domain model needs.

## Literal Inference

Use literal types to preserve domain meaning:

```ts
type Status = "idle" | "loading" | "success" | "error"

const status = "idle" satisfies Status
```

Use `as const` for fixed object and tuple literals:

```ts
const route = { method: "GET", path: "/users" } as const
```

## Narrowing Tools

TypeScript narrows through JavaScript checks:

- `typeof value === "string"`
- `value !== null`
- `Array.isArray(value)`
- `"kind" in value`
- `value instanceof Date`
- Equality checks between related values
- User-defined type predicates
- Assertion functions
- Control flow with returns, throws, and assignments

Avoid truthiness narrowing when empty strings, `0`, or `false` are valid values.

## Discriminated Unions

Prefer one stable discriminant property for variant state:

```ts
type LoadState<T> =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; value: T }
  | { status: "error"; error: string }

function render<T>(state: LoadState<T>): string {
  switch (state.status) {
    case "idle":
      return "Idle"
    case "loading":
      return "Loading"
    case "success":
      return String(state.value)
    case "error":
      return state.error
  }
}
```

## Exhaustiveness

Use `never` checks when a union must be complete:

```ts
function assertNever(value: never): never {
  throw new Error(`Unexpected value: ${String(value)}`)
}
```

If `assertNever(state)` errors at compile time, a variant is unhandled.

## Official Docs

- The Basics: https://www.typescriptlang.org/docs/handbook/2/basic-types.html
- Everyday Types: https://www.typescriptlang.org/docs/handbook/2/everyday-types.html
- Narrowing: https://www.typescriptlang.org/docs/handbook/2/narrowing.html
- Type Inference: https://www.typescriptlang.org/docs/handbook/type-inference.html
- Variable Declaration: https://www.typescriptlang.org/docs/handbook/variable-declarations.html
