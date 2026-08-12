# Linking and SDK

Resource linking connects infrastructure definitions to runtime code without hardcoding IDs.

Default in this skill: show Cloudflare linking examples first.

## Basic Flow

1. Create resource in `sst.config.ts`.
2. Pass it in `link` for the target function/frontend/service/worker.
3. Access it in runtime via SST SDK.

```ts
const bucket = new sst.cloudflare.Bucket("MyBucket");
new sst.cloudflare.Worker("Api", {
  handler: "./index.ts",
  link: [bucket],
  url: true,
});
```

```ts
import { Resource } from "sst";
console.log(Resource.MyBucket.name);
```

## Local Development

- Links are injected on `sst dev` and `sst deploy`.
- In multiplexer mode, `sst dev` starts child processes and injects links for them.
- In basic mode, wrap local commands, for example `sst dev -- next dev`.
- Frontend links are server-side only; pass values to client code explicitly.

## Type Generation

- SST generates `sst-env.d.ts` types for linked resources.
- Keep generated types committed if your team wants autocomplete without running dev first.

## Language Support

- JS/TS: `import { Resource } from "sst"`.
- Python: `from sst import Resource`.
- Go: `resource.Get("MyBucket", "name")`.
- Rust: `Resource::init()` then typed `resource.get(...)`.

Client helper modules are richer in JS/TS; other SDKs mainly expose resource lookups.

## Extending Links

Use `sst.Linkable` or `sst.Linkable.wrap` to expose custom properties from non-SST resources and control permissions.

This is the preferred bridge when integrating external provider resources.

If AWS is explicitly requested, use the same `link` pattern with `sst.aws.*` components.
