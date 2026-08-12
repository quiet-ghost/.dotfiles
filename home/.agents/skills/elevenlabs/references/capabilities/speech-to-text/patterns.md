# Speech To Text Patterns

## Batch Transcription Pipeline

1. Validate file size, duration, and MIME type.
2. Upload with `scribe_v2`.
3. Enable `diarize`, `tag_audio_events`, keyterms, or entities only when needed.
4. For long jobs, set `webhook=true` and persist `request_id`.
5. Store transcript, words, speakers, entities, and source metadata.
6. Apply redaction or retention policy before downstream use.

## Realtime Captioning

1. Generate single-use token server-side.
2. Connect browser with `useScribe` or `Scribe.connect`.
3. Show `partial_transcript` as live text.
4. Commit `committed_transcript` to chat/history.
5. If timestamps needed, set include timestamps and handle `committed_transcript_with_timestamps`.

## Manual Audio Chunking

When not using microphone capture helpers:

| Step | Guidance |
|------|----------|
| Decode | Convert audio to expected PCM/u-law format |
| Chunk | Send reasonably sized chunks, often 4-8 KB |
| Pace | Add small delays if simulating real-time audio |
| Commit | Use manual commit when segment boundary is known |
| Close | Cleanly close after final transcript |

## Keyterm Prompting Pattern

Use keyterms for brand spellings and uncommon proper nouns:

```typescript
const transcription = await client.speechToText.convert({
  file: audioBlob,
  modelId: "scribe_v2",
  keyterms: ["ElevenLabs", "Scribe"],
});
```

For realtime raw WebSocket, keyterms are query parameters repeated once per term.

## Entity Redaction Pattern

Use entity detection to mark sensitive spans, then redact before storage or display.

Important: entity detection returns transcript character spans. Keep original transcript stable while applying redaction, or spans can become invalid.

## Async Webhook Pattern

Webhook payload shape includes:

| Field | Use |
|-------|-----|
| `type` | Event type, such as speech transcription |
| `data.request_id` | Correlate to submitted job |
| `data.webhook_metadata` | Custom metadata from request |
| `data.transcription` | Transcript result |

Return 2xx after durable receipt and process in background.
