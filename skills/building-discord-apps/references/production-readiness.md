# Production Readiness

## Reliability Principles

- Build idempotent handlers for commands, components, and webhooks.
- Separate fast interaction acknowledgement from slow business logic.
- Persist correlation IDs (`interaction.id`, request IDs) for tracing.
- Retry transient failures with bounded backoff.

## HTTP Rate Limit Handling

Do not hardcode limits. Use response headers and 429 payloads.

Key headers:
- `X-RateLimit-Limit`
- `X-RateLimit-Remaining`
- `X-RateLimit-Reset`
- `X-RateLimit-Reset-After`
- `X-RateLimit-Bucket`
- `X-RateLimit-Scope` (`user`, `global`, `shared`)

On `429`:
- honor `Retry-After` header or `retry_after` field
- pause requests for the affected bucket
- apply jitter before replaying queued requests

## Global and Invalid Request Limits

- Global bot rate limit is separate from route buckets.
- Too many invalid requests can trigger temporary API restrictions.
- Track and alert on spikes of `401`, `403`, and `429`.

## Interaction Endpoint Hardening

- Verify `X-Signature-Ed25519` and `X-Signature-Timestamp` on every request.
- Keep raw request body bytes/utf8 text for signature checks.
- Return `401` for failed signature validation.
- Handle Discord's routine invalid-signature probes correctly.

## Safe Message Defaults

- Use `allowed_mentions` to avoid accidental mass pings.
- Enforce message content and embed limits before API calls.
- Validate user-provided URLs and attachment metadata.

## Gateway Operational Hardening

- Monitor heartbeat ACK delay and reconnect frequency.
- Alert on repeated invalid sessions or intent close codes.
- Persist session data needed for resume (`session_id`, `seq`, `resume_gateway_url`).

## Observability Checklist

- Metrics:
  - interaction ack latency
  - 2xx/4xx/5xx and 429 rates
  - gateway reconnect count
  - command execution duration
- Logs:
  - include app/guild/channel/user IDs when available
  - redact tokens, secrets, and signed headers
- Alerts:
  - sustained 429s
  - signature verification failures spike
  - command registration failures

## Deployment Checklist

1. Secrets loaded from secure runtime source.
2. Endpoint signature checks validated in staging.
3. Commands tested in guild scope.
4. Rate limit queueing enabled.
5. Error handling verified for 401/403/429/5xx.
6. Rollout to global commands completed after validation.

## Incident Triage Shortcuts

- 401 on API calls -> bot token invalid, rotated, or malformed auth header.
- 403 on moderation actions -> missing permission or role hierarchy violation.
- 404 webhook usage -> stale resource; stop retrying same invalid target.
- command timeout -> ack path too slow; defer and finish asynchronously.

## Source Docs

- https://docs.discord.com/developers/topics/rate-limits
- https://docs.discord.com/developers/reference
- https://docs.discord.com/developers/interactions/overview
- https://docs.discord.com/developers/events/gateway
