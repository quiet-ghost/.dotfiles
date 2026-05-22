# SST Overview

SST is a framework for building full-stack apps where infrastructure and app features are defined in code, usually in one `sst.config.ts`.

## Mental Model

- `app(input)` defines app-level settings (name, home provider, providers, stage policies).
- `run()` defines resources and returns optional outputs.
- Components are high-level building blocks (`sst.aws.*`, `sst.cloudflare.*`).
- `link` connects infrastructure to runtime code via the SST SDK.
- State tracks deployed resources; SST uses it to compute diffs and apply updates safely.

## Default Workflow

1. `sst init` (or add SST to an existing project).
2. Edit `sst.config.ts`.
3. Run `sst dev` for local development on a personal stage.
4. Run `sst diff` to inspect planned changes.
5. Run `sst deploy --stage <stage>` to deploy shared/prod environments.
6. Use `sst remove --stage <stage>` only when intentionally tearing down a stage.

## Provider Strategy

- Default to built-in Cloudflare components for Worker/R2/KV/D1 workloads.
- Use built-in AWS components when explicitly requested or when Cloudflare cannot satisfy requirements.
- Add extra providers in `providers` when needed for non-built-in services.
- Do not manually import provider packages in `sst.config.ts`; SST manages this.

## Stage Strategy

- Personal stage: default stage for each developer's local `sst dev`.
- Shared stages: `dev`, `staging`, `production`, or `pr-*`.
- Explicit stage flags avoid accidental deploy/remove to the wrong environment.
- Use `protect` and `removal` for guardrails on important stages.

## Next File Routing

- Setup and starter recipes: [start-guides.md](./start-guides.md)
- App config and schema choices: [configuration.md](./configuration.md)
- Selecting components: [components.md](./components.md)
- Runtime access to resources: [linking-sdk.md](./linking-sdk.md)
- CLI and operations: [workflow.md](./workflow.md)
- Debugging and pitfalls: [gotchas.md](./gotchas.md)
