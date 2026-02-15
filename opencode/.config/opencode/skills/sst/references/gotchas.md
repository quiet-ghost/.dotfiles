# Gotchas

Common SST mistakes and practical fixes.

## High-Impact Mistakes

| Mistake | Why it hurts | Fix |
|--------|---------------|-----|
| Changing `app.name` casually | Creates a new app footprint and leaves old resources | Remove old app/stage deliberately before rename |
| Renaming stage/region without plan | Creates parallel resources in new namespace | Treat rename as migrate: deploy new, cut over, remove old |
| Manual edits in cloud console | State and real infra drift apart | Keep infra changes in `sst.config.ts`; run `sst refresh` only when needed |
| Deleting SST state storage | SST loses resource ownership tracking | Never delete state backend buckets/tables manually |
| Running `sst remove` on wrong stage | Permanent resource deletion risk | Use explicit `--stage`, `protect`, and cautious `removal` policy |
| Forgetting `sst install` after provider changes | Missing provider packages and failures | Run `sst install` after provider edits/pulls |
| Missing Cloudflare credentials in shell/CI | Cloudflare deploys fail before planning resources | Set `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_DEFAULT_ACCOUNT_ID` for the stage |

## Linking Pitfalls

- Frontend-linked resources are server-side only.
- If using `sst dev --mode=basic`, wrap your frontend command with `sst dev -- <cmd>`.
- Missing `link` means `Resource.<Name>` access will fail at runtime.

## Component Pitfalls

- Component names should stay stable; rename can trigger replacement.
- Some frontends can hit CloudFront cache behavior limits if too many top-level static paths.
- `sst dev` does not deploy frontends/services that run locally in dev mode.

## State and Recovery Tips

- `sst unlock` fixes stale deployment locks after interrupted deploys.
- `sst state repair` can recover ordering/dependency issues in corrupted state.
- `sst diagnostic` creates a bundle for issue reporting/debugging.

## CI and Scale Tips

- Use explicit stage names in CI.
- Tune deploy build concurrency via:
  - `SST_BUILD_CONCURRENCY_SITE`
  - `SST_BUILD_CONCURRENCY_FUNCTION`
  - `SST_BUILD_CONCURRENCY_CONTAINER`
- Use `--print-logs` in CI to surface logs in job output.
