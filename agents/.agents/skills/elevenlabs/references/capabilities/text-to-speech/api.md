# Text To Speech API

## Endpoint Families

| Endpoint Family | Use |
|-----------------|-----|
| Create speech | Return complete generated audio |
| Create speech with timestamps | Audio plus timing alignment |
| Stream speech | HTTP chunked audio stream |
| Stream speech with timestamps | Streaming audio plus timing |
| TTS WebSocket | Bidirectional real-time text input |
| Multi-context WebSocket | Real-time contexts for more advanced voice agents |

Fetch current API reference for exact request/response schema before implementing.

## Convert Versus Stream

| Method | Use When |
|--------|----------|
| `convert` | Need complete file or simple generation |
| `stream` | Text is ready but playback should begin early |
| WebSocket | Text arrives incrementally from an LLM |

## HTTP Streaming

Python:

```python
response = client.text_to_speech.stream(
    voice_id="JBFqnCBsd6RMkjVDRZzb",
    output_format="mp3_22050_32",
    text="This is a test",
    model_id="eleven_multilingual_v2",
)

for chunk in response:
    if chunk:
        write(chunk)
```

TypeScript:

```typescript
const audioStream = await client.textToSpeech.stream("JBFqnCBsd6RMkjVDRZzb", {
  text: "This is a test",
  modelId: "eleven_v3",
  outputFormat: "mp3_44100_128",
});

for await (const chunk of audioStream) {
  write(chunk);
}
```

## WebSocket

Endpoint shape:

```text
wss://api.elevenlabs.io/v1/text-to-speech/{voice_id}/stream-input?model_id={model_id}
```

WebSocket TTS does not support `eleven_v3`.

Initialize with a first message containing a space, settings, generation config, and auth. Send text chunks as they arrive. Send `""` to close and flush.

Important message fields:

| Field | Purpose |
|-------|---------|
| `text` | Text chunk, space keepalive, or empty close |
| `voice_settings` | Stability, similarity, boost |
| `generation_config.chunk_length_schedule` | Buffer thresholds before audio generation |
| `flush` | Force generation of buffered text |
| `pronunciation_dictionary_locators` | Must be set in initialization message |

## Raw Response Headers

Use raw responses when stitching or tracking cost:

| Header | Use |
|--------|-----|
| `request-id` | Stitch context and debugging |
| `character-cost` | Cost tracking |
| `x-trace-id` | Debug correlation |

## Request Stitching

Use `previous_request_ids` / `previousRequestIds` to preserve prosody across chunks. Request IDs must be from completed requests and should be no older than two hours. Request stitching is not available for `eleven_v3`.
