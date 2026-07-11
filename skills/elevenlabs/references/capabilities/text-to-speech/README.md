# Text To Speech

Text to Speech turns text into lifelike audio with voice, model, output format, and voice settings controls.

## Read First

| Task | Files |
|------|-------|
| Generate basic speech | `README.md` + `api.md` |
| Stream audio | `api.md` |
| Tune latency or quality | `patterns.md` + `gotchas.md` |
| Control pronunciation | `configuration.md` + `patterns.md` |
| Debug artifacts | `gotchas.md` |

## Model Choices

| Model | Use |
|-------|-----|
| `eleven_v3` | Most expressive, audio tags, IPA support, Text to Dialogue |
| `eleven_multilingual_v2` | Stable, high-quality, long-form narration |
| `eleven_flash_v2_5` | Low-latency, 32 languages, up to 40k chars |
| `eleven_flash_v2` | Low-latency English, phoneme tag support |

## Output Formats

| Format | Use |
|--------|-----|
| MP3 | Default, broad playback support |
| PCM S16LE | Low-latency audio pipelines |
| u-law / A-law | Telephony |
| Opus | Efficient streaming/real-time use |

Higher quality output formats can require paid tiers and can increase latency.

## Basic SDK Calls

Python:

```python
audio = client.text_to_speech.convert(
    text="Hello, world!",
    voice_id="JBFqnCBsd6RMkjVDRZzb",
    model_id="eleven_v3",
    output_format="mp3_44100_128",
)
```

TypeScript:

```typescript
const audio = await client.textToSpeech.convert("JBFqnCBsd6RMkjVDRZzb", {
  text: "Hello, world!",
  modelId: "eleven_v3",
  outputFormat: "mp3_44100_128",
});
```

## Voice Settings

| Setting | Effect |
|---------|--------|
| `stability` | Consistency versus expressiveness |
| `similarity_boost` | Closeness to source/reference voice |
| `style` | Style exaggeration where supported |
| `use_speaker_boost` | Stronger speaker similarity, possible latency cost |
| `speed` | 0.7 to 1.2; extremes can reduce quality |

For v3, stability is especially important: Creative is more expressive but riskier, Natural is balanced, Robust is most stable but less responsive to directional prompts.

## Key Facts

| Fact | Detail |
|------|--------|
| Determinism | Output is nondeterministic; `seed` can improve consistency |
| Regenerations | Up to 2 free regenerations in dashboard when text/settings unchanged |
| Commercial rights | Paid plans grant commercial use if input rights are owned |
| Long text | Split into chunks and stitch context where supported |
| Voice library API | Free tier cannot use Voice Library voices via API |
