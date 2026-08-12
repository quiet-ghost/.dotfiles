# Modules and Interop

Use this for ESM/CJS, `module`, `moduleResolution`, package exports, path aliases, import syntax, and module-related compiler errors.

## Contents

- Runtime-first model
- Common settings
- NodeNext vs Bundler
- Type-only imports
- Path aliases
- Debugging
- Official docs

## Runtime-First Model

TypeScript must describe the module system that will run the JavaScript.

Before changing module config, inspect:

- `package.json` `type`, `exports`, `imports`, and `main` fields.
- Bundler or runtime: Node, Bun, Deno, Vite, Next.js, ts-node, tsx, Jest, Vitest, or a library build tool.
- Existing `module`, `moduleResolution`, `target`, `verbatimModuleSyntax`, `esModuleInterop`, and `allowSyntheticDefaultImports`.

## Common Settings

- `module`: emit or module analysis mode.
- `moduleResolution`: how imports are resolved.
- `baseUrl` and `paths`: compile-time resolution hints, not runtime rewrites by themselves.
- `rootDir` and `outDir`: source and output layout.
- `resolveJsonModule`: allow importing JSON with types.
- `allowImportingTsExtensions`: allow `.ts` import specifiers in constrained no-emit workflows.

## NodeNext vs Bundler

Use `moduleResolution: "NodeNext"` when TypeScript should match Node's ESM/CJS rules.

Use `moduleResolution: "Bundler"` when a bundler owns resolution and supports extensionless or transformed imports.

Do not switch between these to silence errors without checking runtime behavior. The wrong setting can typecheck code that fails at runtime or reject code the bundler supports.

## Type-Only Imports

Use `import type` for imports used only in type positions, especially with `verbatimModuleSyntax`.

```ts
import type { User } from "./user"
import { parseUser } from "./user"
```

Benefits:

- Clear runtime dependency graph.
- Better compatibility with strict module emit.
- Fewer accidental side effects.

## ESM/CJS Interop

Interop depends on compiler settings, runtime, and package shape.

- `esModuleInterop` changes helper emit and default import compatibility for CommonJS.
- `allowSyntheticDefaultImports` affects typechecking but not emit by itself.
- A package can expose different types through `exports` conditions.
- Some default imports typecheck in a bundler but fail in plain Node.

Prefer matching the repo's runtime and official module guide over trial-and-error config changes.

## Path Aliases

`paths` helps TypeScript resolve imports. It does not automatically teach Node how to resolve them.

If using aliases, ensure runtime support through the framework, bundler, loader, or package exports.

## Debugging

- `tsc --showConfig`: confirm effective config.
- `tsc --traceResolution`: inspect how a specifier resolves.
- Check whether an import is type-only or runtime.
- Check emitted JS when runtime behavior differs from typechecking.
- Check package `exports` and generated `.d.ts` files.

## Official Docs

- Modules intro: https://www.typescriptlang.org/docs/handbook/modules/introduction.html
- Modules theory: https://www.typescriptlang.org/docs/handbook/modules/theory.html
- Modules reference: https://www.typescriptlang.org/docs/handbook/modules/reference.html
- Choosing compiler options: https://www.typescriptlang.org/docs/handbook/modules/guides/choosing-compiler-options.html
- ESM/CJS interop appendix: https://www.typescriptlang.org/docs/handbook/modules/appendices/esm-cjs-interop.html
