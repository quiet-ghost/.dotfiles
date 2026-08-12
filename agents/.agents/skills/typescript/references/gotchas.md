# Gotchas and Diagnostics

Use this when TypeScript behavior is surprising, compiler errors are unclear, or a quick fix might reduce type safety.

## Contents

- Unsafe escape hatches
- Inference traps
- Nullish and optional traps
- Object and array traps
- Function and class traps
- Module traps
- Debug workflow

## Unsafe Escape Hatches

Problem patterns:

- `any` spreads through assignments, returns, and generics.
- `value!` hides missing null checks.
- `{} as T` creates a value that may not satisfy `T` at runtime.
- `as unknown as T` bypasses compatibility checks.
- `@ts-ignore` hides future unrelated errors on the next line.

Safer fixes:

- Parse or narrow `unknown`.
- Change the model to represent missing state.
- Use `satisfies` for object-shape checks.
- Use `@ts-expect-error` only when testing or documenting an intentional error.

## Inference Traps

- Empty arrays can infer too narrowly depending on context.
- Object literals widen unless constrained with context, `satisfies`, or `as const`.
- Generic inference follows usage positions; adding explicit type arguments can hide a bad API design.
- `Promise<T>` and `T | Promise<T>` can require `Awaited<T>` in helper types.
- Complex conditional types can distribute over unions unless wrapped in tuples.

## Nullish and Optional Traps

- Truthiness checks reject valid `""`, `0`, and `false` values.
- Optional properties are not the same as required properties with `undefined` values.
- Optional chaining narrows only the expression it is used on.
- `strictNullChecks` changes the meaning of many common APIs.
- `noUncheckedIndexedAccess` makes array and dictionary access return possibly undefined values.

## Object and Array Traps

- Excess property checks apply most strongly to fresh object literals.
- `Object.keys` returns `string[]`, not `(keyof T)[]`, because runtime objects can have extra keys.
- Index signatures make all matching property accesses conform to the index value type.
- `Record<string, T>` means any string key is accepted; use key unions for closed maps.
- Spreads can widen types or override discriminants in subtle ways.

## Function and Class Traps

- Optional callback parameters mean the callback may be called without that argument.
- Overloads must be represented by an implementation signature that can handle every overload.
- Methods and function properties have different variance behavior in some compatibility checks.
- `private` is TypeScript-only unless using ECMAScript `#private` fields.
- Class types describe instances; `typeof MyClass` describes the constructor/static side.

## Module Traps

- `paths` does not rewrite runtime imports by itself.
- `allowSyntheticDefaultImports` can typecheck imports that do not work in the runtime.
- `moduleResolution` must match the runtime or bundler.
- `type` in `package.json` changes whether `.js` files are ESM or CommonJS in Node.
- Generated declarations can expose wrong paths if package exports are misconfigured.

## Debug Workflow

1. Read the exact compiler diagnostic and related spans.
2. Check the local TypeScript version and effective `tsconfig`.
3. Reduce the problem to the smallest expression or type relationship.
4. Inspect inferred types in the editor or by assigning to named types.
5. Prefer a modeling or narrowing fix over an assertion.
6. Verify no unsafe escape hatch was introduced.

## Useful Commands

- `npx tsc --noEmit --pretty false`
- `npx tsc --showConfig`
- `npx tsc --explainFiles`
- `npx tsc --traceResolution`

## Official Docs

- Narrowing: https://www.typescriptlang.org/docs/handbook/2/narrowing.html
- Type Inference: https://www.typescriptlang.org/docs/handbook/type-inference.html
- Type Compatibility: https://www.typescriptlang.org/docs/handbook/type-compatibility.html
- Modules reference: https://www.typescriptlang.org/docs/handbook/modules/reference.html
- Declaration Do's and Don'ts: https://www.typescriptlang.org/docs/handbook/declaration-files/do-s-and-don-ts.html
