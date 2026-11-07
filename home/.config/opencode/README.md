# OpenCode 2

One global setup lives here. `oc` / `opencode` launch Omarchy's Mise-managed
`opencode` tool (`/etc/mise/conf.d/omarchy-tools.toml`). Do not also declare
`npm:@opencode/cli` in the user Mise config: it installs a second copy that
shadows this one on `PATH`.

`opencode2` remains the native executable name. There is no isolated launcher.

## Updates

Mise auto-updates the tool every 4 hours when it runs. `mup` runs Mise upgrades
and `opencode-update`. Both skip Mise's 1-hour version cache. `opencode-update`
upgrades the tool, verifies the installed binary's version, and updates package
plugins. It does not deliberately restart the shared service. When active
sessions can be interrupted:

```sh
opencode2 service restart
opencode2 api get /api/health
```

Local plugin dependencies use npm and `package-lock.json`. The plugin API is
beta; after changing its version, run `npm run check` and `npm test` here.

## Plugins

- `file-protection`: blocks `.env` reads and repairs accidental notes-mirror paths.
- `caveman`: server-side instructions, persistent per-session modes, slash command,
  and a synchronized CLI selector on `<leader>v`.
- `custom-tools`: AST-grep search/rewrite and YouTube transcript fetching.
- `plannotator`: upstream package, configured in `opencode.json`.
- `plugins/tui/herdr.ts`: reports the selected root session and its family's
  working/blocked/idle state from the terminal client, not the shared server.

The V1 80%-threshold compaction plugin and its commands are removed. V2's native
automatic compaction remains at its defaults. It is global, **not Claude-only**;
the installed V2 API has no per-model automatic-compaction setting.

## Private state

`service.json` is host-local and must remain Git- and Stow-ignored. Credentials
and session history under `~/.local/share/opencode` remain untouched by migration.
Do not copy them into this directory or publish them.

## Checks

```sh
npm ci --ignore-scripts
npm run check
npm test
opencode2 plugin list
opencode2 mcp list
```
