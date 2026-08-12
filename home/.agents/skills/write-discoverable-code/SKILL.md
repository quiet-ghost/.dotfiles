---
name: write-discoverable-code
description: Write code that agents and humans can find through plain-text search. Use whenever naming, moving, documenting, or organizing functions, types, constants, files, errors, or tests.
---

# Write Discoverable Code

Agents navigate by search and small read windows. Make each identifier, file, comment, and literal a useful search query.

## Names and files

- Give exported symbols 2-4 words, including a domain word: `diffUserObjects`, not `diff`.
- Give generic verbs their object and stop when the name is unique enough.
- Keep one definition site per symbol; move shared helpers instead of copying them.
- Put context in symbols, not only module paths.
- Choose one spelling for each concept and reuse existing project vocabulary.
- Rename stale names when behavior or audience changes.
- Avoid bare-role filenames such as `config.ts`, `types.ts`, `utils.ts`, and `handlers.ts`; use domain-qualified names. Thin `index.ts` re-exports are the exception.

## Types and documentation

- Brand primitive IDs and use capability types for privileged operations.
- Model state with discriminated unions, not nullable-field conventions; avoid `any`.
- Put one useful doc comment on every export, stating constraints the signature cannot show and including ordinary searchable domain phrases.
- Keep imported names and their doc lines self-describing; keep full error and event literals searchable.

## Structure and verification

- Keep one searchable concept per cohesive file and keep orchestrators thin.
- Colocate tests with the implementation when the project convention permits.
- Mark dead ends with `@deprecated` and a pointer to the replacement.

Before committing, search each new exported name, check argument safety, confirm units/timezone/ownership are documented, verify log and error strings exist verbatim, and ensure moved code was deleted from its old home.
