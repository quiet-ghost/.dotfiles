# Type Manipulation

Use this for generics, constraints, `keyof`, `typeof`, indexed access, conditional types, mapped types, template literal types, and utility types.

## Contents

- Generics
- Key and value operators
- Conditional types
- Mapped types
- Template literal types
- Utility types
- Complexity guardrails

## Generics

Generics connect input and output types.

```ts
function first<T>(items: readonly T[]): T | undefined {
  return items[0]
}
```

Use constraints when the implementation needs a capability:

```ts
function getId<T extends { id: string }>(value: T): string {
  return value.id
}
```

Avoid generics that do not relate multiple positions. A concrete type may be clearer.

## Key and Value Operators

- `keyof T`: union of property keys.
- `typeof value`: type of a runtime value in type position.
- `T[K]`: indexed access type.
- `K extends keyof T`: common safe property accessor constraint.

```ts
function get<T, K extends keyof T>(value: T, key: K): T[K] {
  return value[key]
}
```

## Conditional Types

Conditional types branch on assignability:

```ts
type ElementOf<T> = T extends readonly (infer U)[] ? U : never
```

Use them for type relationships that cannot be expressed with simple generics. Avoid large nested conditionals unless they are hidden behind stable public aliases.

## Mapped Types

Mapped types transform object properties:

```ts
type ReadonlyRecord<T> = {
  readonly [K in keyof T]: T[K]
}
```

Use key remapping with care:

```ts
type EventHandlers<T extends string> = {
  [K in T as `on${Capitalize<K>}`]: () => void
}
```

## Template Literal Types

Template literal types build string unions from smaller unions. They are powerful for event names, route names, object paths, and generated keys.

Prefer them when they prevent real mistakes. Avoid making every string format a type-level parser.

## Utility Types

Common built-ins:

- `Partial<T>`: all properties optional; avoid as a persistent domain model.
- `Required<T>`: all properties required.
- `Readonly<T>`: readonly properties.
- `Pick<T, K>` and `Omit<T, K>`: select or remove keys.
- `Record<K, V>`: object keyed by `K` with values `V`.
- `Extract<T, U>` and `Exclude<T, U>`: union filtering.
- `NonNullable<T>`: remove `null` and `undefined`.
- `Parameters<F>` and `ReturnType<F>`: function type reflection.
- `Awaited<T>`: unwrap promise-like types.

## Complexity Guardrails

- Prefer simple domain types over clever type programs.
- Name complex intermediate types.
- Add examples or type tests for public generic utilities.
- Watch for slow or unreadable recursive types.
- If callers need to understand a conditional type to use an API, the API may be too clever.

## Official Docs

- Creating Types from Types: https://www.typescriptlang.org/docs/handbook/2/types-from-types.html
- Generics: https://www.typescriptlang.org/docs/handbook/2/generics.html
- Keyof Type Operator: https://www.typescriptlang.org/docs/handbook/2/keyof-types.html
- Typeof Type Operator: https://www.typescriptlang.org/docs/handbook/2/typeof-types.html
- Indexed Access Types: https://www.typescriptlang.org/docs/handbook/2/indexed-access-types.html
- Conditional Types: https://www.typescriptlang.org/docs/handbook/2/conditional-types.html
- Mapped Types: https://www.typescriptlang.org/docs/handbook/2/mapped-types.html
- Template Literal Types: https://www.typescriptlang.org/docs/handbook/2/template-literal-types.html
- Utility Types: https://www.typescriptlang.org/docs/handbook/utility-types.html
