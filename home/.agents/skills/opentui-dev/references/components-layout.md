# Components and Layout Patterns

## Start with a Layout Shell

Use `Box` to define structure before adding behavior.

```ts
Box(
  {
    flexDirection: "column",
    gap: 1,
    padding: 1,
    borderStyle: "rounded",
  },
  Text({ content: "Header" }),
  Text({ content: "Body" }),
)
```

## Composition Rules

- Put high-level containers near `renderer.root`.
- Split repeated regions into helper functions returning renderables.
- Keep one responsibility per component block (layout, display, input).

## Interactive Components

For forms and menus, combine static labels with input widgets:

- `Input` for single-line entry
- `Textarea` for multi-line text
- `Select` or `TabSelect` for choices
- `ScrollBox` + `ScrollBar` for long content

Build interaction flow in this order:

1. Render labels and static context.
2. Add input/select widget.
3. Bind keyboard behavior.
4. Add validation feedback as `Text` near the field.

## Layout Checklist

- Set `flexDirection` deliberately (`column` for forms, `row` for toolbars).
- Use `gap` instead of manual spacing text.
- Use `padding` to separate borders from content.
- Keep border usage meaningful; avoid boxing every node.
