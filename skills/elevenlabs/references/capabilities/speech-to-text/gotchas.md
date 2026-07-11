# Speech To Text Gotchas

## Limits And Formats

| Gotcha | Fix |
|--------|-----|
| File too large | Max documented size is 3 GB |
| Audio too long | Standard mode supports up to 10 hours; confirm current docs for mode-specific caps |
| Multichannel assumptions | Up to 5 channels; each channel gets speaker ID based on channel |
| Unsupported codec/container | Convert to supported audio/video format |
| HIPAA use | Contact Sales for BAA before PHI workflows |

## Realtime

| Problem | Fix |
|---------|-----|
| Browser auth fails | Use fresh single-use token; never API key |
| `chunk_size_exceeded` | Reduce chunk size |
| `commit_throttled` | Commit less frequently |
| `insufficient_audio_activity` | Send real audio activity or close session |
| No timestamps | Enable timestamp option before connecting |
| Bad transcript from file chunks | Decode and convert to expected sample rate/PCM format |

## Advanced Features

| Feature | Gotcha |
|---------|--------|
| Keyterms | Extra cost; term caps differ for batch/realtime |
| Entities | Extra cost; spans need original transcript offsets |
| No verbatim | Cleaner text but removes filler/false starts |
| Diarization | Not the same as multichannel separation |

## Webhooks

| Issue | Fix |
|-------|-----|
| Signature fails | Preserve raw body and correct header |
| Handler times out | Return 2xx quickly and process async |
| Duplicate events | Deduplicate by request/conversation IDs |
| Local testing | Use HTTPS tunnel such as ngrok |
