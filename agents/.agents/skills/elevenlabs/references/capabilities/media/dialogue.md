# Text To Dialogue

Text to Dialogue creates expressive multi-speaker dialogue from text using `eleven_v3`.

## When To Use

| Use | Do Not Use |
|-----|------------|
| Podcasts, games, audiobooks, scripted scenes | Real-time conversational agents |
| Multiple speakers with distinct voices | Long unchunked books |
| Non-realtime creative generation | Deterministic production without review |

## Key Facts

| Fact | Detail |
|------|--------|
| Model | `eleven_v3` only |
| Realtime | Not intended for realtime agents |
| Speakers | No documented hard speaker count limit |
| Reliable request size | Keep total `inputs[].text` <= 2,000 chars |
| Control | Audio tags in each turn text, `voice_id` per turn |
| Determinism | Nondeterministic; `seed` can improve consistency |

## Prompting

Use audio tags in square brackets inside each dialogue turn:

```text
"[giggling] That's really funny!"
"Well, [sigh] I'm not sure what to say."
"[cautiously] Hello, is this seat-"
"[jumping in] Free? [cheerfully] Yes it is."
```

Tags are natural-language instructions, not a closed enum. Use `../text-to-speech/configuration.md` for more v3 audio tag guidance.

## Output Formats

Supports the same broad output families as TTS: MP3, PCM S16LE, u-law, A-law, and Opus. Higher quality formats can require paid tiers.

## Production Pattern

1. Split script into short dialogue scenes.
2. Assign a stable `voice_id` to each speaker.
3. Add tags only where they help delivery.
4. Generate multiple candidates for important scenes.
5. Let a user/editor select the best take.
6. Concatenate and master audio downstream.

## Gotchas

| Gotcha | Fix |
|--------|-----|
| Tags can be spoken or misread | Test with chosen voice and edit in post |
| Long requests become unreliable | Split under recommended text size |
| Not realtime | Use ElevenAgents or TTS WebSocket instead |
| Voice cannot perform tag | Pick a voice with matching training style |
