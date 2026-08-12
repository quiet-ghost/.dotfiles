---
name: opentui-dev
description: Build and troubleshoot OpenTUI terminal apps with @opentui/core, renderer setup, layout, input, and component composition. Use when creating or fixing OpenTUI UIs.
---

# OpenTUI Dev

Build and debug terminal UIs using OpenTUI's Bun + TypeScript workflow.

## When To Use

Use this skill when the task involves:

- OpenTUI setup or migration to `@opentui/core`
- Renderer lifecycle, root composition, or Ctrl+C behavior
- Component layout with `Box`, `Text`, and interactive components
- Keyboard handling, input flows, or terminal rendering issues

## Quick Start

For a new app:

```bash
mkdir my-tui && cd my-tui
bun init -y
bun add @opentui/core
```

Create `index.ts`:

```ts
import { createCliRenderer, Text } from "@opentui/core"

const renderer = await createCliRenderer({
  exitOnCtrlC: true,
})

renderer.root.add(
  Text({
    content: "Hello, OpenTUI!",
    fg: "#00FF00",
  }),
)
```

Run:

```bash
bun index.ts
```

## Workflow

1. Verify runtime: Bun project with `@opentui/core` installed.
2. Stand up renderer with `createCliRenderer({ exitOnCtrlC: true })`.
3. Compose UI from root using component factory functions.
4. Add layout first (`Box`), then content (`Text`, etc.), then interaction.
5. Validate behavior in terminal and refine spacing/colors/keyboard flow.

## In This Reference

| File | Purpose |
| --- | --- |
| [getting-started.md](./references/getting-started.md) | Install, hello world, renderer pattern |
| [components-layout.md](./references/components-layout.md) | Composition, layout, and interactive component patterns |
| [troubleshooting.md](./references/troubleshooting.md) | Common issues and concrete fixes |

## Guardrails

- Prefer small composable trees over one large nested block.
- Keep layout props explicit (`flexDirection`, `gap`, `padding`, `borderStyle`).
- Use hex colors consistently and verify contrast in terminal themes.
- Default to stable primitives (`Text`, `Box`, `Input`, `Select`) before custom abstractions.
