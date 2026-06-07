# Config and Observability

Use this for configuration, redaction, logs, metrics, tracing, and supervisors.

## Config Basics

Effect `Config` loads typed configuration, usually from environment variables by default.

Common primitives:

- `Config.string("NAME")`
- `Config.int("PORT")`
- `Config.number("LIMIT")`
- `Config.boolean("DEBUG")`
- `Config.duration("TIMEOUT")`
- `Config.url("BASE_URL")`
- `Config.redacted("API_KEY")`
- `Config.schema(schema, "NAME")`

Prefer `Config.schema` for validation and brands.

## Config Service Pattern

Create a config service layer so business logic depends on typed config, not env vars.

```ts
import { Config, Effect, Layer, Redacted, Schema } from "effect"
import * as Context from "effect/Context"

class ApiConfig extends Context.Service<
  ApiConfig,
  {
    readonly apiKey: Redacted.Redacted
    readonly baseUrl: URL
    readonly timeout: Duration.Duration
  }
>()("@app/ApiConfig") {
  static readonly layer = Layer.effect(
    ApiConfig,
    Effect.gen(function* () {
      const apiKey = yield* Config.redacted("API_KEY")
      const baseUrl = yield* Config.url("API_BASE_URL")
      const timeout = yield* Config.duration("API_TIMEOUT")
      return { apiKey, baseUrl, timeout }
    })
  )
}
```

Adjust imports and types to installed version. Some projects keep `Duration` values as plain config strings or numbers; preserve local conventions when appropriate.

## Config Providers

Use `ConfigProvider.layer` to replace config sources in tests or special runtimes.

For tests, often simpler: provide the config service directly with `Layer.succeed`.

## Secrets

- Use `Config.redacted` or `Schema.Redacted` for secrets.
- Do not log raw secret values.
- Extract a redacted value only at the last boundary that needs the raw secret.
- Keep secret-bearing error messages generic.

## Logging

Use Effect logging APIs so logs carry fiber, span, and annotation context.

Common APIs:

- `Effect.log`
- `Effect.logInfo`
- `Effect.logWarning`
- `Effect.logError`
- `Effect.annotateLogs` where available
- `Logger` layers for runtime logger selection

Avoid raw `console.log` inside business effects unless the project intentionally uses it.

## Tracing

Use spans around externally meaningful operations.

```ts
const program = callExternalApi.pipe(
  Effect.withSpan("ExternalApi.call")
)
```

If using `Effect.fn`, check whether it automatically adds spans/tracing in the installed version.

Add span attributes or log annotations for ids, operation names, provider names, and retry attempts, but not secrets.

## Metrics

Use metrics for production behavior, not logs alone.

Track:

- Request counts and failures by operation.
- Latency histograms.
- Queue depth and processing lag.
- Cache hits/misses.
- Retry attempts.
- Resource pool saturation.

Verify metric constructors and label APIs against installed types.

## Supervisors

Supervisors observe fibers and are useful for debugging, diagnostics, and runtime monitoring.

Use when:

- Background fibers fail or leak.
- Concurrency behavior is unclear.
- You need runtime-level visibility.

## Devtools

Effect devtools can help inspect fibers and traces. Add only when useful for the project and compatible with the installed Effect version.

## Smells

- Business code reads `process.env` directly.
- Secrets appear in logs, spans, metrics labels, snapshots, or errors.
- Config parsed as strings and validated later.
- Logs lack operation identifiers.
- Metrics labels contain unbounded user input.
- Raw `console` calls bypass Effect logging context.
