# Text To Speech Gotchas

## Model Support

| Gotcha | Detail |
|--------|--------|
| TTS WebSocket does not support `eleven_v3` | Use Flash for real-time WebSocket TTS |
| Request stitching does not support `eleven_v3` | Use v2/Flash where stitching matters |
| Phoneme tags are limited | `eleven_flash_v2` support; v3 uses native IPA |
| PVCs may be slower | Prefer default/synthetic/IVC for low latency |
| Default voices expire | Default voices are being replaced and expire Dec 31, 2026 |

## Text Quality

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Phone number read oddly | No normalization | Preprocess or prompt LLM to expand digits |
| Strange pauses/artifacts | Too many break tags | Reduce tags, use punctuation/natural text |
| Emotion mismatch | Voice samples do not match target emotion | Pick a better voice or lower expectations |
| Inconsistent output | Nondeterministic model | Use `seed`, regenerate, or select best output |
| Chunk prosody changes | No stitching/context | Use request IDs or larger semantic chunks |

## WebSocket

| Problem | Fix |
|---------|-----|
| Connection closes unexpectedly | Send single space keepalive before 20s idle |
| Final text not generated quickly | Send `flush: true` or empty string to close |
| Latency still high | Check chunk schedule, model, voice, region, network |
| Quality drops after lowering thresholds | Restore default chunk schedule |
| Phoneme dictionary ignored | Add `enable_ssml_parsing=true` for WebSocket |

## Limits

| Area | Limit |
|------|-------|
| `eleven_v3` TTS | 5,000 chars |
| `eleven_multilingual_v2` | 10,000 chars |
| `eleven_flash_v2_5` | 40,000 chars |
| `eleven_flash_v2` | 30,000 chars |
| Text to Dialogue reliable size | Keep total `inputs[].text` <= 2,000 chars |

## Debug Data To Capture

Capture `request-id`, `x-trace-id`, `character-cost`, model ID, voice ID, output format, text length, latency, and `x-region`.
