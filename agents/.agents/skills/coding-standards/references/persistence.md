# Persistence

Read this when behavior reads or writes a database, cache, durable object, ORM model, or persisted record. Keep table layout, queries, raw records, and ORM mechanics private to the owning domain capability; treat stored rows and cached values as serialized input that must be parsed.

Also load `designing-modules.md`, `boundaries-and-parsing.md`, `testing-and-verification.md`, and `workflows-transactions-and-idempotency.md` when their triggers apply.

## Completion check

Each changed persistence operation belongs to one cohesive domain capability, parses stored data before use, and passes linked reference checks or records a concrete exception.
