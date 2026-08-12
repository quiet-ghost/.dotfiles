---
name: elevenlabs
description: Comprehensive ElevenLabs platform skill covering ElevenAPI, ElevenAgents, Speech Engine, ElevenCreative, Reception AI, text-to-speech, speech-to-text, voices, dubbing, music, Image & Video, avatars, webhooks, SDKs, telephony, workspaces, and API reference tasks. Use for any ElevenLabs development, integration, troubleshooting, or documentation task.
references:
  - overview
  - eleven-api
  - eleven-agents
  - capabilities
  - administration
  - api-reference
---

# ElevenLabs Platform Skill

Use this skill for building, debugging, or documenting ElevenLabs integrations. Route by user goal, then read only the relevant reference files.

## Source Of Truth

ElevenLabs docs are AI-friendly:

| Resource | URL |
|---------|-----|
| Full docs index | `https://elevenlabs.io/docs/llms.txt` |
| Full docs bundle | `https://elevenlabs.io/docs/llms-full.txt` |
| Clean page markdown | Append `.md` to any docs page URL |
| Section index | Append `/llms.txt` to any section URL |
| Docs MCP server | `https://elevenlabs.io/docs/_mcp/server` |

When exact endpoint fields, SDK method names, or plan limits matter, fetch the current `.md` page before coding.

## How To Use This Skill

### Reference File Structure

Heavy topics use the 5-file pattern:

| File | Purpose | When To Read |
|------|---------|--------------|
| `README.md` | Overview, task routing, core concepts | Always first |
| `api.md` | Endpoints, SDK methods, WebSocket events | Writing code |
| `configuration.md` | Setup, auth, dashboard, runtime config | Project setup |
| `patterns.md` | Production patterns and examples | Implementation |
| `gotchas.md` | Limits, deprecations, failures | Debugging |

Small topics use a single `README.md`.

### Reading Order

1. Start with this file's decision tree.
2. Read the target `README.md`.
3. Add `api.md` for code, `configuration.md` for setup, `patterns.md` for design, or `gotchas.md` for debugging.

## Quick Decision Trees

### "I need to generate or transform audio"

```
Need audio?
|- Text to speech, streaming, latency -> capabilities/text-to-speech/
|- Transcription, diarization, realtime STT -> capabilities/speech-to-text/
|- Voice library, cloning, design, remix -> capabilities/voices/
|- Multi-speaker dialogue -> capabilities/media/README.md (Text to Dialogue)
|- Add voice to your own chat/LLM server -> capabilities/media/speech-engine.md
|- Dubbing, music, sound effects -> capabilities/media/README.md
|- Image, video, avatars, lip-sync -> capabilities/media/image-video.md
|- Clean noisy speech -> capabilities/media/README.md (Voice Isolator)
|- Change a recorded voice -> capabilities/media/README.md (Voice Changer)
|- Align transcript to existing audio -> capabilities/media/README.md (Forced Alignment)
```

### "I need to build a voice agent"

```
Need ElevenAgents?
|- Create or update agents -> eleven-agents/README.md + api.md
|- Configure prompts, voices, KB, auth -> eleven-agents/configuration.md
|- Add tools, MCP, dynamic variables -> eleven-agents/patterns.md
|- Web, mobile, WebSocket, telephony -> eleven-agents/api.md + patterns.md
|- Tests, evals, analytics, webhooks -> eleven-agents/patterns.md
|- Debug calls, privacy, latency -> eleven-agents/gotchas.md
```

### "I need API basics"

```
Need ElevenAPI?
|- Install SDK / first request -> eleven-api/README.md
|- API keys / service tokens -> eleven-api/authentication.md
|- Streaming / WebSockets / raw headers -> eleven-api/sdks-streaming-webhooks.md
|- Webhooks -> eleven-api/sdks-streaming-webhooks.md
|- Errors / retries / concurrency -> eleven-api/errors.md
|- Endpoint families -> api-reference/README.md + endpoints.md
```

### "I need workspace or compliance setup"

```
Need admin?
|- Billing / usage / credits -> administration/README.md
|- Workspaces / seats / sharing -> administration/README.md
|- Service accounts / API keys -> administration/README.md
|- SSO / SCIM -> administration/README.md
|- Data residency / ZRM / HIPAA -> administration/README.md
```

### "I need no-code product docs"

```
Need product docs?
|- ElevenCreative Studio, audiobooks, flows -> eleven-creative/README.md
|- Audio Native embeds -> eleven-creative/README.md
|- Reception AI receptionist -> reception-ai/README.md
```

## Product Index

### Platform Basics

| Product | Entry File |
|---------|------------|
| Overview | `./references/overview/README.md` |
| Models, limits, costs | `./references/overview/models.md` |
| Security, privacy, cost controls | `./references/overview/security-costs-limits.md` |
| API endpoint map | `./references/api-reference/README.md` |

### Developer Platform

| Product | Entry File |
|---------|------------|
| ElevenAPI | `./references/eleven-api/README.md` |
| Authentication | `./references/eleven-api/authentication.md` |
| SDKs, streaming, webhooks | `./references/eleven-api/sdks-streaming-webhooks.md` |
| Errors | `./references/eleven-api/errors.md` |
| ElevenAgents | `./references/eleven-agents/README.md` |

### Capabilities

| Product | Entry File |
|---------|------------|
| Text to Speech | `./references/capabilities/text-to-speech/README.md` |
| Speech to Text | `./references/capabilities/speech-to-text/README.md` |
| Voices | `./references/capabilities/voices/README.md` |
| Media capabilities | `./references/capabilities/media/README.md` |
| Speech Engine | `./references/capabilities/media/speech-engine.md` |
| Image & Video / Avatars | `./references/capabilities/media/image-video.md` |

### Product Surfaces

| Product | Entry File |
|---------|------------|
| ElevenCreative | `./references/eleven-creative/README.md` |
| Reception AI | `./references/reception-ai/README.md` |
| Administration | `./references/administration/README.md` |

## Implementation Defaults

Prefer these unless the user or repo says otherwise:

| Need | Default |
|------|---------|
| Server-side API | Official SDK: Python `elevenlabs` or JS `@elevenlabs/elevenlabs-js` |
| Browser auth | Signed URLs for agents or single-use tokens for realtime STT; never expose API keys |
| TTS quality | `eleven_v3` for expressiveness, `eleven_multilingual_v2` for stable long-form, Flash for latency |
| Realtime TTS | WebSocket with Flash model; HTTP streaming when input text is ready upfront |
| STT | `scribe_v2` for batch, `scribe_v2_realtime` for live transcription |
| Voice agents | Signed URL for private clients, tools with explicit descriptions, tests before launch |
| Webhooks | Verify HMAC, preserve raw body, return 2xx quickly, make handlers idempotent |
| Debugging | Capture `request-id`, `x-trace-id`, `character-cost`, concurrency headers, and `x-region` |
