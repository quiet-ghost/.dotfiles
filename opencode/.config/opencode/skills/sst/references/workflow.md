# Workflow and CLI

Use the SST CLI to iterate safely from local development to production deploys.

Default provider assumption in this skill is Cloudflare unless AWS is explicitly requested.

## Core Commands

| Command | Use |
|--------|-----|
| `sst init` | Initialize SST in a project |
| `sst dev` | Local dev mode with infra watcher and linked resources |
| `sst diff` | Preview infra changes before deploy |
| `sst deploy --stage <stage>` | Deploy to a specific stage |
| `sst remove --stage <stage>` | Remove a stage intentionally |
| `sst add <provider>` | Add and install a provider |
| `sst install` | Install providers defined in config |
| `sst secret ...` | Manage `sst.Secret` values |
| `sst shell [cmd]` | Run commands with linked env/resources |
| `sst refresh` | Sync state with cloud reality (state-only update) |
| `sst state ...` | Export/repair/edit app state metadata |
| `sst unlock` | Clear stale deploy lock |
| `sst diagnostic` | Generate debug bundle in `.sst/` |

## Global Flags

- `--stage`: set environment namespace explicitly.
- `--verbose` and `--print-logs`: increase local/CI visibility.
- `--config`: run commands against non-default config paths.

Equivalent env vars include `SST_STAGE` and `SST_PRINT_LOGS`.

## Dev Modes

- `sst dev` (default `multi`): tabbed multiplexer with child processes.
- `sst dev --mode=mono`: one log stream with child processes.
- `sst dev --mode=basic`: infra + functions only; manually wrap frontend commands.

## Safe Deploy Sequence

1. Run `sst diff --stage <stage>`.
2. Review create/update/delete changes.
3. Deploy with `sst deploy --stage <stage>`.
4. Confirm outputs and smoke-test endpoints.
5. For prod, use explicit stage and avoid personal-stage deploys.

## Team Pattern

- Each developer works in a personal stage with `sst dev`.
- Shared branches deploy to shared stages (`dev`, `staging`, `production`).
- PR stages can map to `pr-<number>` and be auto-removed on merge/close.
- Configure this with Console autodeploy or your CI pipeline.
