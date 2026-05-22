# OAuth, Installation, and Permissions

## Installation Contexts

Discord apps support two installation contexts:
- Guild install (`integration_type=0`)
- User install (`integration_type=1`)

Decide this early because it impacts command visibility and OAuth UX.

## Common OAuth Scopes

| Scope | Typical Use |
|-------|-------------|
| `applications.commands` | Register and use app commands |
| `bot` | Install bot user into a guild |
| `identify` | Basic user identity for OAuth login |
| `guilds` | Read user guild list |
| `guilds.join` | Add user to guild (requires additional setup) |
| `applications.commands.update` | Update commands with client credentials token |

## OAuth Endpoints

- Authorization URL: `https://discord.com/oauth2/authorize`
- Token URL: `https://discord.com/api/oauth2/token`
- Token revoke URL: `https://discord.com/api/oauth2/token/revoke`

Important: token and revoke endpoints only accept `application/x-www-form-urlencoded`.

## Authorization Code Flow (Recommended for Web Apps)

1. Redirect user to authorize URL with `response_type=code`.
2. Include `state` and validate it on callback (CSRF protection).
3. Exchange `code` for access token at token endpoint.
4. Persist token expiry and refresh token.
5. Refresh tokens before expiry when needed.

## Bot Authorization URL Pattern

```text
https://discord.com/oauth2/authorize
  ?client_id=<APP_ID>
  &scope=bot%20applications.commands
  &permissions=<BITFIELD>
```

Useful optional params:
- `guild_id` to preselect server
- `disable_guild_select=true` to lock server picker

## Command Installation and Context Fields

Use command object fields to control reach:
- `integration_types`: where command is installable
- `contexts`: where command is invokable

These are separate from role/channel command permissions.

## Permissions Model Notes

- Permission bitfields are strings in API v8+.
- Use big integer operations for calculations.
- Role hierarchy matters for moderation and role management actions.
- `ADMINISTRATOR` bypasses channel overwrites.

## Default Command Permissions

- Use `default_member_permissions` on command creation.
- Set to `"0"` to default-deny command usage except admins.
- Apply per-user/role/channel overrides only when needed.

## Practical Security Rules

- Never ship `client_secret` to frontend code.
- Store bot token and OAuth secrets in secret manager or env vars.
- Validate OAuth `state` every time.
- Revoke tokens when disconnecting a user integration.

## Common Failure Patterns

- Missing `applications.commands` scope -> commands do not appear.
- Wrong `integration_type` for command install context -> command not visible where expected.
- JSON token requests to OAuth token endpoint -> rejected by content-type rules.
- 403 on role or member operations -> role hierarchy mismatch.

## Source Docs

- https://docs.discord.com/developers/topics/oauth2
- https://docs.discord.com/developers/resources/application
- https://docs.discord.com/developers/topics/permissions
- https://docs.discord.com/developers/interactions/application-commands
