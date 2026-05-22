# Authentication

## Use Cases

- Viewer or broadcaster login (authorization code flow).
- Server-to-server access where user context is not required (app access token).
- Long-lived integrations requiring refresh tokens.

## Baseline Flow

1. Send user to Twitch authorize URL with required scopes.
2. Exchange code for access token (and refresh token when provided).
3. Store tokens securely and associate them with the Twitch user.
4. Validate token before critical calls.
5. Refresh token on expiry or 401 responses.

## Scope Strategy

- Request minimum scopes needed for current features.
- Keep scope-to-feature mapping documented.
- Fail fast with clear errors when missing scope is detected.

## Common Pitfalls

- Using app token for user-protected endpoints.
- Not rotating/refreshing tokens before expiry.
- Redirect URI mismatch between code and Twitch app settings.
- Missing CSRF state parameter in OAuth callback flow.

## References

- https://dev.twitch.tv/docs/authentication
- https://dev.twitch.tv/docs/authentication/getting-tokens-oauth
