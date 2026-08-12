# Components

Choose components based on the feature you are building, then configure and link them.

Default in this skill: prefer Cloudflare components first, then use AWS components when requested.

## Fast Selection Tree

```text
Need a web frontend?
├─ Cloudflare edge app (default) -> sst.cloudflare.Worker
├─ AWS serverless framework hosting (optional) -> sst.aws.Nextjs/Remix/Astro/SvelteKit/SolidStart
└─ Static assets/site (AWS) -> sst.aws.StaticSite

Need backend compute?
├─ Cloudflare edge compute (default) -> sst.cloudflare.Worker
├─ Lambda-style function (AWS) -> sst.aws.Function
├─ Containerized service (AWS) -> sst.aws.Service (+ sst.aws.Cluster, often sst.aws.Vpc)
└─ Scheduled job (AWS) -> sst.aws.Cron

Need data/storage?
├─ Object storage (default) -> sst.cloudflare.Bucket (R2)
├─ Relational DB (default) -> sst.cloudflare.D1
├─ Key-value (default) -> sst.cloudflare.Kv
├─ Object/relational/queue on AWS (optional) -> sst.aws.Bucket / Postgres / Mysql / Aurora / Queue / Bus / SnsTopic
└─ AWS NoSQL (optional) -> sst.aws.Dynamo
```

## Composition Patterns

- Worker + R2/KV/D1: `sst.cloudflare.Worker` with `link` to storage.
- API + data (AWS): `Function` + `Dynamo`/`Postgres`, linked with `link`.
- Web + API: frontend component + linked backend resources.
- Service workloads: `Vpc` -> `Cluster` -> `Service`; link data resources.

## Naming Guidance

- Component names should be unique across the app.
- Prefer PascalCase names for easier `Resource.MyName` access.
- Renaming components usually causes replacement; plan for migration/downtime.

## Transform and Defaults

Use component `transform` to customize low-level resources (IAM role, log group, etc.).

Use global `$transform` to apply defaults across future components, for example runtime defaults for all functions.

## Deep API References

Use the SST docs component pages for exact args/options:
- `/docs/component/aws/<component>/`
- `/docs/component/cloudflare/<component>/`
