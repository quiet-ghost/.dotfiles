# Services and Layers

Use this for dependency injection, app wiring, and testable architecture.

## Service Rules

- A service is a contract for a capability.
- A service tag identifies the contract in `Context`.
- A layer constructs a service implementation.
- Service methods should usually return effects with `R = never`.
- Dependencies needed to build a service belong in the layer, not in method signatures.
- Use readonly properties for service APIs.

## Context.Service Pattern

Effect Solutions prefers `Context.Service` where available.

```ts
import { Effect, Layer } from "effect"
import * as Context from "effect/Context"

class Users extends Context.Service<
  Users,
  {
    readonly findById: (id: UserId) => Effect.Effect<User, UserNotFound>
  }
>()("@app/Users") {
  static readonly layer = Layer.effect(
    Users,
    Effect.gen(function* () {
      const db = yield* Database

      const findById = Effect.fn("Users.findById")(function* (id: UserId) {
        return yield* db.findUser(id)
      })

      return { findById }
    })
  )
}
```

Verify `Context.Service` against the installed version. Older projects may use `Context.Tag` instead.

## Context.Tag Pattern

Use this when the project already uses tags or the installed version lacks `Context.Service`.

```ts
import { Effect, Context, Layer } from "effect"

class Users extends Context.Tag("@app/Users")<
  Users,
  {
    readonly findById: (id: UserId) => Effect.Effect<User, UserNotFound>
  }
>() {}

const UsersLive = Layer.effect(
  Users,
  Effect.gen(function* () {
    const db = yield* Database
    return Users.of({
      findById: (id) => db.findUser(id)
    })
  })
)
```

## Effect.Service Pattern

`Effect.Service` can bundle a tag and default layer. Use it when the service has an obvious default implementation and the installed version supports it. For service-driven development, `Context.Service` or `Context.Tag` is often easier because contracts can be sketched before implementations.

## Layer Composition

Common constructors:

- `Layer.succeed`: service from a pure value.
- `Layer.sync`: service from synchronous construction.
- `Layer.effect`: service from an effectful constructor.
- `Layer.scoped`: service from a scoped resource with finalization.
- `Layer.merge`: combine independent layers.
- `Layer.provide` / `Layer.provideMerge`: supply dependencies to a layer.

Compose once near the entrypoint:

```ts
const databaseLayer = Database.layer

const appLayer = Users.layer.pipe(
  Layer.provideMerge(databaseLayer),
  Layer.provideMerge(Config.layer)
)

const main = program.pipe(Effect.provide(appLayer))
```

## Layer Memoization

Layers are memoized by reference identity. Store parameterized layers in constants before reusing them.

```ts
const postgresLayer = Postgres.layer({ url, poolSize: 10 })

const appLayer = Layer.merge(
  Users.layer.pipe(Layer.provide(postgresLayer)),
  Orders.layer.pipe(Layer.provide(postgresLayer))
)
```

Calling `Postgres.layer(...)` twice creates two different layer references and can build duplicate pools.

## App Wiring Rules

- Provide dependencies at the app boundary, not throughout business logic.
- Keep one app layer per runtime entrypoint or deployment shape.
- Keep test layers close to tests unless reused broadly.
- Prefer `Layer.succeed` for simple test doubles.
- Prefer fresh per-test layers unless an expensive resource must be shared.

## Service-Driven Development

1. Define domain data and errors.
2. Define leaf service contracts with no implementation.
3. Implement higher-level orchestration against contracts.
4. Add live layers.
5. Add test layers.
6. Wire at entrypoints and tests.

This lets orchestration code typecheck before all infrastructure exists.

## Smells

- Service method type includes unrelated requirements: `Effect<A, E, Config | Logger>`.
- Every function calls `Effect.provide`.
- Layer constructors are invoked repeatedly in composition.
- Test doubles expose broader APIs than contracts.
- Business code imports runtime-specific platform packages.
