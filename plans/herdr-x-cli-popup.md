# Herdr quick x-cli popup

## Context

The old tmux setup provides a quick tweet composer with `Ctrl+$`:

```tmux
bind-key -n C-$ popup -E -w 65% -h 65% "x-cli"
```

After moving daily terminal work to Herdr, that shortcut is no longer available. The intended outcome is the same fast, temporary, **non-fullscreen** `x-cli` surface without creating a persistent workspace/tab/pane. It should retain the old centered 65%×65% sizing rather than occupying the whole Herdr client.

## Approach

Use Herdr's native `type = "popup"` custom command, matching the existing workspace-picker popup pattern. Bind the old `Ctrl+$` shortcut as `ctrl+$`, run `x-cli` directly, and size the popup to 65%×65% to preserve the tmux behavior. Herdr 0.7.5 accepts this binding and popup configuration in `herdr config check`, and `x-cli` is already available on `PATH` at `~/.cache/.bun/bin/x-cli`, so no helper script or shell wrapper is needed.

Add this near the existing tool overlays:

```toml
[[keys.command]]
key = "ctrl+$"
type = "popup"
command = "x-cli"
description = "compose tweet with x-cli"
width = "65%"
height = "65%"
```

Herdr popups **do not need to be fullscreen**. Their `width` and `height` fields accept percentages of the current terminal area, so `"65%"` preserves the tmux popup footprint and Herdr centers it with a border. “Session-modal” only means keyboard input goes to the popup while it is open; it does not mean fullscreen. The popup closes automatically when `x-cli` exits and never changes the current tab layout. Herdr also starts custom commands from the focused pane's detected working directory, though `x-cli` does not require a project-specific directory.

## Files to modify

- `herdr/.config/herdr/config.toml` — add the `x-cli` popup command near the other tool overlays.

## Reuse

- `tmux/.config/tmux/tmux.conf` — source behavior and dimensions (`C-$`, `x-cli`, 65%×65%).
- `herdr/.config/herdr/config.toml` — existing `type = "popup"` custom-command pattern used by the workspace picker.

## Steps

- [ ] Add the `ctrl+$` `x-cli` popup custom command with the old 65%×65% dimensions and a clear help-panel description.
- [ ] Run `herdr config check` before reloading.
- [ ] Run `herdr server reload-config` so the live Herdr session picks up the shortcut.

## Verification

- Run `herdr config check` and reload the Herdr config without parse or keybinding errors.
- From a normal Herdr pane, press `Ctrl+$` (physically `Ctrl+Shift+4` on the current keyboard layout) and confirm `x-cli` opens in a centered, bordered 65%×65% temporary popup—not fullscreen.
- Exit/cancel `x-cli` and confirm the popup closes and focus returns to the previous pane.
- Confirm repeated invocation does not leave extra tabs, panes, or workspaces.
