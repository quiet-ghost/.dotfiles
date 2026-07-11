# SDKs, Streaming, And Webhooks

## Official SDKs

| SDK | Package | Use |
|-----|---------|-----|
| Python | `elevenlabs` | Server, scripts, audio processing |
| Node/TypeScript | `@elevenlabs/elevenlabs-js` | Server, CLIs, backend apps |
| Agents JS client | `@elevenlabs/client` | Browser voice agent sessions |
| Agents React | `@elevenlabs/react` | React hooks and UI integration |
| Scribe JS | `@elevenlabs/client` | Realtime STT browser client |
| Scribe React | `@elevenlabs/react` | `useScribe` realtime STT hook |

## Streaming Modes

| Mode | Use When | Notes |
|------|----------|-------|
| Regular HTTP | Need complete audio file | Simplest, highest time-to-first-audio |
| HTTP streaming | Input text is known upfront | Returns audio chunks progressively |
| TTS WebSocket | Input text arrives live from LLM/user | Bidirectional; not for `eleven_v3` |
| Agent WebSocket | Real-time voice conversation | Use SDK unless custom protocol needed |
| Realtime STT WebSocket | Live transcription | Use single-use token in browsers |

HTTP streaming is supported for Text to Speech, Voice Changer, and Audio Isolation.

## TTS HTTP Streaming

Python:

```python
audio_stream = client.text_to_speech.stream(
    text="This is a test",
    voice_id="JBFqnCBsd6RMkjVDRZzb",
    model_id="eleven_multilingual_v2",
)

for chunk in audio_stream:
    if isinstance(chunk, bytes):
        process(chunk)
```

TypeScript:

```typescript
const audioStream = await client.textToSpeech.stream("JBFqnCBsd6RMkjVDRZzb", {
  text: "This is a test",
  modelId: "eleven_v3",
});

for await (const chunk of audioStream) {
  process(chunk);
}
```

## TTS WebSocket Essentials

Endpoint shape: `wss://api.elevenlabs.io/v1/text-to-speech/{voice_id}/stream-input?model_id={model_id}`.

Important fields:

| Field | Use |
|-------|-----|
| `text` | Send text chunks; `""` closes and flushes |
| `voice_settings` | Stability, similarity, speaker boost, speed |
| `generation_config.chunk_length_schedule` | Control buffering threshold |
| `flush: true` | Force buffered text generation now |
| `alignment` | Optional word/character timing in output |

Tips:

| Tip | Why |
|-----|-----|
| Send a single space to keep open | Empty string closes connection |
| Use `flush: true` at end of turn | Reduces conversational delay |
| Keep default chunk schedule unless measured | Lower latency can reduce quality |
| Use Flash models | Best real-time latency |

## Webhooks

Common event types include `post_call_transcription`, `post_call_audio`, `call_initiation_failure`, `speech_to_text_transcription`, and voice removal events.

Webhook rules:

| Rule | Detail |
|------|--------|
| Verify HMAC | Use raw body and `ElevenLabs-Signature` |
| Return 2xx quickly | Prevent retries and auto-disable |
| Make idempotent | Retries reuse the same payload |
| Preserve raw body | JSON parsers can break signature verification |
| Handle chunked audio webhooks | Audio payloads may stream large base64 MP3 |

Retry behavior for configured webhooks: up to 5 attempts, with delays around immediate, 30s, 2m, 8m, and 30m. Retryable statuses include 5xx, 429, and 408. 4xx normally do not retry.

Auto-disable can occur after 10 or more consecutive failures if the last success was over 7 days ago or never happened.

## Webhook Verification Examples

FastAPI:

```python
payload = await request.body()
signature = request.headers.get("elevenlabs-signature")
event = client.webhooks.construct_event(
    rawBody=payload.decode("utf-8"),
    sig_header=signature,
    secret=WEBHOOK_SECRET,
)
```

Express:

```typescript
app.post("/webhook", express.text({ type: "application/json" }), async (req, res) => {
  const event = await client.webhooks.constructEvent(
    req.body,
    req.headers["elevenlabs-signature"],
    process.env.WEBHOOK_SECRET,
  );

  res.status(200).json({ received: true });
});
```
