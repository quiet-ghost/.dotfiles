# Text To Speech Configuration

## Voice Selection

Choose the voice before over-tuning model settings. Voice training data heavily affects pacing, emotion, and accent.

| Voice Type | Notes |
|------------|-------|
| Default/synthetic | Often fastest |
| Community Voice Library | Large selection; not API-accessible on free tier |
| Instant Voice Clone | Quick custom voice, often suitable for real-time |
| Professional Voice Clone | Highest fidelity, can be slower, Creator+ plan |
| Voice Design | Prompt-generated character voices |

## Pronunciation Controls

| Model/Mode | Control |
|------------|---------|
| `eleven_v3` | Native IPA in text wrapped with `/.../` |
| `eleven_flash_v2` | SSML phoneme tags and pronunciation dictionaries |
| Other models | Alias tags or text preprocessing |

### v3 IPA

Use standard IPA wrapped in forward slashes:

```text
The city of "/ˌsænfrənˈsɪskoʊ/" is located in California.
```

v3 IPA is strong but not perfectly deterministic. Include stress markers for multi-syllable words.

### v2 Phoneme Tags

For `eleven_flash_v2`, use phoneme tags. CMU Arpabet is often more reliable than IPA:

```xml
<phoneme alphabet="cmu-arpabet" ph="M AE1 D IH0 S AH0 N">Madison</phoneme>
```

Phoneme tags work for individual words. Names with multiple words need separate tags per word.

## Pronunciation Dictionaries

Pronunciation dictionaries support PLS/TXT style rules with phoneme or alias replacements. Searches are case-sensitive and the first match wins.

Use dictionaries for:

| Use | Example |
|-----|---------|
| Brand terms | `ElevenLabs` |
| Names | `Claughton` -> `Cloffton` |
| Acronyms | `UN` -> `United Nations` |
| Technical terms | Product or medical terms |

For WebSocket phoneme dictionaries, include `enable_ssml_parsing=true` in the WebSocket URI.

## Text Normalization

Flash v2.5 may misread phone numbers, dates, currency, URLs, addresses, abbreviations, units, and keyboard shortcuts if raw text is passed. Normalize text in the LLM prompt or preprocessing layer.

Prompt instruction example:

```text
Convert output text into a format suitable for speech. Expand numbers, symbols, URLs, dates, times, currency, and abbreviations into clear spoken words.
```

## Audio Tags And v3

`eleven_v3` uses square-bracket audio tags such as `[whispers]`, `[laughs]`, `[sighs]`, `[sarcastic]`, `[excited]`, `[strong French accent]`, and `[sings]`.

Tags are not guaranteed enums. Match tags to the selected voice. A serious voice may not convincingly giggle; a shouting voice may not whisper well.
