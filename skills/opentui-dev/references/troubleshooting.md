# Troubleshooting OpenTUI

## App does not start

**Check:** Bun is installed and dependencies are present.

```bash
bun --version
bun install
```

## Nothing renders

**Likely causes:**

- `createCliRenderer` not awaited
- No nodes added to `renderer.root`
- Immediate process exit after setup

**Fix:** Ensure root add path executes and process stays alive via renderer lifecycle.

## Ctrl+C does not exit

**Fix:** Set `exitOnCtrlC: true` in renderer creation.

## Layout looks collapsed

**Fixes:**

- Add explicit `flexDirection`
- Add `padding` and `gap`
- Wrap sections in parent `Box` containers

## Colors look wrong

**Fixes:**

- Use explicit hex color strings (`#RRGGBB`)
- Test in another terminal theme
- Increase contrast between foreground and background

## Useful references

- Getting started: https://opentui.com/docs/getting-started/
- Renderer: https://opentui.com/docs/core-concepts/renderer
- Layout: https://opentui.com/docs/core-concepts/layout
- Components: https://opentui.com/docs/components/text
