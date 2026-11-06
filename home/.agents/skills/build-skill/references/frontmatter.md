# YAML Frontmatter Specification

For portable skills, begin `SKILL.md` with YAML frontmatter and keep `name` aligned with the directory. These are Agent Skills/local authoring conventions, not all runtime requirements of OpenCode V2.

V2 derives the case-sensitive skill ID from its path; `name` is a display label. Frontmatter is optional at runtime, but a skill without a description is not advertised to the model. V2 does not enforce the portable name/description length limits below. See the [V2 skills guide](https://opencode.ai/v2/docs/skills).

## Required Format

```yaml
---
name: skill-name
description: What this skill does and when to use it.
---
```

**Critical:** Frontmatter must start at line 1. No blank lines before `---`.

## Portable Required Fields

### name

| Constraint | Value |
|------------|-------|
| Required | Yes |
| Max length | 64 characters |
| Pattern | `^[a-z0-9]+(-[a-z0-9]+)*$` |
| Must match | Directory name |

**Rules:**
- Lowercase letters, numbers, hyphens only
- Cannot start or end with hyphen
- No consecutive hyphens (`--`)
- Must match parent directory name

**Naming conventions:**

| Style | Example | When to Use |
|-------|---------|-------------|
| Gerund (recommended) | `processing-pdfs` | Actions/capabilities |
| Noun phrase | `pdf-processor` | Tool/utility |
| Domain-specific | `cloudflare` | Platform skills |

**Good names:**
- `analyzing-data`
- `managing-releases`
- `code-review`
- `bigquery-analytics`

**Bad names:**
- `helper` (too vague)
- `utils` (meaningless)
- `MySkill` (uppercase)
- `pdf_processor` (underscores)

### description

| Constraint | Value |
|------------|-------|
| Required | Yes |
| Max length | 1024 characters |
| Min recommended | 50 characters |

**Rules:**
- Write in third person ("Processes files" not "I process files")
- Include WHAT the skill does
- Include WHEN to use it (activation triggers)
- Be specific with key terms

**Good descriptions:**

```yaml
# PDF skill
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or asked to read/edit PDFs.

# BigQuery skill  
description: Query BigQuery datasets using SQL. Use for data analytics, reports, or Google Cloud data warehouse tasks.

# Code review skill
description: Review pull requests for quality, security, and test coverage. Use when asked to review a PR or diff.
```

**Bad descriptions:**

```yaml
description: Helps with files          # Too vague
description: I can help you with data  # Wrong POV
description: PDF tool                  # No trigger context
description: Useful utility            # Meaningless
```

## Optional Fields

### license

```yaml
license: Apache-2.0
# or
license: See LICENSE.txt
```

### compatibility

```yaml
compatibility: Requires git, docker, and jq installed. macOS/Linux only.
```

Max 500 characters. Document environment requirements.

### metadata

```yaml
metadata:
  author: dmmulroy
  version: "1.0"
  team: platform
```

String-to-string map. Arbitrary key-value pairs.

### disable-model-invocation

```yaml
disable-model-invocation: true
```

Use for a deliberately manual-only skill. OpenCode and Pi omit it from automatic model discovery. This is visibility control, not a permission boundary; V2 still permits explicit loading by ID when permissions allow it.

### OpenCode-specific invocation metadata

```yaml
metadata:
  opencode/autoinvoke: false
```

V2 also supports this boolean setting. It takes precedence over `disable-model-invocation` when both exist. Prefer the portable top-level flag for shared OpenCode/Pi skills; other harnesses need not interpret this metadata key.

### Supporting references

Supporting files are not automatically loaded. Do not rely on a `references` frontmatter field for preloading. Put links and required read conditions in the Markdown body:

```markdown
For schema changes, read [the schema guide](references/schemas.md).
```

## Complete Example

```markdown
---
name: release-manager
description: Create releases with changelogs, version bumps, and git tags. Use when preparing a release, generating changelog, or bumping version numbers.
license: MIT
compatibility: Requires git and gh CLI
metadata:
  author: dmmulroy
  version: "2.0"
---

# Release Manager

Before proposing a version, read [versioning](references/versioning.md).
When drafting the changelog, read [changelog format](references/changelog-format.md).
```

## Validation Checklist

| Check | Requirement |
|-------|-------------|
| Starts with `---` | Line 1, no preceding blank lines |
| Has `name:` | Required |
| Name format | Lowercase, hyphens, no `--`, no leading/trailing `-` |
| Name matches dir | `my-skill/SKILL.md` has `name: my-skill` |
| Has `description:` | Required |
| Description quality | 50+ chars, third person, includes triggers |
| Closes with `---` | Required |
| YAML fields | Use YAML frontmatter fields, not XML wrappers |

## See Also

- [anatomy.md](./anatomy.md) - Directory structures
- [gotchas.md](./gotchas.md) - Common frontmatter errors
