# ElevenAPI Authentication

## API Key Auth

Every API request needs the `xi-api-key` header unless using a short-lived token or signed URL flow.

```http
xi-api-key: ELEVENLABS_API_KEY
```

Example raw request:

```bash
curl 'https://api.elevenlabs.io/v1/models' \
  -H 'Content-Type: application/json' \
  -H "xi-api-key: $ELEVENLABS_API_KEY"
```

## API Key Restrictions

Keys can be configured with restrictions:

| Restriction | Use |
|-------------|-----|
| Scope restriction | Limit accessible endpoint groups |
| Credit quota | Cap usage per key |
| IP whitelisting | Enterprise preview, public IP/CIDR only |

Use restricted keys for CI, production services, and partner integrations.

## Server-Side SDK Setup

Python:

```python
from elevenlabs.client import ElevenLabs

client = ElevenLabs(api_key=os.getenv("ELEVENLABS_API_KEY"))
```

TypeScript:

```typescript
import { ElevenLabsClient } from "@elevenlabs/elevenlabs-js";

const client = new ElevenLabsClient({ apiKey: process.env.ELEVENLABS_API_KEY });
```

## Client-Side Auth Patterns

| Scenario | Credential |
|----------|------------|
| ElevenAgents private browser session | Signed URL generated server-side |
| Realtime Speech to Text in browser | Single-use token generated server-side |
| Public agent widget | Public `agent-id` if agent is intended public |
| Direct API in browser | Do not do this with an API key |

## Single-Use Tokens

Some endpoints support single-use tokens so clients can connect without exposing the API key. Realtime Scribe uses this pattern. Generate tokens server-side and return them only to authenticated app users.

Example server token creation for realtime Scribe:

```typescript
const token = await elevenlabs.tokens.singleUse.create("realtime_scribe");
```

Single-use tokens expire after 15 minutes.

## Agent Signed URLs

For private ElevenAgents sessions, server fetches a signed WebSocket URL with the API key, then the client connects using that URL. Signed URLs are valid for initiating a session for 15 minutes.

Do not reuse signed URLs as long-lived user credentials. Generate one per session.

## Service Accounts

For teams, prefer service accounts over personal API keys. Grant access via user groups or resource sharing. Rotate keys by creating a replacement key on the same service account with copied permissions, deploying it, then deleting the old key.

## Security Checklist

| Check | Required |
|-------|----------|
| API key stored outside source control | Yes |
| API key only used server-side | Yes |
| Client auth uses signed URL or single-use token | Yes |
| Webhooks verify raw body signature | Yes |
| Production keys scoped and quota-limited | Recommended |
| Keys rotated after exposure | Required |
