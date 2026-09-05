# ghost.discord

Local Omarchy bar widget for Vesktop. Vendored from
[thisisgm/omarchy-discord](https://github.com/thisisgm/omarchy-discord)
1.0.1 (MIT). Not a submodule.

Upstream is hardcoded to the Arch `discord` package. This copy matches
Vesktop as measured on this machine:

- desktop entry `vesktop.desktop`, `StartupWMClass=vesktop`
- Hyprland class `vesktop`
- `ps -C vesktop`
- PipeWire `application.process.binary=vesktop`

The optional Discord RPC voice bridge is left off. Vesktop's
`discord-ipc-0` is arRPC (rich presence for games), not Discord's voice
socket, so channel name / Discord mute / deafen / hangup are unavailable.
Call state, PipeWire mute, and volume still work.

Left click opens the panel. Middle click raises or starts Vesktop.
Right click mutes the call mic, or refreshes when not in a call.

Hide Vesktop's own tray item once: right-click the tray > Manage.
