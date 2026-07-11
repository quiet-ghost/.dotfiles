# ElevenLabs Overview

ElevenLabs provides APIs and product surfaces for AI audio, transcription, voice agents, creative workflows, and phone reception.

## Major Surfaces

| Surface | Use For | Read Next |
|---------|---------|-----------|
| ElevenAPI | Programmatic TTS, STT, voices, music, effects, webhooks | `../eleven-api/README.md` |
| ElevenAgents | Real-time voice agents across web, mobile, and telephony | `../eleven-agents/README.md` |
| Speech Engine | Add ElevenLabs voice to your own chat agent or LLM server | `../capabilities/media/speech-engine.md` |
| ElevenCreative | Studio, audiobooks, dubbing, flows, Audio Native | `../eleven-creative/README.md` |
| Reception AI | SMB phone receptionist, booking, knowledge base | `../reception-ai/README.md` |
| Administration | Workspaces, billing, service accounts, SSO, data residency | `../administration/README.md` |

## Capability Map

| Need | Capability |
|------|------------|
| Generate speech from text | Text to Speech |
| Generate multi-speaker scenes | Text to Dialogue |
| Voice-enable your own LLM server | Speech Engine |
| Transcribe audio/video | Speech to Text |
| Transcribe live microphone audio | Realtime Speech to Text |
| Clone, design, or remix voices | Voices |
| Transform source speech into another voice | Voice Changer |
| Remove background noise | Voice Isolator |
| Translate media while preserving speakers | Dubbing |
| Generate sound design | Sound Effects |
| Generate songs or stems | Eleven Music |
| Align transcript to existing audio | Forced Alignment |
| Generate images/videos or talking avatars | Image & Video / Avatars |

## Docs Access

Use `https://elevenlabs.io/docs/llms.txt` for the current docs index. Use `.md` pages for clean Markdown. Use `llms-full.txt` only for broad research because it is large.

## Implementation Workflow

1. Identify the product surface and capability.
2. Read its local reference entry.
3. Fetch current upstream docs for exact request fields.
4. Implement with official SDKs unless raw HTTP or WebSocket is required.
5. Verify with a small request, mock, or dashboard test.

## Cross-Cutting Rules

| Rule | Reason |
|------|--------|
| Never expose `ELEVENLABS_API_KEY` client-side | API keys authorize account usage and quota |
| Use signed URLs or single-use tokens in browsers | Short-lived credentials reduce blast radius |
| Record request IDs and trace IDs | Support and debugging need exact request context |
| Treat audio and transcripts as sensitive | They can contain personal or regulated data |
| Design webhook handlers as idempotent | Retries deliver the same payload again |
| Balance model quality and latency | Higher quality models can increase response time |

## Key URLs

| Purpose | URL |
|---------|-----|
| API base | `https://api.elevenlabs.io` |
| US-only API base | `https://api.us.elevenlabs.io` |
| Voice library | `https://elevenlabs.io/app/voice-library` |
| API keys | `https://elevenlabs.io/app/settings/api-keys` |
| Webhooks | `https://elevenlabs.io/app/settings/webhooks` |
| Agents dashboard | `https://elevenlabs.io/app/agents` |
| Phone numbers | `https://elevenlabs.io/app/agents/phone-numbers` |
