# Platform and CLI

Use this for runtime services, filesystem, terminal, command execution, HTTP, and command-line apps.

## Platform Packages

Common packages:

- `@effect/platform`
- `@effect/platform-node`
- `@effect/platform-bun`
- `@effect/platform-browser`

Use only packages needed by the target runtime. Keep platform imports at adapters, entrypoints, and infrastructure layers, not domain modules.

## Runtime Services

Platform packages provide runtime-specific services and `runMain` helpers.

Node:

```ts
import { NodeRuntime } from "@effect/platform-node"

NodeRuntime.runMain(main)
```

Bun:

```ts
import { BunRuntime } from "@effect/platform-bun"

BunRuntime.runMain(main)
```

Use platform service layers such as Node or Bun services when programs require filesystem, path, terminal, command, or other platform capabilities.

## Filesystem and Path

Use platform services for filesystem work instead of direct `fs` in business effects.

Typical pattern:

1. Domain logic depends on a service contract.
2. Live layer uses platform `FileSystem` and `Path`.
3. Test layer uses in-memory or temp-directory behavior.

For small scripts, direct platform services can be acceptable if the script is the boundary.

## CLI Module

Effect CLI APIs may live under `effect/unstable/cli` depending on version. Verify installed imports.

Common concepts:

- `Command.make(name, config, handler)` defines a command.
- `Argument.string`, `Argument.integer`, optional/variadic args define positionals.
- `Flag.boolean`, `Flag.string`, `Flag.choice`, aliases define options.
- `Command.withSubcommands` builds multi-command CLIs.
- `Command.run(command, { version })` builds the runnable program.

Minimal shape:

```ts
import { Console, Effect } from "effect"
import { Argument, Command, Flag } from "effect/unstable/cli"
import { BunRuntime, BunServices } from "@effect/platform-bun"

const name = Argument.string("name").pipe(Argument.withDefault("World"))
const shout = Flag.boolean("shout").pipe(Flag.withAlias("s"))

const greet = Command.make("greet", { name, shout }, ({ name, shout }) => {
  const message = `Hello, ${name}!`
  return Console.log(shout ? message.toUpperCase() : message)
})

Command.run(greet, { version: "1.0.0" }).pipe(
  Effect.provide(BunServices.layer),
  BunRuntime.runMain
)
```

Adjust runtime and import paths for Node or installed API shape.

## CLI Design

- Parse CLI inputs with `Argument` and `Flag` schemas when available.
- Decode config and files with `Schema`.
- Keep command handlers thin; delegate to services.
- Use `Console` from Effect, not raw console, unless project style differs.
- Use `runMain` for graceful teardown.

## HTTP and Client APIs

Effect HTTP APIs and import paths have changed across versions. Before adding HTTP code:

1. Inspect existing project imports.
2. Check installed `@effect/platform` and `effect/unstable/http` types.
3. Use Schema to decode request/response bodies.
4. Wrap provider errors in typed domain/API errors.
5. Add timeouts and retry only where safe.

## Command Execution

Use platform command APIs for shell/process work when available. Keep command construction explicit, pass args as arrays, and avoid shell interpolation for user input.

## Smells

- Domain modules import `@effect/platform-node`.
- CLI handlers contain all business logic.
- Raw process env, fs, or console spread through services.
- Unstable import paths used without checking installed version.
- HTTP responses trusted without Schema decoding.
