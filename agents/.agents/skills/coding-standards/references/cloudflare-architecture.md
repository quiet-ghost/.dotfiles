# Cloudflare Architecture

Use with the existing `cloudflare` skill for API details. This file covers architecture taste for Workers, bindings, Durable Objects, Agents, D1, KV/R2, Queues, Workflows, and runtime hops.

## Rules

- Keep raw `Env`, `Request`, `ExecutionContext`, bindings, and framework objects at entrypoints or local adapter modules.
- Parse all inbound requests, queue messages, alarm payloads, and runtime-hop payloads before service/domain logic.
- Treat Durable Object and Agent identity, storage, and lifecycle as topology decisions, not just classes.
- Do not put hot-path global coordination in a single object unless serialization is intentional.
- Make retry/idempotency explicit for Queues, Workflows, and webhook-style handlers.
- Use service bindings or adapters to hide remote/runtime mechanics from service modules.
- Avoid leaking platform-specific response, storage, or binding types into domain modules.

## Review Checks

- Does a service receive `Env`, binding handles, raw `Request`, or storage rows?
- Can a runtime-hop payload lose type/context and enter core logic unparsed?
- Is object identity split across multiple keys/classes by accident?
- Are queue retries or workflow resumes safe to repeat?
- Are logs safe for edge/runtime payloads?
