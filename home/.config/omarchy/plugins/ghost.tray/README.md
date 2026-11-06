# ghost.tray

Omarchy's stock tray (`omarchy.tray`), plus status icons you can arrange by hand.
Edit `Tray.qml` / `TrayModel.js` here. Omarchy updates do not overwrite it.

## Use

Hover or click the chevron to open the drawer.

**Bar widgets** (handled by Omarchy's own bar):

- Drag a widget from the bar into the open drawer to tuck it away
- Drag it within the drawer to reorder
- Drag it onto the bar to pull it back out

**Status icons** (handled by this plugin):

- Drag within the drawer to reorder
- Drag onto the icons beside the chevron to pin one, so it stays visible
- Drag a pinned icon back into the drawer to unpin it
- Drag one well off the bar to hide it

Right-click the chevron to pin, hide, or bring back icons, or to turn them all off.
Drag the chevron to move the whole tray.

Status icons stay in the tray's own strips. They have no `bar.layout` entry, so
they cannot sit between bar widgets. Icons always come before widgets in the drawer.

## Config

In `shell.json`:

- `bar.layout.tray`: the drawer's bar widgets, owned by Omarchy
- `pinned`, `hidden`, `order` on this widget's entry: status icon ids

## Test

```bash
node --test tests/
```
