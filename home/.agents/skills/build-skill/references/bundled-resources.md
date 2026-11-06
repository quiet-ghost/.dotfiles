# Bundled Resources

Guide to scripts/, references/, and assets/ directories.

## Resource Type Decision

```
What kind of content?
├─ Executable code → scripts/
├─ Documentation for agent → references/
└─ Files for output → assets/
```

## scripts/

Executable code the agent runs directly.

**When to include:**
- Same code rewritten repeatedly
- Deterministic operations needed
- Complex validation logic

**Best practices:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# Handle errors
if [[ ! -f "$1" ]]; then
    echo "Error: File not found: $1" >&2
    exit 1
fi
```

**Execution vs reading:**
- "Run `scripts/validate.sh`" → execute
- "See `scripts/validate.sh` for logic" → read

## references/

Documentation loaded into agent context.

**When to include:**
- Domain knowledge model lacks
- API documentation
- Database schemas
- Detailed workflow guides

**Structure each file:**
```markdown
# Title

Brief overview.

## Contents
- Section 1
- Section 2

## Section 1
...
```

**Size limit:** Target 100-150 lines, max 200.

## assets/

Files used in output, not loaded into context.

**When to include:**
- Templates (`.yaml`, `.json`)
- Images (logos, diagrams)
- Boilerplate code

**Organization:**
```
assets/
├── templates/config.yaml
├── images/logo.png
└── boilerplate/project/
```

Agent copies/uses files without loading into context.

## Comparison

| Directory | Purpose | Token Cost | Agent Action |
|-----------|---------|------------|--------------|
| scripts/ | Automation | Zero | Execute |
| references/ | Documentation | When read | Read |
| assets/ | Output files | Zero | Copy/use |

## OpenCode V2 Integration Boundary

A skill bundle supplies instructions and supporting files, not automatic MCP server registration. Configure servers under `mcp.servers` in the appropriate global or project `opencode.json(c)`, following the [V2 MCP guide](https://opencode.ai/v2/docs/mcp-servers). Do not assume a bundled `mcp.json` installs a server, or change configuration without authorization.

## See Also

- [anatomy.md](./anatomy.md) - Directory structures
- [patterns.md](./patterns.md) - Real skill patterns
