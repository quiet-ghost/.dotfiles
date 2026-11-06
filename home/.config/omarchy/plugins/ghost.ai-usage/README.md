# ghost.ai-usage

One Omarchy bar panel for subscription quotas and API spend.

Laid out like `omarchy.agents`: a hero with a rotating summary, then one page of providers with compact limit meters.

Left click opens the panel. Right click switches Subs / APIs. Middle click or `r` force-refreshes; so does Enter when nothing is picked.

Subscription meters come from Codex / Claude Code OAuth, not API keys. Rotating `ai-usage.json` keys will not fix those banners.

Claude follows the stock `omarchy.agents` collector: it reads the Claude Code login, probes `GET /api/oauth/usage` with the same headers, reuses a 15s last-good cache, and keeps open windows when Anthropic 429s. It does not mint Claude tokens — start Claude Code or run `claude auth login` if the saved sign-in expired.

Codex still refreshes `~/.codex/auth.json` when that access token is stale.

## Views

- **Subs** — Codex, Grok, Claude Code (5h/weekly), OpenCode
- **APIs** — OpenAI, xAI, Claude Admin spend, OpenRouter
- **Settings** (gear, or `,`) — assign each provider to Subs, APIs, or Hide; a choice saves at once

Both views keep tokens-by-day and tokens-by-model: click a provider's header, or pick it and press Enter, to open them. Exact percentages and per-model input/output/cache counts are in the tooltips.

Keys: arrows or `hjkl` move, Enter acts, `s` Subs, `a` APIs, `,` settings, `r` refresh, Tab next panel, Esc back or close.

## Keys

Optional file: `~/.config/omarchy/ai-usage.json` (not in git)

```json
{
  "openaiAdminKey": "sk-admin-...",
  "xaiManagementKey": "...",
  "xaiTeamId": "...",
  "openrouterApiKey": "sk-or-...",
  "openrouterManagementKey": "",
  "anthropicAdminKey": ""
}
```

Environment names also work: `OPENAI_ADMIN_KEY`, `XAI_MANAGEMENT_KEY`, `XAI_TEAM_ID`, `OPENROUTER_API_KEY`, `OPENROUTER_MANAGEMENT_KEY`.

OpenRouter: a normal key (`GET /api/v1/key`) shows that key’s cap and usage. A **Management** key (`GET /api/v1/credits`) shows account-wide purchased vs used. Prefer the management key for wallet remaining.

Without those keys, API tabs still show local OpenCode/Grok token history and say which key is missing.
