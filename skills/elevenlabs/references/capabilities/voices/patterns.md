# Voice Patterns

## Choosing A Voice

| Goal | Best Choice |
|------|-------------|
| Lowest latency | Default, synthetic, or IVC |
| Highest clone fidelity | PVC |
| Character creation | Voice Design or Voice Library |
| Brand variant | Voice Remixing on owned clone/design |
| Multilingual consistency | Voice with matching accent/language samples |

## Recording For Clones

| Do | Avoid |
|----|-------|
| Use clean audio with minimal noise | Music, room echo, overlapping speakers |
| Include natural continuous speech | Tiny disconnected clips only |
| Match target emotion/use case | Training neutral only for expressive target |
| Use varied emotion for v3 expressive voices | Expecting tags to override unsuitable voice |
| Keep microphone and environment consistent | Mixed devices and compression artifacts |

## Voice Design Prompting

Include specific age, gender presentation, accent, tone, pacing, energy, use case, and emotional range.

Example:

```text
Warm female British narrator in her early 30s, calm but expressive, clear studio quality, gentle pacing, suited for premium audiobook narration and reflective documentary voiceover.
```

## Voice Remixing Pattern

Use remixing when you own the source voice and need controlled variation:

| Change | Example Prompt |
|--------|----------------|
| Accent | "Make this voice sound lightly Australian while preserving identity." |
| Age | "Slightly older and more authoritative." |
| Style | "More energetic and conversational for ads." |
| Quality | "Cleaner studio quality with reduced rasp." |

## Voice Library Workflow

1. Search by accent, use case, tone, age, gender, or style.
2. Preview voices with representative text.
3. Add selected voice to collection.
4. Test with target model and output format.
5. Store voice ID in app config, not hardcoded across code.
