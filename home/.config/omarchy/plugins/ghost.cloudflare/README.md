# ghost.cloudflare

Local Omarchy bar widget for a Cloudflare account. Vendored from
[meirdick/omarchy-cloudflare](https://github.com/meirdick/omarchy-cloudflare)
1.1.0 (MIT). Not a submodule.

- Overview: attention, recent deploys, usage, resource counts, live sites
- Drill into Workers, Pages, R2, D1, KV, Queues, and zones
- `/` search, `o` live site, `t` tail, `D`/`R` deploy/rollback
- Uses the wrangler OAuth token; no separate API token

Left click toggles the panel. Right click refreshes. Middle click opens the
Workers dashboard. Dashboard URLs open as a webapp; other URLs use the browser.

Default project scan is `~/dev`. Override with `projectsRoot` in `shell.json`.
Diagnose with `omarchy-shell ghost.cloudflare diagnose`.
