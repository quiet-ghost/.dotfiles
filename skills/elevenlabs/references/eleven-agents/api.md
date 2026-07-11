# ElevenAgents API And SDKs

## Endpoint Families

| Family | Representative Operations |
|--------|---------------------------|
| Agents | Create, get, list, update, delete, duplicate, link, simulate |
| Branches and versions | Branch CRUD, merge, drafts, deployments, version metadata |
| Conversations | List, get, delete, audio, signed URL, WebRTC token, feedback |
| Tools | CRUD, dependent agents, executions |
| Knowledge base | Documents from URL/text/file, folders, RAG, search, size, summaries |
| Tests | CRUD, run, folders, invocations, summaries |
| Phone numbers | CRUD/import, SIP outbound, Twilio outbound/register, batch calling |
| Integrations | WhatsApp, MCP servers, tool approvals, environment variables |
| Analytics | Live count, dashboard metrics, users, conversation search |

Read `../api-reference/endpoints.md` for the broader endpoint map.

## Create Agent With SDK

Python shape:

```python
response = client.conversational_ai.agents.create(
    name="My voice agent",
    tags=["test"],
    conversation_config={
        "tts": {"voice_id": "aMSt68OGf4xUZAnLpTU8", "model_id": "eleven_flash_v2"},
        "agent": {
            "first_message": "Hi, how can I help you today?",
            "prompt": {"prompt": prompt},
        },
    },
)
```

TypeScript shape:

```typescript
const agent = await client.conversationalAi.agents.create({
  name: "My voice agent",
  tags: ["test"],
  conversationConfig: {
    tts: { voiceId: "aMSt68OGf4xUZAnLpTU8", modelId: "eleven_flash_v2" },
    agent: {
      firstMessage: "Hi, how can I help you today?",
      prompt: { prompt },
    },
  },
});
```

Fetch current endpoint docs for exact schema before writing production payloads.

## Client WebSocket

Endpoint: `wss://api.elevenlabs.io/v1/convai/conversation?agent_id={agent_id}`.

For private agents, fetch a signed URL server-side:

```bash
curl -X GET "https://api.elevenlabs.io/v1/convai/conversation/get-signed-url?agent_id=<agent-id>" \
  -H "xi-api-key: <api-key>"
```

Then connect client to returned `signed_url`.

## Common WebSocket Events

| Event | Direction | Use |
|-------|-----------|-----|
| `conversation_initiation_client_data` | Client -> server | Initial context, dynamic variables, overrides |
| `user_audio_chunk` | Client -> server | Base64 user audio chunks |
| `contextual_update` | Client -> server | Non-interrupting context update |
| `pong` | Client -> server | Reply to server ping |
| `user_transcript` | Server -> client | User speech transcript |
| `agent_response` | Server -> client | Agent text response |
| `agent_response_correction` | Server -> client | Corrected response text |
| `agent_chat_response_part` | Server -> client | Streaming text in text-only conversations |
| `audio` | Server -> client | Base64 agent audio plus optional alignment |
| `interruption` | Server -> client | Conversation interruption signal |
| `ping` | Server -> client | Keepalive and latency measurement |

## SDK Surfaces

| SDK | Use |
|-----|-----|
| Python Agents SDK | Desktop/server voice sessions, CLI-style scripts |
| JavaScript client | Browser session control and client tools |
| React SDK | Hooks for web apps and widget-like UI |
| React Native SDK | Cross-platform mobile voice agents |
| Swift SDK | iOS native apps |
| Kotlin SDK | Android native apps |
| Raw WebSocket | Custom clients and low-level integrations |

## Post-Call Webhook Types

| Type | Data |
|------|------|
| `post_call_transcription` | Transcript, analysis, metadata, dynamic variables |
| `post_call_audio` | Base64 full MP3 audio plus IDs |
| `call_initiation_failure` | Failed outbound call reason and provider metadata |
