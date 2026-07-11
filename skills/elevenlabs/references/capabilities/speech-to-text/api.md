# Speech To Text API

## Endpoint Families

| Endpoint | Use |
|----------|-----|
| Create transcript | Batch STT upload |
| Get transcript | Fetch async result |
| Delete transcript | Remove transcript resource |
| Realtime WebSocket | Stream audio and receive partial/committed transcripts |

## Batch Parameters

| Parameter | Use |
|-----------|-----|
| `file` | Audio/video file/blob/stream |
| `model_id` / `modelId` | Usually `scribe_v2` |
| `language_code` | Optional language hint, otherwise auto-detect |
| `tag_audio_events` | Include non-speech events |
| `diarize` | Speaker diarization |
| `keyterms` | Bias important terms |
| `entity_detection` | Detect entities such as PII/PHI/PCI |
| `webhook` | Deliver async result to webhook |

## Realtime Client-Side Flow

Use this for microphone transcription in browser apps.

1. Server creates a single-use token for `realtime_scribe`.
2. Browser connects using `@elevenlabs/client` or `@elevenlabs/react`.
3. Client streams microphone or chunked audio.
4. App handles partial and committed transcript events.

React hook shape:

```typescript
const scribe = useScribe({
  modelId: "scribe_v2_realtime",
  onPartialTranscript: (data) => console.log(data.text),
  onCommittedTranscript: (data) => console.log(data.text),
  onCommittedTranscriptWithTimestamps: (data) => console.log(data.words),
});

await scribe.connect({ token, microphone: { echoCancellation: true } });
```

## Realtime Events

Sent:

| Event | Use |
|-------|-----|
| `input_audio_chunk` | Send audio chunks |

Received:

| Event | Use |
|-------|-----|
| `session_started` | Connection accepted |
| `partial_transcript` | Live interim text |
| `committed_transcript` | Finalized segment |
| `committed_transcript_with_timestamps` | Finalized segment plus word timings |

## Realtime Error Events

| Error | Meaning |
|-------|---------|
| `auth_error` | Bad token/key |
| `quota_exceeded` | Usage quota hit |
| `input_error` | Invalid audio/parameters |
| `commit_throttled` | Too many commits |
| `rate_limited` | Too many requests |
| `queue_overflow` | Processing queue full |
| `resource_exhausted` | Server capacity |
| `session_time_limit_exceeded` | Session max duration |
| `chunk_size_exceeded` | Reduce audio chunk size |
| `insufficient_audio_activity` | Not enough audio to keep session |
