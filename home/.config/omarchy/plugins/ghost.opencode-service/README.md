# ghost.opencode-service

Omarchy bar monitor for the local OpenCode 2 shared service.

- Five-second health and active-session polling
- Compact status with expandable diagnostics
- Confirmed stop and restart controls
- Start, refresh, and open-log actions

The helper reads OpenCode's mode-`0600` service registration and emits sanitized JSON. Passwords, authorization headers, session IDs, prompts, titles, and project paths never enter QML state.

Left click opens the panel. Middle click refreshes. In the panel, `e` toggles details, `r` refreshes, `l` opens the service log, and `s` starts a stopped service.
