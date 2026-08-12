# Dubbing

Dubbing translates audio/video while preserving each speaker's tone, timing, and emotional delivery.

## Product Modes

| Mode | Use | Limits/Notes |
|------|-----|--------------|
| Automatic Dubbing | Fast self-serve dubbing | Dubbing v2 Alpha, up to 2 GB and 180 minutes |
| Dubbing Studio | Granular transcript/speaker edits | Legacy V1, up to 1 GB and 45 minutes, maintenance mode |
| Productions | Human-verified managed service | Contact Productions |

Dubbing v2 API status has changed in docs over time. Verify current docs before implementing API creation flows.

## Capabilities

| Capability | Notes |
|------------|-------|
| Speaker separation | Detects multiple speakers, including overlap |
| Voice preservation | Retains identity, pace, style, emotion |
| 90+ languages | Broad localization coverage |
| Background audio | Keeps music/effects/ambience |
| Source inputs | Files, direct URLs, YouTube, X, TikTok, Vimeo |

## Cloning Strength

Dubbing v2 uses cloning strength. Default value 7 works for most content. Higher values favor voice similarity but may sound less natural across languages and can preserve source accent. Lower values improve target-language naturalness at cost of voice resemblance.

## Limits And Costs

| Topic | Detail |
|-------|--------|
| Recommended speakers | Up to 9 unique speakers per file |
| Self-serve concurrency | Up to 5 concurrent jobs |
| Enterprise concurrency | Default 100 concurrent jobs |
| Realtime dubbing | Not currently available |
| Failed/cancelled Studio jobs | Credits refunded |
| Dubbing v2 failed jobs | Not charged per docs |

## Gotchas

| Gotcha | Fix |
|--------|-----|
| Dubbing v2 API availability unclear | Fetch current docs before coding |
| Dubbing Studio is V1/maintenance | Use only when transcript-level edits are required |
| Too many concurrent jobs | Queue locally; wait for existing jobs |
| Stuck queued/loading | Cancel and resubmit per docs |
| Watermark discount expected | Dubbing v2 has no watermark-for-credit-discount toggle |
