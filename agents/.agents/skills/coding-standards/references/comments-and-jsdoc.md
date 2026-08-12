# Comments and JSDoc

Document every exported symbol at its original declaration with the sharpest caller-visible fact its signature cannot show. Include searchable ordinary domain phrases, expected outcomes, side effects, ownership, invariants, or safety reasons when relevant.

Use `@param`, `@returns`, and `@template` when they clarify constraints; reserve `@throws` for unrecoverable defects or framework-required behavior. Document public members and non-obvious internal invariants, and keep comments meaningful rather than restating code.

## Completion check

Exports and public members have useful local documentation, expected typed failures are not described as throws, and comments add durable searchable meaning.
