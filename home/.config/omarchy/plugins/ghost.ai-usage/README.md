# ghost.ai-usage

One Omarchy bar panel for subscription quotas and API spend.

Left click opens the panel. Right click switches Subs / APIs. Middle click refreshes.

## Views

- **Subs** — Codex weekly, Grok SuperGrok weekly, OpenCode Go windows when entitled
- **APIs** — OpenAI Admin usage/costs, xAI prepaid balance

Both views keep tokens-by-day and tokens-by-model.

## Keys

Optional file: `~/.config/omarchy/ai-usage.json` (not in git)

```json
{
  "openaiAdminKey": "sk-admin-...",
  "xaiManagementKey": "...",
  "xaiTeamId": "..."
}
```

Environment names also work: `OPENAI_ADMIN_KEY`, `XAI_MANAGEMENT_KEY`, `XAI_TEAM_ID`.

Without those keys, API tabs still show local OpenCode/Grok token history and say which key is missing.
