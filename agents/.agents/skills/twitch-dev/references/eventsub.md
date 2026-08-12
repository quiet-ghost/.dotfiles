# EventSub

## Transport Choices

- Webhook: Good for backend services that can receive HTTPS callbacks.
- WebSocket: Good for apps that prefer a persistent outbound connection.
- Conduit: Good for larger-scale event routing architectures.

## Webhook Safety Requirements

- Verify message signatures before parsing payloads.
- Handle verification challenge flow correctly.
- Enforce replay protection using message IDs and timestamps.
- Respond quickly; perform heavier work asynchronously.

## Subscription Lifecycle

1. Create subscription with desired type, version, and condition.
2. Persist subscription IDs and statuses.
3. Monitor revocations and renew or recreate subscriptions.
4. Build idempotent handlers to tolerate duplicate deliveries.

## Common Pitfalls

- Ignoring signature verification in local-first prototypes.
- Processing events before challenge handshake completes.
- Missing logic for subscription revocation/recovery.

## References

- https://dev.twitch.tv/docs/eventsub
- https://dev.twitch.tv/docs/eventsub/handling-webhook-events
