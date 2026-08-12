# ADR Format

ADRs live in `docs/adr/` and use sequential names: `0001-slug.md`, `0002-slug.md`.

## Template

```md
# {Short title of the decision}

{1-3 sentences: context, decision, and reason.}
```

Add optional `Status` frontmatter, `Considered Options`, or `Consequences` only when they preserve useful context. Create the directory lazily and increment the highest existing number.

An ADR is warranted only when a decision is hard to reverse, surprising without context, and based on a real trade-off.
