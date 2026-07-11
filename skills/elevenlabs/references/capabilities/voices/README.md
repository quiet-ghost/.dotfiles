# Voices

ElevenLabs voices include community library voices, cloned voices, generated Voice Design voices, and remixed voices.

## Voice Types

| Type | Use | Notes |
|------|-----|-------|
| Community | Browse and use shared voices | 10,000+ voices; API not available to free-tier users |
| Instant Voice Clone | Quick clone from short samples | Good for fast iteration |
| Professional Voice Clone | Highest-fidelity clone | Creator plan or above; voice captcha verification |
| Voice Design | Generate a new voice from prompt | Great for characters and creative voices |
| Voice Remixing | Modify a voice you own | Adjust gender, accent, style, pacing, quality |

## Read First

| Task | Files |
|------|-------|
| Pick voice type | `README.md` |
| Use voice APIs | `api.md` |
| Create reliable voices | `patterns.md` |
| Debug access/quality | `gotchas.md` |

## Voice Design

Voice Design creates three previews from a voice description between 20 and 1000 characters. Optional preview text is 100 to 1000 characters.

With Eleven v3, Voice Design can produce voices with broader emotion and audio tag support in previews.

## Cloning

| Clone Type | Guidance |
|------------|----------|
| IVC | Short samples, quick setup, often better for v3 exploration |
| PVC | More training data, higher fidelity, verification required |

For v3, expressive IVC voices should include varied emotional tones. For narrow use cases like commentary, use consistent emotion in samples.

## Managing Voices

Manage voices in My Voices. Add descriptions, tags, categories, and samples. Use voice IDs from saved/library voices in API calls.

## Language Notes

Voices can work across supported languages, but accent fidelity depends on samples or designed attributes. Choose a voice whose accent matches the target language/region for natural output.

## Key Facts

| Fact | Detail |
|------|--------|
| Professional clones | Creator plan or above |
| Voice sharing | PVCs can be shared publicly; IVC and generated voices cannot |
| Default voices | Expire Dec 31, 2026 |
| Voice Library API | Not available to free-tier users |
| Commercial use | Depends on plan and rights to source material |
