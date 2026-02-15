# Start Guides

Practical entry points for common SST setups.

Default in this skill: use the Cloudflare path unless AWS is explicitly requested.

## AWS + Next.js (optional)

1. Create app:

```bash
npx create-next-app@latest my-app
cd my-app
npx sst@latest init
```

2. Choose AWS during init and start dev:

```bash
npx sst dev
```

3. Minimal `sst.config.ts` pattern:

```ts
/// <reference path="./.sst/platform/config.d.ts" />
export default $config({
  app(input) {
    return {
      name: "my-app",
      home: "aws",
      removal: input?.stage === "production" ? "retain" : "remove",
    };
  },
  async run() {
    const bucket = new sst.aws.Bucket("Uploads");
    new sst.aws.Nextjs("Web", { link: [bucket] });
    return { web: "deployed" };
  },
});
```

4. Deploy shared stage:

```bash
npx sst deploy --stage production
```

## Cloudflare Worker + R2 (default)

1. Initialize project:

```bash
mkdir my-worker && cd my-worker
npm init -y
npx sst@latest init
npm install
```

2. Choose Cloudflare during init and set credentials:

```bash
export CLOUDFLARE_API_TOKEN=...
export CLOUDFLARE_DEFAULT_ACCOUNT_ID=...
```

3. Minimal `sst.config.ts` pattern:

```ts
/// <reference path="./.sst/platform/config.d.ts" />
export default $config({
  app() {
    return { name: "my-worker", home: "cloudflare" };
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
});
```

4. Run local dev and deploy:

```bash
npx sst dev
npx sst deploy --stage production
```

## When to Choose Which

- Choose Cloudflare path by default for edge-first Worker workloads with KV/D1/R2.
- Choose AWS path only if your app relies on AWS-native components (`Nextjs`, `Function`, `Dynamo`, `Postgres`, `Queue`) or explicitly asks for AWS.
- Mixed-provider apps are possible; configure additional providers in `app().providers`.
