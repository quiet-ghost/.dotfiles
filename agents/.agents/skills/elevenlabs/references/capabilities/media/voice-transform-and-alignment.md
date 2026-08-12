# Voice Transform, Isolation, And Alignment

Use this for Voice Changer, Voice Isolator, and Forced Alignment.

## Voice Changer

Transforms source audio into a target voice while preserving timing, accent, and emotional delivery.

| Fact | Detail |
|------|--------|
| API | Speech-to-Speech convert and stream |
| Model | Prefer `eleven_multilingual_sts_v2` |
| Segment length | 5 minutes |
| Billing | 1,000 characters per processed audio minute |
| Noise control | `remove_background_noise=true` can help |

Use it to replace a performance voice, preserve actor delivery, or make character voices consistent across recordings.

## Voice Isolator

Cleans noisy speech from audio/video files.

| Fact | Detail |
|------|--------|
| API | Audio Isolation convert and stream |
| File size | Up to 500 MB |
| Duration | Up to 1 hour |
| Supported sources | Common audio and video files |
| Cost | 1,000 characters per minute |

Not specifically optimized for extracting vocals from music.

## Forced Alignment

Aligns provided transcript text to existing spoken audio.

| Fact | Detail |
|------|--------|
| Input text | Plain string only |
| Diarization | Not supported |
| File size | Up to 3 GB |
| Duration | Up to 10 hours |
| Text length | Up to 675,000 chars |
| Pricing | Same rate as STT |

Use for subtitle timing, audiobook word timings, and transcript-to-audio alignment. Do not pass diarized text; it can produce unexpected results.

## Debug Checklist

1. Confirm source file format and duration.
2. Confirm target voice access for Voice Changer.
3. Split long Voice Changer recordings into <=5 minute chunks.
4. For Forced Alignment, strip speaker labels and pass plain transcript text.
5. Capture request IDs and original media metadata.
