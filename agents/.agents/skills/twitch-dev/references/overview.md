# Twitch Dev Overview

## Core Product Areas

- Helix API: REST endpoints for users, channels, streams, clips, moderation, analytics.
- Authentication: OAuth flows, scope management, token validation, token refresh.
- EventSub: Realtime subscription events via webhooks, WebSockets, or Conduits.
- Chat and Bots: IRC-style chat integration, command handling, moderation interactions.
- Extensions: Interactive viewer experiences embedded on Twitch pages.

## Recommended Build Sequence

1. Register app and set redirect URI.
2. Implement OAuth (user or app tokens as needed).
3. Call one Helix endpoint to validate auth and scope setup.
4. Add EventSub or chat features.
5. Harden reliability (retries, idempotency, signature checks, token refresh).

## Design Principles

- Start with the narrowest scope set; expand only when required.
- Separate user tokens and app access tokens by capability.
- Treat webhooks and chat events as untrusted input.
- Build for replay and retries; event delivery can be repeated.

## Official Documentation Entry

- https://dev.twitch.tv/docs
