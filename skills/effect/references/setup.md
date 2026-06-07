# Setup

Use this when adding Effect to a project or fixing project configuration.

## Package Manager Rule

- Detect the existing package manager from lockfiles and scripts.
- Use the existing package manager for installs and commands.
- Do not switch module systems or package managers just for Effect.

## Core Packages

Common package set:

```bash
pnpm add effect
pnpm add @effect/platform @effect/platform-node
pnpm add -D vitest @effect/vitest @effect/language-service
```

For Bun apps, use the Bun platform package:

```bash
pnpm add effect @effect/platform @effect/platform-bun
```

Use `npm`, `yarn`, or `bun` equivalents if the project already uses them.

## TypeScript Baseline

Effect projects should be strict.

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "strict": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noUnusedLocals": true,
    "sourceMap": true,
    "skipLibCheck": true
  }
}
```

Generator syntax needs `target` of `ES2015` or newer, or `downlevelIteration`.

## Module Settings

Choose based on who emits JavaScript.

| Project Type | TypeScript Settings |
|--------------|---------------------|
| Bundled app | `module: "preserve"`, `moduleResolution: "bundler"`, `noEmit: true` |
| Node app, Bun app, CLI, library | `module: "NodeNext"` |
| Library emitting types | add `declaration: true`; monorepos often add `composite: true`, `declarationMap: true` |

With `NodeNext`, relative imports usually need `.js` in source imports. With bundler mode, the bundler resolves paths.

## Effect Language Service

Install:

```bash
pnpm add -D @effect/language-service
```

Add the plugin to `tsconfig.json`:

```json
{
  "$schema": "https://raw.githubusercontent.com/Effect-TS/language-service/refs/heads/main/schema.json",
  "compilerOptions": {
    "plugins": [
      { "name": "@effect/language-service" }
    ]
  }
}
```

Editors must use the workspace TypeScript version for plugins to load.

For build-time diagnostics, Effect Solutions recommends patching TypeScript:

```bash
pnpm exec effect-language-service patch
```

If used, persist it with a `prepare` script.

## Test Setup

Prefer `@effect/vitest` for Effect code.

```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest"
  }
}
```

Use `vitest`, not `bun test`, when tests depend on `@effect/vitest` helpers.

## Source and Docs Lookup

- Exact installed API: `node_modules/effect` and package `.d.ts` files.
- Official docs: https://effect.website/docs/
- Prescriptive guide: https://www.effect.solutions/
- Context7: `/websites/effect-ts_github_io_effect`
- Optional local source clone for deep lookup: `Effect-TS/effect` or the repository named by current Effect Solutions guidance.

## Setup Checklist

- `effect` installed and version known.
- Platform package installed only when runtime services are needed.
- `strict` TypeScript enabled.
- `exactOptionalPropertyTypes` enabled unless a dependency conflict blocks it.
- Language service plugin configured when project uses heavy Effect types.
- Test runner supports Effect tests.
- Entry point uses a platform runtime when graceful shutdown matters.
