# Speech To Text

Speech to Text converts audio/video to transcripts with timestamps, diarization, language detection, keyterm prompting, and entity detection.

## Read First

| Task | Files |
|------|-------|
| Batch transcription | `README.md` + `api.md` |
| Realtime microphone transcription | `api.md` + `configuration.md` |
| Keyterms/entities/webhooks | `patterns.md` |
| Debug formats/limits | `gotchas.md` |

## Models

| Model | Use |
|-------|-----|
| `scribe_v2` | Batch transcription with advanced features |
| `scribe_v2_realtime` | Live transcription with partial and committed transcripts |

## Core Features

| Feature | Notes |
|---------|-------|
| 90+ languages | Smart language detection available |
| Word timestamps | `words[]` includes start/end per token |
| Speaker diarization | Up to 32 speakers in batch |
| Audio event tags | Laughter, applause, and other non-speech events |
| Keyterm prompting | Bias terms; extra cost |
| Entity detection | PII/PHI/PCI and other entities; extra cost |
| No verbatim mode | Removes filler words and disfluencies |

## Basic Batch SDK Calls

Python:

```python
transcription = client.speech_to_text.convert(
    file=audio_data,
    model_id="scribe_v2",
    tag_audio_events=True,
    language_code="eng",
    diarize=True,
)
```

TypeScript:

```typescript
const transcription = await client.speechToText.convert({
  file: audioBlob,
  modelId: "scribe_v2",
  tagAudioEvents: true,
  languageCode: "eng",
  diarize: true,
});
```

## Output Shape

Typical response includes:

| Field | Meaning |
|-------|---------|
| `language_code` | Detected or provided language |
| `language_probability` | Confidence |
| `text` | Full transcript |
| `words` | Timed word/spacing/audio_event entries |
| `speaker_id` | Speaker diarization ID when enabled |
| `entities` | Entity detection output when enabled |
| `transcription_id` | Transcript resource ID when present |

## Input Limits

| Limit | Value |
|-------|-------|
| Max file size | 3 GB |
| Standard duration | Up to 10 hours |
| Multichannel duration | Upstream docs have differed by section; verify current docs before enforcing a hard cap |
| Multichannel channels | Up to 5 |

For exact current duration rules, fetch the current STT docs before enforcing limits in code.
