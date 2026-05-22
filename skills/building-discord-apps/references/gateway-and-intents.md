# Gateway and Intents

## When to Use Gateway

Prefer Gateway when your app needs:
- real-time event stream processing
- local state synchronized with Discord events
- high-frequency updates where polling is not viable

For pure slash-command apps, HTTP interactions are usually simpler.

## Connection Lifecycle (High Level)

1. Fetch Gateway URL (`/gateway` or `/gateway/bot`) and cache it.
2. Connect via WebSocket (`wss://gateway.discord.gg/?v=10&encoding=json`).
3. Receive `Hello (op 10)` with `heartbeat_interval`.
4. Start heartbeat loop (`op 1`) with jitter.
5. Send `Identify (op 2)` with token, intents, and properties.
6. Receive `Ready` dispatch and cache `session_id` + `resume_gateway_url`.
7. On disconnect, attempt `Resume (op 6)` with `session_id` + last `seq`.

## Critical Reliability Rules

- If heartbeat ACK (`op 11`) is not received in time, reconnect.
- Keep and update last non-null sequence (`s`) from dispatch events.
- Prefer resume flow before full reconnect+identify.
- Reconnect using `resume_gateway_url`, not the initial URL.

## Gateway Intents

Intents are bitfields provided in `Identify` to choose event groups.

Common intents for bots:
- `GUILDS (1 << 0)`
- `GUILD_MESSAGES (1 << 9)`
- `GUILD_MESSAGE_REACTIONS (1 << 10)`
- `DIRECT_MESSAGES (1 << 12)`

Privileged intents:
- `GUILD_MEMBERS`
- `GUILD_PRESENCES`
- `MESSAGE_CONTENT`

Privileged intents must be enabled in app settings, and may require approval for verified apps.

## Gateway Limits to Respect

- 120 gateway events per connection per 60 seconds.
- Identify calls are globally constrained; excessive identify attempts can invalidate sessions.
- Identify bursts are constrained by `max_concurrency` buckets.

## Sharding Basics

- Required when app scale grows (hard cap: 2500 guilds per shard).
- Include `shard: [shard_id, num_shards]` in Identify.
- Routing formula:

```text
shard_id = (guild_id >> 22) % num_shards
```

## Intents and HTTP Side Effects

Intent configuration can also affect some HTTP endpoints. Example: listing guild members requires the `GUILD_MEMBERS` intent to be enabled for the application.

## Common Failure Patterns

- Passing privileged intents without enabling them -> close code `4014`.
- Invalid intent bitmask -> close code `4013`.
- Sending payloads over 4096 bytes -> close code `4002`.
- Treating reconnect as fatal rather than expected lifecycle behavior.

## Source Docs

- https://docs.discord.com/developers/events/gateway
- https://docs.discord.com/developers/events/gateway-events
- https://docs.discord.com/developers/topics/opcodes-and-status-codes
