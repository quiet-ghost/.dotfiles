# Version Notes

Use this when behavior may depend on the installed TypeScript version or when advice involves recent syntax and compiler flags.

## Contents

- Version-first workflow
- When versions matter
- Release-note usage
- Compatibility checks
- Official links

## Version-First Workflow

1. Inspect the local `typescript` version.
2. Check the repo's package manager and lockfile before assuming upgrades are allowed.
3. Read release notes for features or diagnostics near that version.
4. Prefer syntax supported by the local compiler and the repo's runtime/toolchain.
5. If recommending an upgrade, state why and what behavior changes may matter.

## When Versions Matter

Version can affect:

- New syntax support.
- Narrowing and inference behavior.
- Module resolution modes and defaults.
- Decorator behavior and emit.
- JSX and React typing behavior.
- Standard library declarations.
- New strictness flags or diagnostics.
- Performance for complex type programs.

## Common Version-Sensitive Features

- `satisfies` operator: useful for validating object shape while preserving literal inference.
- `const` type parameters: preserve literal inference in generic APIs.
- Modern decorators: different from legacy experimental decorators.
- `moduleResolution: "Bundler"`: matches many bundler workflows better than Node resolution.
- `verbatimModuleSyntax`: makes import/export emit behavior more explicit.
- New `lib` declarations: can change DOM, iterator, promise, and runtime API types.

Always confirm the feature exists in the installed compiler before using it in code.

## Release-Note Usage

Use release notes to answer:

- Why did this code start erroring after a TypeScript upgrade?
- Is this syntax available in this repo?
- Did narrowing or inference behavior change?
- Is this compiler option supported?
- Does this flag replace older recommendations?

## Compatibility Checks

- TypeScript version: `npx tsc --version`
- Effective config: `npx tsc --showConfig`
- Installed library types: inspect `node_modules/<pkg>` and `@types/<pkg>`.
- Framework support: check the framework's documented TypeScript range.
- Editor mismatch: ensure editor TypeScript version matches workspace version when diagnostics differ.

## Upgrade Guardrails

- Do not upgrade TypeScript just to use a nicer type unless the user asks or the existing version blocks the task.
- Read release notes across every skipped minor version for large jumps.
- Run the full typecheck after compiler upgrades.
- Expect new errors from stricter standard library declarations or improved inference.
- Avoid changing module settings and TypeScript version in the same patch unless required.

## Official Release Notes

- TypeScript 6.0: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html
- TypeScript 5.9: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-9.html
- TypeScript 5.8: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-8.html
- TypeScript 5.7: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-7.html
- TypeScript 5.6: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-6.html
- TypeScript 5.5: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-5.html
- TypeScript 5.4: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-4.html
- TypeScript 5.3: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-3.html
- TypeScript 5.2: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-2.html
- TypeScript 5.1: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-1.html
- TypeScript 5.0: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-0.html
- Full release notes list: https://www.typescriptlang.org/docs/handbook/release-notes/overview.html
