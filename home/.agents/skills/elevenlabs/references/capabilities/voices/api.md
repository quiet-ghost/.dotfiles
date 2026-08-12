# Voices API

## Endpoint Families

| Family | Use |
|--------|-----|
| Voices | List, get, update, delete voices |
| Voice settings | Get/update settings |
| Shared voice library | Search and add shared voices |
| Instant Voice Cloning | Create quick clone |
| Professional Voice Cloning | Create/update/train, samples, verification |
| Voice samples | Get sample audio, delete samples |
| Voice Design | Create voice previews and save generated voice |
| Voice Remix | Remix owned voices and stream previews |
| Similar voices | Find voices similar to uploaded/input audio |

Fetch current API docs for exact schema before implementing clone creation or PVC training flows.

## Common Concepts

| Field | Use |
|-------|-----|
| `voice_id` | Required by TTS, Voice Changer, dialogue turns |
| `name` | Human readable label |
| `description` | Search/manage context |
| `labels` / tags | Categorization |
| `settings` | Default voice settings |
| samples | Training or preview audio |

## Voice Usage In TTS

TypeScript:

```typescript
const audio = await client.textToSpeech.convert(voiceId, {
  text,
  modelId: "eleven_v3",
});
```

Python:

```python
audio = client.text_to_speech.convert(
    voice_id=voice_id,
    text=text,
    model_id="eleven_v3",
)
```

## Voice Design Inputs

| Input | Limit |
|-------|-------|
| Voice description | 20 to 1000 characters |
| Preview text | 100 to 1000 characters |
| Previews | 3 generated voice previews |

## Voice Access Checks

If `voice_not_found` or `voice_access_denied` occurs, verify:

1. Voice ID is correct.
2. Voice belongs to the same workspace/environment.
3. Resource is shared with the service account/API key.
4. Plan allows the chosen voice source via API.
