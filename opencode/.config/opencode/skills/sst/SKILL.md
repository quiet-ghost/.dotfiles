---
name: sst
description: Cloudflare-first SST guidance for code-defined infrastructure, components, resource linking, and CLI workflows. Use when handling SST tasks; switch to AWS patterns only when explicitly requested.
references:
  - references/README.md
  - references/workflow.md
  - references/configuration.md
---

# SST Skill

Use this skill for SST v3+ architecture, implementation, deployment, and debugging.

## Core Principles

- Define infrastructure in code in `sst.config.ts`.
- Default to Cloudflare (`home: "cloudflare"` and `sst.cloudflare.*`) unless requirements explicitly need AWS.
- Prefer SST components first, then provider-level components when needed.
- Keep infrastructure code (`sst.config.ts`) and runtime code (app/functions) separate.
- Use explicit stages for shared environments and personal stages for local work.
- Run `sst diff` before impactful deploys.

## Quick Router

What are you trying to do?

```text
Need to start a project?
├─ Cloudflare Worker/edge app (default) -> references/start-guides.md
└─ AWS app (optional or explicit request) -> references/start-guides.md

Need to change app config?
├─ Cloudflare-first app name/stage/home/providers/removal/protect -> references/configuration.md
└─ env files, outputs, Console autodeploy config -> references/configuration.md

Need to add app features?
├─ Cloudflare Worker/KV/D1/R2 components (default) -> references/components.md
├─ Frontend/API/database/queues/cron components -> references/components.md
└─ Link infra into runtime code -> references/linking-sdk.md

Need to run or ship changes?
├─ local dev, deploy, diff, remove, secrets, state -> references/workflow.md
└─ team and preview environments -> references/workflow.md

Need to debug issues?
└─ common failures and safe recovery steps -> references/gotchas.md
```

## Working Style

1. Read `references/README.md` for context.
2. Route to the task-specific reference file.
3. Apply the smallest safe change in code.
4. Validate with relevant CLI commands from `references/workflow.md`.
5. If behavior is unclear, check the exact component/API docs linked in the reference files.

## Reading Order

| Task | Files to Read |
|------|---------------|
| New SST work | `references/README.md` -> `references/start-guides.md` |
| Update app config | `references/configuration.md` |
| Implement features | `references/components.md` -> `references/linking-sdk.md` |
| Deploy or operate | `references/workflow.md` |
| Troubleshoot failures | `references/gotchas.md` |

## In This Reference

| File | Purpose |
|------|---------|
| [README.md](./references/README.md) | SST mental model and baseline workflow |
| [start-guides.md](./references/start-guides.md) | Quickstart paths for AWS and Cloudflare |
| [configuration.md](./references/configuration.md) | `sst.config.ts`, stages, providers, env, outputs |
| [components.md](./references/components.md) | Component selection and composition patterns |
| [linking-sdk.md](./references/linking-sdk.md) | Resource linking and SDK usage |
| [workflow.md](./references/workflow.md) | CLI commands and deployment operations |
| [gotchas.md](./references/gotchas.md) | Common mistakes and fixes |

## Scope Notes

- Provider default is Cloudflare; AWS is opt-in.
- This skill focuses on practical SST implementation patterns, not exhaustive per-component API docs.
- For component-specific args, open the corresponding SST docs page from `references/components.md`.
- If a task depends on provider internals (Pulumi/Terraform specifics), treat SST abstractions as primary and provider docs as secondary.
