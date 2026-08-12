# Imports, Exports, and Files

Import directly from the owning file; use barrels only as intentional public entrypoints. Prefer named imports, `import type` and `export type` for type-only edges, and dynamic imports only at lazy, optional, plugin, or code-splitting boundaries.

Export only caller-facing behavior and rename stale exports with changed behavior. Give each file a searchable subject and one cohesive capability; keep domain policy with its owner and test internal helpers through public interfaces.

## Completion check

Imports expose ownership, exports are intentional, type-only edges are explicit, dynamic imports have a runtime reason, and files are cohesive and searchable.
