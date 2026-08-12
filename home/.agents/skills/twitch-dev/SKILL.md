---
name: twitch-dev
description: Builds and troubleshoots Twitch integrations using Helix API, EventSub, OAuth, chat bots, and extensions. Use when implementing Twitch login, subscriptions, moderation bots, webhooks, clips, or stream-related workflows.
references:
  - references/overview.md
  - references/authentication.md
  - references/helix-api.md
  - references/eventsub.md
  - references/chat-and-bots.md
  - references/extensions.md
---

# Skill: twitch-dev

Practical workflow for building Twitch developer integrations.

## When to Use

Use this skill when the user asks to build, debug, or ship Twitch features such as:

- Log in with Twitch (OAuth)
- Helix API integrations
- EventSub subscriptions and webhook handling
- IRC/chat bot features and moderation tooling
- Twitch Extensions architecture and deployment prep

## Default Approach

1. Clarify the requested Twitch product area (API, EventSub, Chat, Extension, Embed).
2. Load only the reference file(s) needed for that task.
3. Implement minimum working path first (auth + one endpoint or one subscription).
4. Add reliability checks (signature validation, retries, token refresh).
5. Verify against Twitch docs and return concrete next steps.

## Reading Order

| Task | Files to Read |
|------|---------------|
| Start a new Twitch integration | `references/overview.md` + `references/authentication.md` |
| Call Twitch REST endpoints | `references/helix-api.md` |
| Receive realtime events | `references/eventsub.md` |
| Build chat automation | `references/chat-and-bots.md` |
| Build or debug an Extension | `references/extensions.md` |

## Decision Tree

What does the user need?

- Login, scopes, or token issues -> `references/authentication.md`
- Data reads/writes (channels, users, clips, moderation) -> `references/helix-api.md`
- Realtime notifications (follows, subs, stream state) -> `references/eventsub.md`
- Chat commands or moderation bot -> `references/chat-and-bots.md`
- Overlay or panel app inside Twitch -> `references/extensions.md`

## Implementation Checklist

- Confirm app registration assumptions (redirect URL, app type, scopes).
- Use least-privilege scopes and document why each scope is needed.
- Implement token lifecycle (access + refresh) before feature expansion.
- Validate EventSub signatures and challenge handshakes before processing events.
- Handle Twitch rate limits and transient failures with retry/backoff.
- Link to exact Twitch docs pages used in the final response.

## Output Requirements

When assisting, return:

- Working code or precise diffs for the requested Twitch feature.
- Required Twitch dashboard setup steps.
- Environment variables and secrets expected.
- Local verification steps (example requests/events) and production caveats.

## In This Reference

| File | Purpose |
|------|---------|
| `references/overview.md` | Product map and recommended build sequence |
| `references/authentication.md` | OAuth flows, scopes, token refresh, validation |
| `references/helix-api.md` | Helix request patterns, headers, pagination, errors |
| `references/eventsub.md` | Subscription transport patterns and webhook safety |
| `references/chat-and-bots.md` | IRC/chatbot architecture and moderation workflows |
| `references/extensions.md` | Extension model, auth context, and integration notes |

## Primary Docs

- https://dev.twitch.tv/docs
- https://dev.twitch.tv/docs/api
- https://dev.twitch.tv/docs/authentication
- https://dev.twitch.tv/docs/eventsub
- https://dev.twitch.tv/docs/chat
- https://dev.twitch.tv/docs/extensions
