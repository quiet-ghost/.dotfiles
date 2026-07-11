# Boundaries and Parsing

Boundary data is untrusted until parsed. Types alone do not validate runtime values.

## Boundaries

- HTTP/RPC request bodies, route params, headers, cookies.
- CLI args, env vars, config files.
- Database rows and storage objects.
- Queue messages, webhook payloads, runtime-hop payloads.
- Third-party SDK responses and `Response.json()`.

## Rules

- Accept `unknown` or framework types at the boundary, then parse once.
- Pass parsed/domain values into service and domain modules.
- Return typed parse failures with actionable messages.
- Keep DTO projection explicit on output; do not spread domain objects into public responses.
- Do not use `JSON.parse(...) as Type`, `await response.json() as Type`, or row casts as proof.
- Avoid repeated defensive shape checks in core logic; parse at the edge and carry refined values.

## Parser Shape

Prefer the repo's existing schema library. If no convention exists, prefer Standard Schema-compatible validators for TypeScript projects.

Parser output should be a refined value, not `boolean`:

```ts
type ParseResult<T, E> = { readonly ok: true; readonly value: T } | { readonly ok: false; readonly error: E };
```

## Review Checks

- Does untrusted data cross into service/domain logic?
- Is validation performed but the refined value discarded?
- Are storage rows or wire DTOs used as application/domain types?
- Are error messages specific enough to recover or debug?
