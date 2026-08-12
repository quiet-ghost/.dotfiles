---
name: building-discord-apps
description: Builds and troubleshoots Discord applications using interactions, application commands, OAuth2 installation flows, and Gateway events. Use when creating a Discord app, implementing slash commands or components, integrating OAuth, or preparing a Discord integration for production.
references:
  - references/quickstart.md
  - references/interactions-and-commands.md
  - references/oauth-installation-and-permissions.md
  - references/gateway-and-intents.md
  - references/production-readiness.md
---

# Building Discord Apps

Use this skill for Discord app work that touches:
- Interaction handlers (HTTP webhooks or Gateway)
- Slash, user, and message commands
- Bot install and OAuth2 authorization flows
- Permissions, intents, and production hardening

## Architecture Choice

Discord interactions can be delivered in two mutually exclusive ways:
- Outgoing webhooks (HTTP endpoint configured in app settings)
- Gateway `INTERACTION_CREATE` events

Default choice:
- Use HTTP interactions for slash-command style apps and stateless services.
- Use Gateway when you already need an event stream and in-memory state.

## Workflow

1. Define app type and install context (guild, user, or both).
2. Configure app settings (scopes, install contexts, bot permissions, intents).
3. Implement transport (HTTP interactions or Gateway).
4. Implement commands/components/modals and interaction responses.
5. Register commands in guild scope first, then global.
6. Add rate limit handling, retries, and idempotency.
7. Verify security headers, token storage, and operational checks.

## Reading Order

| Task | Files |
|------|-------|
| Build first command bot | quickstart.md -> interactions-and-commands.md |
| Handle interactions correctly | interactions-and-commands.md |
| Add OAuth/login/install flow | oauth-installation-and-permissions.md |
| Build Gateway/event bot | gateway-and-intents.md |
| Ship and harden in production | production-readiness.md |

## In This Reference

| File | Purpose |
|------|---------|
| [quickstart.md](./references/quickstart.md) | End-to-end starter flow for a new Discord app |
| [interactions-and-commands.md](./references/interactions-and-commands.md) | Interaction models, command rules, response timing |
| [oauth-installation-and-permissions.md](./references/oauth-installation-and-permissions.md) | OAuth2, install contexts, scopes, and permissions |
| [gateway-and-intents.md](./references/gateway-and-intents.md) | Gateway lifecycle, intents, resume, sharding basics |
| [production-readiness.md](./references/production-readiness.md) | Rate limits, reliability, security, and launch checks |

## Guardrails

- Never expose bot tokens, client secrets, or signing keys in code or logs.
- Verify `X-Signature-Ed25519` and `X-Signature-Timestamp` on every HTTP interaction.
- Reply to every interaction quickly: initial response must be sent within 3 seconds.
- Treat Discord APIs as eventually consistent and build idempotent handlers.
- Do not hardcode rate limits; always use response headers and 429 payloads.

## Practical Defaults

- API base URL: `https://discord.com/api/v10`
- During development, register commands to a test guild for instant updates.
- For production release, promote to global commands after validation.
- Use `default_member_permissions` plus channel and role command permissions.
- Use `allowed_mentions` in bot responses to avoid accidental mass pings.

## Troubleshooting Routing

- Invalid interaction signature -> inspect raw request body handling and public key.
- Commands not appearing -> check `applications.commands` scope and command scope.
- 429 spikes -> implement per-bucket queues keyed by `X-RateLimit-Bucket`.
- Gateway drops -> ensure heartbeat ACK handling and resume logic.
- 403 on management actions -> check bot role hierarchy and granted permissions.
