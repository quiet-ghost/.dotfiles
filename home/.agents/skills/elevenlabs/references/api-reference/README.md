# API Reference

Use this as the endpoint-family router. For exact fields, fetch the current endpoint `.md`, OpenAPI, or AsyncAPI docs.

## API Docs Resources

| Resource | Use |
|----------|-----|
| `https://elevenlabs.io/docs/llms.txt` | Current docs and API index |
| Clean endpoint pages | Append `.md` to docs endpoint page |
| OpenAPI JSON/YAML | Raw REST schemas |
| AsyncAPI JSON/YAML | WebSocket/event schemas |
| Docs MCP | `https://elevenlabs.io/docs/_mcp/server` |

## Top-Level Families

| Family | Read |
|--------|------|
| ElevenAgents API | `../eleven-agents/api.md` and `endpoints.md` |
| Text to Speech | `../capabilities/text-to-speech/api.md` |
| Speech to Text | `../capabilities/speech-to-text/api.md` |
| Voices | `../capabilities/voices/api.md` |
| Media capabilities | `../capabilities/media/README.md` |
| Studio API | `../eleven-creative/README.md` |
| Workspace/Admin | `../administration/README.md` |

## Base URLs

| Environment | REST Base | WebSocket Base |
|-------------|-----------|----------------|
| Global | `https://api.elevenlabs.io` | `wss://api.elevenlabs.io` |
| US forced | `https://api.us.elevenlabs.io` | `wss://api.us.elevenlabs.io` if supported |
| EU residency | `https://api.eu.residency.elevenlabs.io` | `wss://api.eu.residency.elevenlabs.io` |
| India residency | `https://api.in.residency.elevenlabs.io` | `wss://api.in.residency.elevenlabs.io` |
| Singapore residency | `https://api.sg.residency.elevenlabs.io` | `wss://api.sg.residency.elevenlabs.io` |

## Auth Summary

| API Area | Auth |
|----------|------|
| Server REST APIs | `xi-api-key` header |
| TTS WebSocket | `xi-api-key` header or init payload, per current docs |
| Agent private client | Signed URL from server |
| Realtime Scribe browser | Single-use token from server |
| Webhooks | HMAC signature validation |

## Implementation Rule

Do not generate code from this endpoint map alone. It is a router. Fetch current endpoint docs when writing payloads.
