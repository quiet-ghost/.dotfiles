# Setup and TSConfig

Use this when installing TypeScript, reading `tsconfig.json`, changing compiler flags, or debugging project references.

## Contents

- Config inspection
- Strictness baseline
- Emit and build modes
- Project references
- Diagnostic commands
- Official docs

## Config Inspection

1. Read `package.json` scripts and dependencies.
2. Read all relevant `tsconfig*.json` files, including `extends` chains.
3. Identify framework-specific configs: `tsconfig.app.json`, `tsconfig.node.json`, `tsconfig.build.json`, `jsconfig.json`, or monorepo package configs.
4. Use `tsc --showConfig` to inspect the final merged config when behavior is unclear.
5. Avoid broad compiler-option migrations unless the user requested them.

## Strictness Baseline

For new TypeScript code, prefer `strict: true` unless a framework template has a clear reason not to.

High-value safety flags:

- `strict`: enables the core strict family.
- `noImplicitOverride`: catches accidental method override drift.
- `noUncheckedIndexedAccess`: makes indexed access account for missing values.
- `exactOptionalPropertyTypes`: distinguishes absent optional properties from explicit `undefined`.
- `noFallthroughCasesInSwitch`: catches unintentional fallthrough.
- `noPropertyAccessFromIndexSignature`: keeps index-signature access explicit.

Migration rule: enable strictness incrementally. Do not flip stricter flags across a large legacy repo unless the task is a migration.

## Target, Lib, and Types

- `target` controls emitted JavaScript syntax level.
- `lib` controls available global APIs such as `dom`, `es2023`, or `webworker`.
- `types` narrows included global type packages. If set, only listed `@types/*` packages are included globally.
- `skipLibCheck` skips typechecking declaration files. It can reduce noise, but it can hide dependency type conflicts.

## Emit and Build Modes

- Use `noEmit: true` when another tool handles output.
- Use `declaration: true` for libraries that publish types.
- Use `emitDeclarationOnly: true` when JS is built by another compiler but `.d.ts` output is needed.
- Use `sourceMap` or `declarationMap` when debugging emitted code or library types.
- Use `incremental` for faster repeated builds.
- Use `composite` for project references.

## Project References

Use project references for multi-package or multi-project builds where TypeScript should understand dependency boundaries.

Project reference requirements:

- Referenced projects need `composite: true`.
- Build with `tsc -b` for reference-aware ordering.
- Keep public API boundaries clean; downstream projects consume emitted declarations.
- If errors mention stale output, clean generated build info and declaration output using the repo's normal clean command.

## Diagnostic Commands

- Effective config: `npx tsc --showConfig`
- Typecheck only: `npx tsc --noEmit --pretty false`
- Build references: `npx tsc -b`
- Explain included files: `npx tsc --explainFiles`
- Debug module resolution: `npx tsc --traceResolution`
- List compiler options: `npx tsc --help --all`

Prefer package-manager equivalents (`pnpm exec`, `bunx`, `yarn tsc`) that match the repo.

## Official Docs

- What is `tsconfig.json`: https://www.typescriptlang.org/docs/handbook/tsconfig-json.html
- TSConfig reference: https://www.typescriptlang.org/tsconfig/
- Compiler options: https://www.typescriptlang.org/docs/handbook/compiler-options.html
- Project references: https://www.typescriptlang.org/docs/handbook/project-references.html
- Choosing compiler options: https://www.typescriptlang.org/docs/handbook/modules/guides/choosing-compiler-options.html
- Integrating with build tools: https://www.typescriptlang.org/docs/handbook/integrating-with-build-tools.html
