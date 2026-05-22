# Helix API

## Request Essentials

- Use `Authorization: Bearer <token>` and `Client-Id: <client_id>` headers.
- Match token type to endpoint requirements (user vs app token).
- Capture and log Twitch request IDs for debugging.

## Pagination and Throughput

- Handle cursor-based pagination (`after`/`before`).
- Respect rate limits; add backoff on 429 or transient 5xx.
- Cache safe reads where practical to reduce request volume.

## Error Handling Pattern

- `401/403`: token invalid, expired, or missing scope.
- `429`: throttle and retry with jitter.
- `5xx`: retry with bounded attempts; surface degraded mode if needed.

## Implementation Checklist

- Encapsulate common headers in one API client.
- Normalize error shapes before returning to app logic.
- Keep endpoint-specific scope requirements near callsites.

## References

- https://dev.twitch.tv/docs/api
- https://dev.twitch.tv/docs/api/reference
