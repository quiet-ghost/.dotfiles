# ghost.tray

Local tray. Edit `Tray.qml` / `TrayModel.js` here. Omarchy updates do not overwrite it.

## Use

- Hover or click the chevron → drawer (system icons + captured bar plugins)
- Drag a bar widget onto the tray → it moves into the drawer
- Open drawer, drag a plugin back onto the bar → it leaves the tray
- Drag within the drawer → reorder plugins and system icons
- Drag the chevron → move the whole tray
- Right-click chevron → hide/show system icons

The drawer stays open during a drag. System tray icons can be reordered or hidden;
only bar plugins can be dragged out onto the bar.

On stock Omarchy 4, host discovery uses a stock widget in the same bar window
(for example Menu, Audio, or Network). Keep at least one stock widget on the bar
so the tray can reconnect to the drag coordinator after a restart.

Captured plugins live on this widget's `shell.json` entry (`widgets`, `order`). They also stay listed in `plugins[]` so the shell keeps their components loaded.

Syncthing uses `SyncthingWidget.qml`: a local wrapper around the installed upstream
panel, with one shared backend across monitors. It stays out of `plugins[]` while
hosted to avoid starting a second backend. Returning it to the bar restores normal
Omarchy service loading. Upstream Syncthing files remain updateable.

Mise Radar 1.2.0+ and local Govee use their own shared QML backends. These tray
integrations run on stock Omarchy; no host patches are required.
