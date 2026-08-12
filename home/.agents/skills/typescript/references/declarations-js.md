# Declaration Files and JavaScript Projects

Use this for `.d.ts` files, ambient declarations, library typing, JavaScript migration, `allowJs`, `checkJs`, and JSDoc.

## Contents

- Declaration files
- Ambient declarations
- Library publishing
- Declaration quality
- JavaScript migration
- JSDoc typing

## Declaration Files

Declaration files describe JavaScript shape to TypeScript. They do not implement runtime behavior.

Common sources:

- Generated declarations from TypeScript source.
- Handwritten declarations for JavaScript libraries.
- `@types/*` packages from DefinitelyTyped.
- Local ambient declarations for assets or globals.

Prefer generating `.d.ts` from source when maintaining a TypeScript library.

## Ambient Declarations

Ambient declarations should be narrow and intentional.

Examples:

- `declare module "*.css"`
- `declare module "virtual:generated"`
- `declare global { interface Window { ... } }`

Avoid using ambient declarations to paper over unresolved modules or missing runtime dependencies.

## Library Publishing

For packages that publish types:

- Verify `package.json` `types`, `exports`, and conditional type entries.
- Ensure emitted declarations match the package's public runtime entrypoints.
- Use `declarationMap` when source navigation matters.
- Test consuming the built package when changing package boundaries.
- Treat `.d.ts` as a public API artifact.

## Declaration Quality

- Do not use wrapper object types like `String`, `Number`, `Boolean`, or `Object` for normal values.
- Do not use optional callback parameters unless the callback may actually be called without them.
- Prefer unions over overloads when return type does not vary by input.
- Prefer precise object shapes over broad `{ [key: string]: unknown }` when keys are known.
- Avoid exposing private implementation types in public declarations.

## JavaScript Migration

Incremental migration options:

- `allowJs`: include JavaScript files in the program.
- `checkJs`: typecheck JavaScript files.
- `// @ts-check`: enable checking per JS file.
- JSDoc annotations: add types without converting to `.ts`.
- Generate declarations from JS when publishing typed JS packages.

Migration approach:

1. Turn on checking for a small scope.
2. Add JSDoc or convert the most valuable files first.
3. Fix boundaries before internals.
4. Avoid broad `any` comments that hide migration value.
5. Convert files when types become too complex for readable JSDoc.

## JSDoc Typing

Useful JSDoc tags:

- `@param`
- `@returns`
- `@typedef`
- `@template`
- `@satisfies`
- `@type`

Prefer JSDoc for typed JavaScript projects or gradual migrations. Prefer `.ts` when advanced type manipulation dominates the file.

## Official Docs

- Declaration files intro: https://www.typescriptlang.org/docs/handbook/declaration-files/introduction.html
- Declaration reference: https://www.typescriptlang.org/docs/handbook/declaration-files/by-example.html
- Library structures: https://www.typescriptlang.org/docs/handbook/declaration-files/library-structures.html
- Declaration Do's and Don'ts: https://www.typescriptlang.org/docs/handbook/declaration-files/do-s-and-don-ts.html
- Publishing declarations: https://www.typescriptlang.org/docs/handbook/declaration-files/publishing.html
- Consuming declarations: https://www.typescriptlang.org/docs/handbook/declaration-files/consumption.html
- JS projects using TypeScript: https://www.typescriptlang.org/docs/handbook/intro-to-js-ts.html
- Type checking JavaScript: https://www.typescriptlang.org/docs/handbook/type-checking-javascript-files.html
- JSDoc reference: https://www.typescriptlang.org/docs/handbook/jsdoc-supported-types.html
