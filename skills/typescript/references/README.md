# TypeScript Overview

TypeScript is a static typechecker for JavaScript. It checks programs before they run, but the emitted JavaScript still follows JavaScript runtime semantics.

## Contents

- Working model
- Default workflow
- Learning path
- Official source map
- Local version checks

## Working Model

- TypeScript adds types to JavaScript; it does not replace JavaScript.
- Types are erased at runtime unless a tool transforms syntax for a feature such as enums or namespaces.
- Type safety is strongest inside trusted code and weakest at untyped boundaries.
- TypeScript uses structural typing: compatibility depends on shape, not declared nominal identity.
- Inference is a feature. Add annotations where they improve API boundaries, intent, or diagnostics.
- The compiler can prove many relationships, but it cannot prove runtime data shape without validation code.

## Default Workflow

1. Read `package.json` and `tsconfig*.json` before changing TypeScript behavior.
2. Identify the local `typescript` version, framework typecheck command, and module system.
3. Reproduce the exact type error or behavior with the smallest command.
4. Prefer language-level fixes over assertions.
5. Use official docs or local compiler/types when syntax, flags, or resolution behavior matters.
6. Verify with the smallest relevant typecheck or test.

## Learning Path

1. Handbook intro and basics: what TypeScript checks and what it does not check.
2. Everyday types: primitives, arrays, objects, unions, literals, `null`, and `undefined`.
3. Narrowing: control-flow analysis, discriminated unions, and exhaustive checks.
4. Functions and object types: callbacks, overloads, generics, readonly, and index signatures.
5. Type manipulation: `keyof`, `typeof`, indexed access, conditional, mapped, and template literal types.
6. Modules and tsconfig: TypeScript must match the runtime or bundler's module behavior.
7. Declaration files and JS migration: how TypeScript describes untyped JavaScript.

## Handbook vs Reference

- Use the Handbook for concepts and everyday language behavior.
- Use Reference pages for deeper, isolated topics such as type compatibility, inference, enums, decorators, and declaration merging.
- Use TSConfig reference for compiler option semantics.
- Use release notes for behavior that changed across TypeScript versions.
- Use source and installed `.d.ts` files for exact library signatures.

## Local Version Checks

- Prefer project scripts such as `npm run typecheck`, `pnpm typecheck`, `bun run typecheck`, or `yarn typecheck`.
- Use `npx tsc --version` or the package manager equivalent when no script exists.
- Use `npx tsc --showConfig` to inspect the effective compiler config.
- Use `npx tsc --noEmit --pretty false` for a plain compiler check.
- Use `npx tsc --traceResolution` only for module-resolution diagnostics; it can be noisy.

## Official Source Map

| Need | Official Source |
|------|-----------------|
| Handbook entry | https://www.typescriptlang.org/docs/handbook/intro.html |
| Docs index | https://www.typescriptlang.org/docs/ |
| Playground | https://www.typescriptlang.org/play |
| TSConfig reference | https://www.typescriptlang.org/tsconfig/ |
| Compiler options | https://www.typescriptlang.org/docs/handbook/compiler-options.html |
| Modules reference | https://www.typescriptlang.org/docs/handbook/modules/reference.html |
| Declaration files | https://www.typescriptlang.org/docs/handbook/declaration-files/introduction.html |
| GitHub source | https://github.com/microsoft/TypeScript |
| Website source | https://github.com/microsoft/TypeScript-Website |

## Key Docs

- Handbook intro: https://www.typescriptlang.org/docs/handbook/intro.html
- The Basics: https://www.typescriptlang.org/docs/handbook/2/basic-types.html
- Everyday Types: https://www.typescriptlang.org/docs/handbook/2/everyday-types.html
- Narrowing: https://www.typescriptlang.org/docs/handbook/2/narrowing.html
- Type Inference: https://www.typescriptlang.org/docs/handbook/type-inference.html
- Type Compatibility: https://www.typescriptlang.org/docs/handbook/type-compatibility.html
