# Media Capabilities

This covers Text to Dialogue, Speech Engine, Voice Changer, Voice Isolator, Dubbing, Sound Effects, Music, Forced Alignment, Image & Video, and Avatars.

## Read Next

| Task | File |
|------|------|
| Multi-speaker expressive dialogue | `dialogue.md` |
| Add voice to your own LLM/chat server | `speech-engine.md` |
| Voice changer, isolator, forced alignment | `voice-transform-and-alignment.md` |
| Dubbing and localization | `dubbing.md` |
| Music and sound effects | `music-and-sfx.md` |
| Image, video, avatars, lip-sync | `image-video.md` |

## Capability Map

| Capability | API/Product | Use |
|------------|-------------|-----|
| Text to Dialogue | API | Multi-speaker expressive scenes using `eleven_v3` |
| Speech Engine | SDK/WebSocket | Add voice to your own server-side chat agent |
| Voice Changer | Speech-to-Speech API | Transform recorded speech into another voice |
| Voice Isolator | Audio Isolation API | Remove background noise from speech |
| Dubbing | ElevenCreative/API | Translate audio/video while preserving speakers |
| Sound Effects | Text-to-Sound Effects API | Generate Foley, ambience, impacts, loops |
| Music | Music API/ElevenCreative | Generate studio-grade songs and sections |
| Forced Alignment | Forced Alignment API | Align transcript text to existing audio |
| Image & Video | ElevenCreative | Generate images, videos, avatars, lip-sync, upscale |

## Text To Dialogue

Read `dialogue.md` for deeper routing.

| Fact | Detail |
|------|--------|
| Model | Only `eleven_v3` |
| Use | Non-realtime expressive dialogue |
| Speakers | No documented hard speaker count limit |
| Request size | Keep total `inputs[].text` <= 2,000 chars for reliable generation |
| Control | Audio tags in each turn text plus `voice_id` per turn |

Do not use Text to Dialogue for realtime conversational agents. Generate multiple variants and let users pick when quality matters.

## Voice Changer

Read `voice-transform-and-alignment.md` for deeper routing.

| Fact | Detail |
|------|--------|
| Model | Prefer `eleven_multilingual_sts_v2`; often better even for English |
| Segment limit | 5 minutes |
| Billing | 1,000 characters per minute processed |
| Noise | `remove_background_noise=true` can reduce environmental noise |
| Output voice | Any cloned/designed/library voice available to your account |

Use Voice Changer when original performance timing/emotion should be preserved but voice identity should change.

## Voice Isolator

Read `voice-transform-and-alignment.md` for deeper routing.

| Fact | Detail |
|------|--------|
| Use | Clean noisy speech in audio/video |
| File size | Up to 500 MB |
| Duration | Up to 1 hour |
| Cost | 1,000 characters per audio minute |
| Streaming | Audio Isolation supports streaming endpoint |

Not specifically optimized for isolating vocals from music.

## Dubbing

Read `dubbing.md` for deeper routing.

| Fact | Detail |
|------|--------|
| Languages | 90+ |
| Automatic Dubbing | Dubbing v2 Alpha, up to 2 GB and 180 minutes |
| Dubbing Studio | Legacy V1, up to 1 GB and 45 minutes, maintenance mode |
| Recommended speakers | Up to 9 unique speakers per file for best quality |
| Concurrency | Self-serve plans up to 5 concurrent jobs; Enterprise default 100 |
| Realtime | Not currently available |

Dubbing v2 API was noted as not live yet in the overview docs; verify current status before implementing.

## Sound Effects

Read `music-and-sfx.md` for deeper routing.

| Parameter | Detail |
|-----------|--------|
| Duration | 0.1 to 30 seconds, optional |
| Looping | Seamless loops for longer ambience/backgrounds |
| Prompt influence | Higher is literal, lower is more creative |
| Output | MP3; WAV 48 kHz for non-looping effects |

Prompt with concrete sound design language: impact, whoosh, ambience, one-shot, loop, stem, braam, glitch, drone.

## Music

Read `music-and-sfx.md` for deeper routing.

| Fact | Detail |
|------|--------|
| Model | `music_v2` is current-generation; `music_v1` remains during transition |
| Duration | 3 seconds to 5 minutes |
| Output | MP3 44.1 kHz 128-192 kbps and WAV |
| Commercial use | Cleared for many commercial uses; verify music terms |
| Finetunes | v1 finetunes only now; v2 finetunes coming |

## Forced Alignment

Read `voice-transform-and-alignment.md` for deeper routing.

| Fact | Detail |
|------|--------|
| Input text | Plain string only, not JSON-wrapped |
| Diarization | Not supported; diarized text can produce bad results |
| File size | Up to 3 GB |
| Duration | Up to 10 hours |
| Text length | Up to 675,000 chars |
| Pricing | Same rate as STT |

## Image & Video / Avatars

Read `image-video.md` for deeper routing.
