# ElevenAPI

ElevenAPI is the programmatic interface for audio generation, transcription, voices, music, dubbing, webhooks, and platform resources.

## Read First

| Task | Files |
|------|-------|
| First SDK request | `README.md` + `authentication.md` |
| Build streaming audio | `sdks-streaming-webhooks.md` + capability refs |
| Handle webhooks | `sdks-streaming-webhooks.md` |
| Debug failures | `errors.md` |
| Find endpoints | `../api-reference/README.md` + `../api-reference/endpoints.md` |

## Installation

| Language | Package |
|----------|---------|
| Python | `pip install elevenlabs` |
| TypeScript/JavaScript | `npm install @elevenlabs/elevenlabs-js` |

Use `.env` for local development:

```env
ELEVENLABS_API_KEY=<your_api_key_here>
```

## First TTS Request

Python:

```python
from elevenlabs.client import ElevenLabs

client = ElevenLabs(api_key="your_api_key")

audio = client.text_to_speech.convert(
    text="The first move is what sets everything in motion.",
    voice_id="JBFqnCBsd6RMkjVDRZzb",
    model_id="eleven_v3",
    output_format="mp3_44100_128",
)
```

TypeScript:

```typescript
import { ElevenLabsClient } from "@elevenlabs/elevenlabs-js";

const client = new ElevenLabsClient({ apiKey: process.env.ELEVENLABS_API_KEY });

const audio = await client.textToSpeech.convert("JBFqnCBsd6RMkjVDRZzb", {
  text: "The first move is what sets everything in motion.",
  modelId: "eleven_v3",
  outputFormat: "mp3_44100_128",
});
```

## Core API Families

| Family | Use |
|--------|-----|
| Text to Speech | Create speech, stream, timestamps, WebSocket input |
| Speech to Text | Batch transcripts and realtime Scribe |
| Voices | Library, cloning, design, remix, settings |
| Agents | Agent lifecycle, conversations, tools, phone numbers, tests |
| Music | Compose, stream, plans, stems |
| Dubbing | Dubbing jobs, audio, transcripts |
| Sound Effects | Text-to-sound effects |
| Voice Changer | Speech-to-speech convert and stream |
| Audio Isolation | Speech cleanup convert and stream |
| Webhooks | Event delivery and HMAC validation |
| Workspace | Service accounts, usage analytics, members, sharing |

## Raw Response Metadata

Use raw responses when you need generation costs or debugging IDs.

| Header | Meaning |
|--------|---------|
| `character-cost` | Billed character cost |
| `request-id` | Request correlation ID |
| `x-trace-id` | Trace correlation ID |
| `x-region` | Region serving request |

## Current Docs

Fetch exact current pages before implementing non-trivial endpoint payloads. Endpoint docs can change faster than this skill.
