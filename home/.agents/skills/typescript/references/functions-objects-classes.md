# Functions, Objects, and Classes

Use this for function signatures, callbacks, overloads, object shapes, class typing, and structural compatibility.

## Contents

- Function design
- Callback typing
- Overloads
- Object types
- Optional properties
- Classes
- Compatibility

## Function Design

- Type exported functions at the boundary.
- Let local return types infer unless an explicit return type improves diagnostics or public API stability.
- Use `readonly T[]` for inputs that are not mutated.
- Use union parameters when one implementation handles all cases similarly.
- Use overloads when input shape changes the return type in caller-visible ways.

```ts
function parse(input: string): Date
function parse(input: number): Date
function parse(input: string | number): Date {
  return new Date(input)
}
```

## Callback Typing

- Keep callback parameter types as narrow as callers need.
- Do not mark callback parameters optional unless the implementation may omit them.
- Prefer named function types for repeated callback shapes.
- Remember `void` return allows callers to return a value that is ignored.

```ts
type Visit<T> = (value: T, index: number) => void
```

## `this` Parameters

Use explicit `this` parameters for functions that depend on a receiver:

```ts
function format(this: { prefix: string }, value: string): string {
  return `${this.prefix}${value}`
}
```

Prefer avoiding dynamic `this` in new code unless matching a framework or JavaScript API.

## Object Types

- Use required properties for required data.
- Use optional properties only when absence is meaningful.
- Prefer discriminated unions to objects with several optional fields.
- Use index signatures only for true dictionaries.
- Use `Record<K, V>` for known key unions and dictionary-like data.

## Optional Properties

With `exactOptionalPropertyTypes`, `name?: string` means the property may be absent; it does not automatically mean `name: undefined` is valid.

Choose deliberately:

- `name?: string`: absent or string.
- `name: string | undefined`: key exists but value may be undefined.
- `name?: string | undefined`: absent, string, or explicit undefined.

## Classes

- Classes have runtime behavior and type behavior.
- Use classes when identity, inheritance, private fields, decorators, or runtime constructors matter.
- Prefer object types or functions for simple data modeling.
- Use `override` with `noImplicitOverride` for safer inheritance.
- Understand that TypeScript `private` and ECMAScript `#private` have different runtime behavior.

## Compatibility

TypeScript is structural. A value can satisfy an interface without explicitly declaring it.

Implications:

- Public shape controls assignability.
- Extra properties may be rejected for fresh object literals but accepted through variables.
- Classes with private or protected members have nominal-like compatibility for those members.

## Official Docs

- More on Functions: https://www.typescriptlang.org/docs/handbook/2/functions.html
- Object Types: https://www.typescriptlang.org/docs/handbook/2/objects.html
- Classes: https://www.typescriptlang.org/docs/handbook/2/classes.html
- Type Compatibility: https://www.typescriptlang.org/docs/handbook/type-compatibility.html
- Mixins: https://www.typescriptlang.org/docs/handbook/mixins.html
- Decorators: https://www.typescriptlang.org/docs/handbook/decorators.html
