# Configuration

Use `sst.config.ts` to define app settings and resources.

## Canonical Shape

```ts
/// <reference path="./.sst/platform/config.d.ts" />
export default $config({
  app(input) {
    return {
      name: "my-sst-app",
      home: "cloudflare",
      providers: {
        cloudflare: {
          accountId: process.env.CLOUDFLARE_DEFAULT_ACCOUNT_ID!,
        },
      },
      protect: input.stage === "production",
      removal: input.stage === "production" ? "retain" : "remove",
    };
  },
  async run() {
    const bucket = new sst.cloudflare.Bucket("Assets");
    const worker = new sst.cloudflare.Worker("Api", {
      handler: "./index.ts",
      link: [bucket],
      url: true,
    });
    return { api: worker.url };
  },
  console: {
    autodeploy: {},
  },
});
```

## Rules

- Define components only in `run()`, not in `app()`.
- `app()` returns config and can branch by `input.stage`.
- Avoid direct imports of provider packages in `sst.config.ts`.
- Use `providers` to pin versions or configure provider settings.
- Return outputs from `run()` for CLI visibility and `.sst/outputs.json`.

## Provider Default Rule

- Assume Cloudflare unless the task explicitly asks for AWS or requires AWS-only components.
- Cloudflare-first means `home: "cloudflare"` and `sst.cloudflare.*` in new examples.
- Keep AWS as an explicit option, not the default.

## AWS Optional Variant

When AWS is required, switch `home` and component namespace intentionally:

```ts
app(input) {
  return {
    name: "my-sst-app",
    home: "aws",
    providers: { aws: { region: "us-west-2" } },
    protect: input.stage === "production",
    removal: input.stage === "production" ? "retain" : "remove",
  };
}
```

## Important Fields

| Field | Why it matters |
|------|----------------|
| `name` | Namespaces resources; changing it creates a new app footprint |
| `home` | Where SST stores state (`aws`, `cloudflare`, or `local`) |
| `providers` | Enables provider resources and provider-specific config |
| `protect` | Blocks accidental `sst remove` on protected stages |
| `removal` | Controls resource retention during remove/replacement |
| `version` | Pins SST CLI compatibility, useful in CI |

## Stage Behavior

- Stage comes from `--stage` or `SST_STAGE`.
- If omitted, SST uses a personal stage (typically machine username).
- Renaming a stage means creating a new stage and removing the old one.
- Use explicit stage names in CI and production operations.

## Environment Files

- `.env` and `.env.<stage>` are loaded from config directory.
- Values are available via `process.env` in `app()` and `run()`.
- `.env` takes precedence over `.env.<stage>`.
- Restart `sst dev` after env file changes.

## Console Autodeploy

`console.autodeploy` can customize:

- `target(event)` to map git events to stages.
- `runner(stage)` to choose build machine settings.
- `workflow({ $, event })` to customize build/deploy commands.

Use this when you need branch-to-stage policies, pre-deploy tests, or custom pipelines.
