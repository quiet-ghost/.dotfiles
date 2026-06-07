# Schema and Data Modeling

Use this for domain models, boundary validation, JSON, brands, and generated tooling.

## Schema Mental Model

`Schema<A, I, R>` describes data that decodes from input `I` to output `A`, may require `R`, and can encode `A` back to `I`.

Schema can provide:

- Runtime validation.
- Decoding and encoding.
- TypeScript types.
- Standard Schema.
- JSON Schema.
- Pretty printers.
- Arbitraries for property tests.
- Equivalence helpers.

Rule: schemas should roundtrip. Encoding then decoding should preserve the value unless a documented lossy transform is intentional.

## Boundary Rule

Decode at boundaries:

- HTTP request bodies and responses.
- CLI arguments and flags.
- Config and env vars.
- Files and JSON.
- Queue messages and pubsub payloads.
- Database rows from untyped drivers.
- External API responses.

Inside the domain, pass typed values rather than re-decoding repeatedly.

## Records

Use `Schema.Class` for domain records with behavior.

```ts
import { Schema } from "effect"

const UserId = Schema.String.pipe(Schema.brand("UserId"))
type UserId = typeof UserId.Type

class User extends Schema.Class<User>("User")({
  id: UserId,
  name: Schema.NonEmptyString,
  email: Schema.String
}) {
  get displayName() {
    return `${this.name} <${this.email}>`
  }
}
```

If the installed version uses different class APIs, follow local examples and installed types.

## Brands

Use brands for semantically different primitives:

- Entity IDs: `UserId`, `OrderId`.
- Email, URL, slug.
- Port, percentage, count, money amount.
- External provider IDs.

Avoid passing raw strings across service boundaries when the value has domain meaning.

## Variants

Use tagged classes and unions for illegal-state prevention.

```ts
import { Match, Schema } from "effect"

class Active extends Schema.TaggedClass<Active>("Active")("Active", {
  userId: UserId
}) {}

class Suspended extends Schema.TaggedClass<Suspended>("Suspended")("Suspended", {
  userId: UserId,
  reason: Schema.String
}) {}

const AccountState = Schema.Union([Active, Suspended])
type AccountState = typeof AccountState.Type

const label = (state: AccountState) =>
  Match.value(state).pipe(
    Match.tag("Active", ({ userId }) => `active:${userId}`),
    Match.tag("Suspended", ({ reason }) => `suspended:${reason}`),
    Match.exhaustive
  )
```

## Decoding and Encoding

Use effectful decoders at boundaries:

```ts
const user = yield* Schema.decodeUnknownEffect(User)(input)
const output = yield* Schema.encodeEffect(User)(user)
```

For JSON strings:

```ts
const UserFromJson = Schema.fromJsonString(User)

const user = yield* Schema.decodeUnknownEffect(UserFromJson)(jsonString)
const json = yield* Schema.encodeEffect(UserFromJson)(user)
```

Use the JSON-string schema when input/output is a string, not the object schema.

## Config Schema

Prefer `Config.schema` for validated env values.

```ts
import { Config, Schema } from "effect"

const Port = Schema.NumberFromString.pipe(
  Schema.check(Schema.isInt()),
  Schema.check(Schema.isBetween({ minimum: 1, maximum: 65535 })),
  Schema.brand("Port")
)

const port = yield* Config.schema(Port, "PORT")
```

## Standard Schema and Tooling

When integrating with libraries that accept Standard Schema, prefer deriving from Effect Schema instead of duplicating a second schema. For generated JSON Schema, OpenAPI, form validation, or property tests, keep the Effect schema as the source of truth.

## Smells

- Type alias and runtime validator defined separately for the same data.
- Boundary accepts `unknown` but casts instead of decoding.
- IDs modeled as raw `string` everywhere.
- Optional properties conflict with `exactOptionalPropertyTypes`.
- JSON parse/stringify done without Schema validation.
