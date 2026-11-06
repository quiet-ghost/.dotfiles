# Common Mistakes

Issues, causes, and fixes for skill creation.

The format checks below are portable authoring conventions. OpenCode V2 is more permissive at runtime; its path-derived IDs and discovery rules still apply.

## Frontmatter Errors

| Error | Fix |
|-------|-----|
| No opening `---` | Must start at line 1 |
| Blank lines before `---` | Frontmatter must be first |
| No closing `---` | Add `---` after fields |
| XML tags `<description>` | Use YAML only |

## Name Field Errors

| Error | Bad | Good |
|-------|-----|------|
| Uppercase | `My-Skill` | `my-skill` |
| Underscores | `my_skill` | `my-skill` |
| Leading hyphen | `-my-skill` | `my-skill` |
| Trailing hyphen | `my-skill-` | `my-skill` |
| Double hyphens | `my--skill` | `my-skill` |
| Dir mismatch | Dir: `foo/`, name: `bar` | Match both |

**Valid pattern:** `^[a-z0-9]+(-[a-z0-9]+)*$`

## Description Errors

| Error | Bad | Good |
|-------|-----|------|
| Too vague | "Helps with files" | "Extract text from PDFs" |
| First person | "I help with PDFs" | "Extracts text from PDFs" |
| No trigger | "PDF tool" | "PDF tool. Use when working with PDFs." |

## OpenCode V2 Routing Errors

| Error | Fix |
|-------|-----|
| Calling the skill tool with `name` | Use `skill({ id: 'my-skill' })` |
| Using display-name capitalization as an ID | Use the exact case-sensitive path-derived ID |
| Assuming the first duplicate wins | Later registered V2 sources replace earlier definitions |
| Expecting frontmatter references to preload | Link files in the body and state when to read them |
| Treating manual-only visibility as security | Use V2 `skill` permission rules to restrict loading |
| Setting only OpenCode metadata for a shared Pi skill | Prefer `disable-model-invocation: true` |
| Restarting to apply file edits | V2 watches definitions; use `/reload` to force a reload |

## Structure Errors

| Error | Fix |
|-------|-----|
| SKILL.md > 500 lines | Split to references/ |
| Duplicated content | Link, don't copy |
| Broken links | Verify paths exist |

## Script Errors

| Error | Fix |
|-------|-----|
| No shebang | Add `#!/usr/bin/env bash` |
| Silent failures | Add error handling |
| Hardcoded paths | Use relative paths |

## Validation Quick Reference

| Error Message | Fix |
|---------------|-----|
| "No frontmatter" | Add `---` at line 1 |
| "Missing name" | Add `name:` field |
| "Invalid name format" | Use lowercase-hyphens |
| "Name mismatch" | Match dir and name |
| "Missing description" | Add `description:` |
| "Description too short" | 50+ chars recommended |
| "File too large" | Split to references/ |
| "Broken link" | Fix path or create file |

The bundled validator currently reads `description: >` or `description: |` as a one-character description. That warning is a validator limitation, not evidence that valid YAML block scalars fail to load. Confirm with a YAML-aware loader.

## Context Rot Symptoms

| Symptom | Fix |
|---------|-----|
| Agent ignores instructions | Reduce SKILL.md size |
| Wrong file accessed | Add decision trees |
| Repeated questions | Improve cross-refs |
| Slow responses | Split to multi-file |

## See Also

- [frontmatter.md](./frontmatter.md) - YAML spec
- [anatomy.md](./anatomy.md) - Directory structures
