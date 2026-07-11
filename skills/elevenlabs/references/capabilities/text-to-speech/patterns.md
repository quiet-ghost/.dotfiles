# Text To Speech Patterns

## Latency Optimization

Four principles:

| Principle | Implementation |
|-----------|----------------|
| Use Flash | `eleven_flash_v2_5` or `eleven_flash_v2` for realtime |
| Stream | HTTP streaming for known text, WebSocket for live text |
| Use geographic proximity | Inspect `x-region`, use residency or US base URL when appropriate |
| Choose fast voices | Default, synthetic, and IVC usually faster than PVC |

`api.elevenlabs.io` uses global routing by default. Use `https://api.us.elevenlabs.io` to opt out and force USA servers.

## Real-Time LLM To TTS

Use WebSocket when text arrives token-by-token from an LLM.

Pattern:

1. Open WebSocket with Flash model.
2. Send initialization message with voice settings and chunk schedule.
3. Buffer LLM text into speakable fragments, not individual tokens.
4. Send text fragments to WebSocket.
5. Send `flush: true` at end of each conversational turn.
6. Queue returned audio chunks for playback.

## Long-Form Narration

Use `eleven_multilingual_v2` for stable quality. Split text by semantic units, not arbitrary length. Use request stitching when supported.

Chunking guidance:

| Do | Avoid |
|----|-------|
| Split at paragraph or sentence boundaries | Cutting mid-sentence |
| Keep context with previous request IDs | Isolated chunks with no context |
| Track request IDs and costs | Losing raw response headers |
| Concatenate audio after complete chunks | Starting next chunk before prior ID exists |

## Expressive Dialogue

Use `eleven_v3` and text shaping:

| Control | Example |
|---------|---------|
| Audio tag | `[whispers] I never knew.` |
| Ellipses | `I... I thought so.` |
| Capitalization | `That was VERY close.` |
| Dialogue labels | `Speaker 1: [excited] ...` |
| Narrative context | `she said, her voice trembling` |

Descriptive emotional text can be spoken aloud. Plan post-production if you need to remove narration.

## Telephony Output

Use u-law or A-law 8 kHz when integrating with telephony systems. Keep responses short, normalize digits and times, and test with real phone audio.

## Cost Tracking Pattern

Always expose raw headers in server logs or metrics:

```typescript
const { data, rawResponse } = await client.textToSpeech
  .convert(voiceId, { text, modelId: "eleven_v3" })
  .withRawResponse();

metrics.cost = rawResponse.headers.get("character-cost");
metrics.requestId = rawResponse.headers.get("request-id");
```
