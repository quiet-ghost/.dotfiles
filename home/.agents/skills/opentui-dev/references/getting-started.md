# OpenTUI Getting Started

## Install

```bash
mkdir my-tui && cd my-tui
bun init -y
bun add @opentui/core
```

OpenTUI currently targets Bun first.

## Minimal App

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

## Basic Container Pattern

```ts
import { createCliRenderer, Box, Text } from "@opentui/core"

const renderer = await createCliRenderer({ exitOnCtrlC: true })

renderer.root.add(
  Box(
    { borderStyle: "rounded", padding: 1, flexDirection: "column", gap: 1 },
    Text({ content: "Welcome", fg: "#FFFF00" }),
    Text({ content: "Press Ctrl+C to exit" }),
  ),
)
```

## Notes

- Components are factory functions.
- First argument is props.
- Additional arguments are children.
