# Models, Limits, And Selection

Use this reference when choosing models, estimating limits, or debugging latency and concurrency.

## Text To Speech Models

| Model ID | Best For | Languages | Character Limit |
|----------|----------|-----------|-----------------|
| `eleven_v3` | Most expressive speech, drama, multi-speaker dialogue | 70+ | 5,000 |
| `eleven_multilingual_v2` | Stable high-quality long-form narration | 29 | 10,000 |
| `eleven_flash_v2_5` | Low-latency real-time apps | 32 | 40,000 |
| `eleven_flash_v2` | Low-latency English apps | English | 30,000 |

Use Flash for interactive systems and Agents Platform. Use Multilingual v2 when number normalization and long-form stability matter. Use v3 for expressive dialogue and audio tags.

## Speech To Text Models

| Model ID | Best For | Notes |
|----------|----------|-------|
| `scribe_v2` | Batch transcription | 90+ languages, keyterms, entities, diarization |
| `scribe_v2_realtime` | Live transcription | 90+ languages, around 150 ms model latency, partial and committed transcripts |

Scribe v2 supports word timestamps, speaker diarization up to 32 speakers, dynamic audio tagging, smart language detection, keyterm prompting, and entity detection.

## Other Models

| Model ID | Use |
|----------|-----|
| `eleven_multilingual_sts_v2` | Voice changer / speech-to-speech |
| `eleven_english_sts_v2` | English voice changer |
| `eleven_ttv_v3` | Text-to-voice design with v3 |
| `eleven_text_to_sound_v2` | Sound effects |
| `music_v2` | Current-generation music |
| `music_v1` | Older music model during transition |

## Deprecated Or Replaced

`scribe_v1`, `eleven_monolingual_v1`, and `eleven_multilingual_v1` are deprecated and scheduled for removal on July 9, 2026. `eleven_turbo_v2_5` and `eleven_turbo_v2` are effectively replaced by Flash models.

## Model Selection Defaults

| Use Case | Prefer |
|----------|--------|
| High-fidelity narration | `eleven_multilingual_v2` |
| Expressive characters | `eleven_v3` |
| Real-time TTS | `eleven_flash_v2_5` |
| English-only low latency | `eleven_flash_v2` |
| Batch STT | `scribe_v2` |
| Realtime STT | `scribe_v2_realtime` |
| Speech-to-speech | `eleven_multilingual_sts_v2` |
| Music | `music_v2` when available |

## Concurrency Facts

Plan limits vary by product and model. Public plans include lower concurrent request caps than Enterprise. Speech to Text has elevated concurrency. Response headers can include `current-concurrent-requests` and `maximum-concurrent-requests`.

Concurrency is not requests per minute. It depends on how long requests run and how bursts are shaped.

## Scale Testing Guidance

| Do | Avoid |
|----|-------|
| Simulate real users and conversation cadence | Firing raw requests in one burst only |
| Ramp traffic over minutes | Instant max load |
| Add jitter to request timing and text size | Perfectly synchronized requests |
| Capture latency and error codes | Only checking success count |
| Use WebSockets for real-time TTS | Large HTTP calls for live LLM output |

## Headers To Capture

| Header | Use |
|--------|-----|
| `character-cost` | Generation cost tracking |
| `request-id` | Support/debug correlation |
| `x-trace-id` | Deeper trace correlation |
| `current-concurrent-requests` | Runtime concurrency monitoring |
| `maximum-concurrent-requests` | Plan concurrency ceiling |
| `x-region` | Backend region serving request |
