# ghost.ai-usage

One Omarchy bar panel for subscription quotas and API spend.

Laid out like `omarchy.agents`: a hero with a rotating summary, then one page of providers with compact limit meters.

Left click opens the panel. Right click switches Subs / APIs. Middle click or `r` force-refreshes; so does Enter when nothing is picked.

Subscription meters come from Codex / Claude Code OAuth, not API keys. Rotating `ai-usage.json` keys will not fix those banners.

Claude follows the stock `omarchy.agents` collector: it reads the Claude Code login, probes `GET /api/oauth/usage` with the same headers, reuses a 15s last-good cache, and keeps open windows when Anthropic 429s. It does not mint Claude tokens — start Claude Code or run `claude auth login` if the saved sign-in expired.

Codex still refreshes `~/.codex/auth.json` when that access token is stale.

## Views

- **Subs** — Codex, Grok, Claude Code (5h/weekly), OpenCode, plus Omarchy providers with limits or history
- **APIs** — OpenAI, xAI, Claude Admin spend, OpenRouter, Cerebras, plus Omarchy providers with a prepaid balance
- **Settings** (gear, or `,`) — assign each provider to Subs, APIs, or Hide; a choice saves at once

Both views keep tokens-by-day and tokens-by-model: click a provider's header, or pick it and press Enter, to open them. Exact percentages and per-model input/output/cache counts are in the tooltips.

Keys: arrows or `hjkl` move, Enter acts, `s` Subs, `a` APIs, `,` settings, `r` refresh, Tab next panel, Esc back or close.

## Other providers

Every other provider Omarchy can collect (Cursor, Copilot, Kimi, DeepSeek, Ollama, Z.ai and so on) comes from the records `omarchy-agent-usage-update` writes to `~/.local/state/omarchy/agents/usage/`. Any record there is a provider, so one Omarchy adds later appears by itself, wearing the mark Omarchy ships for it.

The plugin runs that command itself, every 15 minutes and when the panel opens, leaving out Claude, Codex, Grok, OpenCode and OpenRouter: `scripts/ai_usage.py` collects those, and asking twice would double the limit probes.

Records with nothing to show start hidden. Choose a view for them in Settings. Omarchy's multi-account switching isn't offered here; a provider with several accounts shows its active one.

## Keys

Optional file: `~/.config/omarchy/ai-usage.json` (not in git)

```json
{
  "openaiAdminKey": "sk-admin-...",
  "xaiManagementKey": "...",
  "xaiTeamId": "...",
  "openrouterApiKey": "sk-or-...",
  "openrouterManagementKey": "",
  "anthropicAdminKey": "",
  "cerebrasApiKey": ""
}
```

Environment names also work: `OPENAI_ADMIN_KEY`, `XAI_MANAGEMENT_KEY`, `XAI_TEAM_ID`, `OPENROUTER_API_KEY`, `OPENROUTER_MANAGEMENT_KEY`.

OpenRouter: a normal key (`GET /api/v1/key`) shows that key’s cap and usage. A **Management** key (`GET /api/v1/credits`) shows account-wide purchased vs used. Prefer the management key for wallet remaining.

Cerebras: the key is only checked against `GET /v1/models`. Cerebras has no API for balance or spend, so those stay in its Cloud Console; tokens come from OpenCode sessions on the `cerebras` provider.

Fireworks is read by Omarchy's collector, which takes its key from `~/.fireworks/auth.ini` (`api_key = ...`), outside this repo.

Without those keys, API tabs still show local OpenCode/Grok token history and say which key is missing.
