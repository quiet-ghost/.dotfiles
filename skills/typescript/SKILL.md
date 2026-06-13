---
name: typescript
description: Deep TypeScript language guidance for .ts, .tsx, .d.ts, tsconfig.json, tsc, strict mode, narrowing, generics, conditional/mapped/template literal types, modules, declaration files, and project references. Use when writing, reviewing, debugging, learning, or migrating TypeScript code.
references:
  - references/README.md
  - references/setup-tsconfig.md
  - references/official-reference-docs.md
  - references/best-practices.md
  - references/core-types-narrowing.md
  - references/type-manipulation.md
  - references/functions-objects-classes.md
  - references/modules-interop.md
  - references/declarations-js.md
  - references/version-notes.md
  - references/gotchas.md
---

# TypeScript

Use this skill for TypeScript language, type-system, compiler, module, declaration, and migration work.

## Critical Rules

- First inspect the local `typescript` version and project config before version-sensitive advice: `package.json`, lockfile, `tsconfig*.json`, and existing scripts.
- Treat TypeScript as a static typechecker for JavaScript. Separate runtime behavior from type-system behavior.
- Prefer official docs, local `node_modules/typescript`, and installed `.d.ts` files over memory when details matter.
- Preserve the repo's chosen framework, module system, target, lint rules, and style unless a migration is requested.
- Prefer strict, narrow types: `unknown` at boundaries, discriminated unions for states, exhaustive `never` checks, and runtime validation for untrusted data.
- Avoid unsafe escape hatches: `any`, non-null assertion, broad `as`, ambient globals, and enums by default. If unavoidable, localize and justify them.
- Do not confuse types with validation. Type annotations do not prove external JSON, env vars, CLI args, database rows, or API responses are valid.
- Verify changes with the smallest relevant `tsc --noEmit`, framework typecheck, test, or lint command.

## Quick Router

```text
Need TypeScript help?
|- Mental model, study path, official docs map -> README.md
|- Complete official TypeScript reference-doc index -> official-reference-docs.md
|- Install, tsconfig, compiler flags, project refs -> setup-tsconfig.md
|- Best practices, safe API design, boundary typing -> best-practices.md
|- Everyday types, unions, literals, narrowing, never -> core-types-narrowing.md
|- Generics, keyof, typeof, conditional/mapped/template types -> type-manipulation.md
|- Functions, objects, callbacks, classes, structural typing -> functions-objects-classes.md
|- ESM/CJS, moduleResolution, paths, imports/exports -> modules-interop.md
|- .d.ts, library types, JS migration, JSDoc -> declarations-js.md
|- Version-specific syntax, flags, release notes -> version-notes.md
|- Strange errors, inference traps, unsafe patterns -> gotchas.md
```

## Reading Order

| Task | Files to Read |
|------|---------------|
| Learn or explain TypeScript | [README.md](./references/README.md) -> [official-reference-docs.md](./references/official-reference-docs.md) -> topic file |
| Add or review code | [best-practices.md](./references/best-practices.md) -> [core-types-narrowing.md](./references/core-types-narrowing.md) -> topic file |
| Fix type errors | [gotchas.md](./references/gotchas.md) -> relevant topic file |
| Configure a project | [setup-tsconfig.md](./references/setup-tsconfig.md) -> [modules-interop.md](./references/modules-interop.md) |
| Design library/public API types | [functions-objects-classes.md](./references/functions-objects-classes.md) -> [type-manipulation.md](./references/type-manipulation.md) -> [declarations-js.md](./references/declarations-js.md) |
| Migrate JavaScript | [declarations-js.md](./references/declarations-js.md) -> [setup-tsconfig.md](./references/setup-tsconfig.md) -> [best-practices.md](./references/best-practices.md) |
| Debug modules or packages | [modules-interop.md](./references/modules-interop.md) -> [setup-tsconfig.md](./references/setup-tsconfig.md) -> [gotchas.md](./references/gotchas.md) |

## Primary Docs

- Handbook intro: https://www.typescriptlang.org/docs/handbook/intro.html
- Docs index: https://www.typescriptlang.org/docs/
- Handbook chapters: https://www.typescriptlang.org/docs/handbook/2/basic-types.html
- TSConfig reference: https://www.typescriptlang.org/tsconfig/
- `tsc` CLI options: https://www.typescriptlang.org/docs/handbook/compiler-options.html
- Modules reference: https://www.typescriptlang.org/docs/handbook/modules/reference.html
- Declaration files: https://www.typescriptlang.org/docs/handbook/declaration-files/introduction.html
- TypeScript GitHub: https://github.com/microsoft/TypeScript
- TypeScript website source: https://github.com/microsoft/TypeScript-Website

## In This Reference

| File | Purpose |
|------|---------|
| [README.md](./references/README.md) | TypeScript mental model, study path, official docs map |
| [official-reference-docs.md](./references/official-reference-docs.md) | Complete official TypeScript reference-doc index from typescriptlang.org |
| [setup-tsconfig.md](./references/setup-tsconfig.md) | `tsconfig.json`, compiler options, strictness, project references |
| [best-practices.md](./references/best-practices.md) | Safe typing defaults, API design, validation, maintainability |
| [core-types-narrowing.md](./references/core-types-narrowing.md) | Everyday types, unions, literals, control-flow narrowing, `never` |
| [type-manipulation.md](./references/type-manipulation.md) | Generics, indexed access, conditional, mapped, template literal, utility types |
| [functions-objects-classes.md](./references/functions-objects-classes.md) | Function, object, callback, class, and structural typing patterns |
| [modules-interop.md](./references/modules-interop.md) | ESM/CJS, module resolution, path aliases, package boundaries |
| [declarations-js.md](./references/declarations-js.md) | `.d.ts`, ambient types, JS projects, JSDoc, publishing types |
| [version-notes.md](./references/version-notes.md) | Release-note workflow and version-sensitive features |
| [gotchas.md](./references/gotchas.md) | Common traps, diagnostics, and fixes |
