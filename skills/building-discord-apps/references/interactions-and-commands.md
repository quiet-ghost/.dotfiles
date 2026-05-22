# Interactions and Commands

## Interaction Delivery

Interactions can be received in one of two ways:
- HTTP outgoing webhooks
- Gateway `INTERACTION_CREATE`

These two modes are mutually exclusive for interactions.

## Core Interaction Types

| Name | Value |
|------|-------|
| `PING` | `1` |
| `APPLICATION_COMMAND` | `2` |
| `MESSAGE_COMPONENT` | `3` |
| `APPLICATION_COMMAND_AUTOCOMPLETE` | `4` |
| `MODAL_SUBMIT` | `5` |

## High-Value Interaction Fields

- `id`: interaction ID
- `token`: token for responses and followups
- `type`: interaction type
- `data`: command/component payload
- `context`: where it was triggered (`GUILD`, `BOT_DM`, `PRIVATE_CHANNEL`)
- `member` or `user`: invoker identity

## Response Rules

- Initial response deadline is 3 seconds.
- Interaction token is valid for followup work for 15 minutes.
- If responding inline to HTTP, return status `200` with interaction response body.
- If responding later via callback endpoint, acknowledge the original request quickly.

## Common Interaction Callback Types

| Type | Value | Typical Use |
|------|-------|-------------|
| `PONG` | `1` | Acknowledge `PING` |
| `CHANNEL_MESSAGE_WITH_SOURCE` | `4` | Immediate message response |
| `DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE` | `5` | Ack first, respond later |
| `DEFERRED_UPDATE_MESSAGE` | `6` | Component ack then update later |
| `UPDATE_MESSAGE` | `7` | Edit component parent message |
| `APPLICATION_COMMAND_AUTOCOMPLETE_RESULT` | `8` | Return autocomplete options |
| `MODAL` | `9` | Open modal UI |
| `LAUNCH_ACTIVITY` | `12` | Launch app Activity |

## Command Types

| Name | Value |
|------|-------|
| `CHAT_INPUT` | `1` |
| `USER` | `2` |
| `MESSAGE` | `3` |
| `PRIMARY_ENTRY_POINT` | `4` |

## Command Design Constraints

- Slash command name length: 1-32 chars.
- Description length: 1-100 chars.
- Max options per command: 25.
- Required options must come before optional options.
- `choices` and `autocomplete` are mutually exclusive on an option.
- Max 25 choices per choice-based option.

## Scope and Rollout Strategy

- Guild command: instant update, ideal for development.
- Global command: broader rollout, eventual propagation.
- Recommended flow:
  1. Build and verify as guild commands.
  2. Promote stable commands to global scope.

## Context-Aware Commands

Use these fields on command objects:
- `integration_types`: where command is installable (guild or user install)
- `contexts`: where command can be invoked (`GUILD`, `BOT_DM`, `PRIVATE_CHANNEL`)

## Component and Modal Handling

- Assign deterministic `custom_id` values for routing.
- Encode minimal state in `custom_id` and use durable storage for anything sensitive.
- For select menus and modal submissions, validate both `custom_id` and actor permissions.

## Safer Message Responses

- Add `allowed_mentions: { parse: [] }` unless explicit mentions are required.
- Use ephemeral flags for user-specific responses.
- Avoid duplicating side effects; retries can happen.

## Common Failure Patterns

- Missing PING handling -> endpoint verification fails.
- Signature verification against parsed JSON instead of raw body -> false negatives.
- Slow database work before ack -> interaction timeout.
- Re-registering commands too often -> command create limits and noisy deploys.

## Source Docs

- https://docs.discord.com/developers/interactions/overview
- https://docs.discord.com/developers/interactions/receiving-and-responding
- https://docs.discord.com/developers/interactions/application-commands
