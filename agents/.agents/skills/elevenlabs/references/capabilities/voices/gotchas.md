# Voice Gotchas

| Gotcha | Detail/Fix |
|--------|------------|
| Voice Library API blocked on free tier | Upgrade or use a custom/default voice |
| Default voices expire Dec 31, 2026 | Migrate to replacement voices before then |
| PVC not fully optimized for v3 | Prefer IVC/designed voices for v3 research-preview features |
| Voice access denied | Check workspace sharing and service account permissions |
| Pronunciation differs across voices | Test IPA/dictionaries per voice |
| Voice cannot perform tag | Choose a voice whose samples match the requested delivery |
| Clone sounds noisy | Improve training samples; use Voice Isolator before cloning only when appropriate |
| Accent drift in other languages | Use a voice/accent matching target region |

## Debug Checklist

1. Confirm `voice_id` and workspace/environment.
2. Confirm API key scope and resource sharing.
3. Test the same text with a default voice to isolate voice-specific issues.
4. Test the same voice with a stable model to isolate model-specific issues.
5. Capture model ID, settings, seed, voice ID, request ID, and output format.
