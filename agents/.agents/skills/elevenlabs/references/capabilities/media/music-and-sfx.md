# Music And Sound Effects

Use this for Eleven Music and Text-to-Sound Effects.

## Eleven Music

Eleven Music generates studio-grade music from prompts, composition plans, or previous songs.

| Fact | Detail |
|------|--------|
| Current model | `music_v2` |
| Older model | `music_v1` remains during transition |
| Duration | 3 seconds to 5 minutes |
| Outputs | MP3 44.1 kHz 128-192 kbps and WAV |
| Commercial use | Broad commercial clearance, verify music terms |
| API | Available for paid subscribers |

Music v2 improves prompt adherence, section-by-section composition, mid-track genre transitions, fast rap, complex vocals, inpainting, and embedded sound effects.

## Music Finetunes

| Topic | Detail |
|-------|--------|
| Current support | Music v1 finetunes |
| v2 finetunes | Coming per docs |
| Dataset | Non-copyrighted tracks you own; screened automatically |
| Training time | About 5-10 minutes |
| Enterprise | Can request proprietary owned-catalog training without third-party screening |

Existing v1 finetunes are not compatible with Music v2.

## Sound Effects

Sound Effects generates Foley, ambience, impacts, loops, musical components, and cinematic sound design.

| Parameter | Detail |
|-----------|--------|
| Duration | Optional, 0.1 to 30 seconds |
| Looping | Seamless repeat for ambience/backgrounds |
| Prompt influence | High is literal, low is creative |
| Outputs | MP3; WAV 48 kHz for non-looping effects |

Prompt terms that work well: impact, whoosh, ambience, one-shot, loop, stem, braam, glitch, drone.

## Sound Effects Prompt Patterns

| Type | Example |
|------|---------|
| Simple | `Glass shattering on concrete` |
| Sequence | `Footsteps on gravel, then a metallic door opens` |
| Ambience | `Soft rain on a cabin roof, seamless loop` |
| Musical | `90s hip-hop drum loop, 90 BPM` |
| Cinematic | `Deep brass braam with sub-bass impact` |

## Gotchas

| Gotcha | Fix |
|--------|-----|
| Need full song | Use Music, not Sound Effects |
| Need loop longer than 30s | Generate looping ambience and repeat client-side |
| Need exact sequence timing | Generate segments and layer in post |
| Music terms/commercial use | Verify current plan and music terms |
