# Extensions

## Extension Model

- Frontend experiences embedded in Twitch (panels, overlays, components).
- Uses extension context and JWT-related mechanisms for trusted calls.
- Often paired with EBS (Extension Backend Service) for secure server logic.

## Build Guidance

- Separate viewer-facing frontend from privileged backend operations.
- Validate extension identity/context on backend endpoints.
- Keep latency low for overlay interactions during live streams.

## Common Pitfalls

- Trusting client-provided state without backend verification.
- Overloading frontend with privileged logic.
- Forgetting extension-specific review and deployment constraints.

## References

- https://dev.twitch.tv/docs/extensions
