# YouTube Music

Native, full-window Omarchy music client. The first version supports account-free
YouTube search, a playback queue, seeking, and lightweight audio playback through
the system's existing `yt-dlp` and `mpv` packages.

Open it with `SUPER + SHIFT + Y` or:

```bash
omarchy-shell shell summon local.youtube-music
```

## Current scope

- Native QML window following the active Omarchy theme
- Search with `Ctrl+K`
- Play/pause with Space
- Previous/next with `Ctrl+Left` and `Ctrl+Right`
- Search results become the active queue

## Connect your account

The app supports browser-session authentication for personalized Home,
listening history, liked songs, library songs, albums, artists, and playlists.

1. Sign in at `music.youtube.com` in your browser.
2. Open Developer Tools and select the Network tab.
3. Reload, then select a successful POST request named `browse`.
4. Choose **Copy > Copy as cURL** and paste the complete command into the app's
   Connect page. A request URL by itself does not contain authentication data.

The app never requests your Google password. Headers travel to the helper over
stdin rather than process arguments. The resulting session is stored at
`~/.local/state/omarchy/youtube-music/browser.json` with mode `0600`, outside
the synchronized dotfiles tree. Browser sessions can expire and may need importing
again.
