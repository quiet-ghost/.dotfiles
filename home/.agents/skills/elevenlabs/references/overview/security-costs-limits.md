# Security, Costs, And Limits

Use this reference for production hardening and account-impact checks.

## Secret Handling

| Credential | Safe Use |
|------------|----------|
| API key | Server-side only, environment variable or secret manager |
| Agent signed URL | Browser/mobile, generated server-side, expires after 15 minutes |
| Realtime Scribe single-use token | Browser STT, generated server-side, expires after 15 minutes |
| Webhook secret | Server-side only, used to verify HMAC signatures |
| Tool auth headers | Store as ElevenLabs workspace secrets or backend secrets |

Never put `ELEVENLABS_API_KEY` in browser, mobile app bundles, public repos, logs, or user-visible config.

## Cost Controls

| Area | Control |
|------|---------|
| TTS | Track `character-cost`, choose Flash when quality tradeoff is acceptable |
| STT | Remember billing is based on audio duration; advanced features can cost extra |
| Sound effects | Duration-specified effects cost per second |
| Voice changer | Charged per processed audio minute equivalent |
| Dubbing | Watch concurrent job limits and plan-specific pricing |
| Agents | Monitor LLM model choice, tool calls, call duration, and post-call analysis |

## Privacy Controls

| Need | Feature |
|------|---------|
| Minimize retained content | Zero Retention Mode where available |
| Control agent history | Retention settings |
| Avoid audio storage | Disable audio saving |
| Redact sensitive history | Conversation history redaction for Enterprise |
| Region-specific storage | Data residency isolated environments |
| HIPAA use | Contact Sales and complete BAA before protected health workflows |

## Webhook Security

Always verify `ElevenLabs-Signature` against the raw request body. Use SDK helpers: JavaScript `constructEvent`, Python `construct_event(rawBody, sig_header, secret)`.

Return HTTP 2xx quickly after durable receipt. Do slow work asynchronously. Make processing idempotent using `event_timestamp`, `conversation_id`, or event-specific IDs.

## Rate And Concurrency Failures

| Error | Meaning | Recovery |
|-------|---------|----------|
| `rate_limit_exceeded` | Too many requests in a short period | Exponential backoff with jitter |
| `concurrent_limit_exceeded` | Too many active generations/jobs | Queue locally until current work completes |
| `system_busy` | Temporary capacity pressure | Retry later with backoff |
| `insufficient_credits` | Account lacks credits | Stop retries and alert billing owner |

## Data Residency

Isolated environments use separate web, API, WebSocket URLs, separate API keys, and mostly blank workspaces. Do not assume resources migrate from global to residency environments.

| Region | API Base | WebSocket Base |
|--------|----------|----------------|
| EU | `https://api.eu.residency.elevenlabs.io` | `wss://api.eu.residency.elevenlabs.io` |
| India | `https://api.in.residency.elevenlabs.io` | `wss://api.in.residency.elevenlabs.io` |
| Singapore | `https://api.sg.residency.elevenlabs.io` | `wss://api.sg.residency.elevenlabs.io` |
