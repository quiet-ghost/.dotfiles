# Speech To Text Configuration

## Batch Versus Realtime

| Requirement | Choose |
|-------------|--------|
| Files, recordings, long videos | Batch `scribe_v2` |
| Live microphone or conversation | Realtime `scribe_v2_realtime` |
| Web app microphone | Realtime with single-use token |
| Server stream from URL | Realtime server-side WebSocket |
| Need async completion | Batch with `webhook=true` |

## Realtime Browser Auth

Never expose the API key. Generate a single-use token server-side:

```typescript
const token = await client.tokens.singleUse.create("realtime_scribe");
```

Then return the token to authenticated users only. Tokens expire after 15 minutes.

## Audio Options

Realtime supports PCM and u-law formats at common sample rates. For file transcription, ElevenLabs supports common audio/video containers including MP3, WAV, FLAC, M4A, WebM, MP4, AVI, MKV, MOV, WMV, FLV, MPEG, and 3GPP.

Normalize audio sample rate/format in your app if the source library produces incompatible chunks.

## Keyterms

| Mode | Max Terms | Max Characters Per Term |
|------|-----------|-------------------------|
| Batch `scribe_v2` | 1000 | 50 |
| Realtime `scribe_v2_realtime` | 50 | 20 |

Use keyterms for product names, uncommon names, brands, and domain terms. Keyterms rely on context; they should not force incorrect transcription when context does not fit.

## Entity Detection

Enable with `entity_detection` / `entityDetection`. Use categories such as `pii`, `phi`, `pci`, or `all`, or specific entity labels.

Common labels:

| Category | Examples |
|----------|----------|
| PII | name, email_address, phone_number, ssn, credit_card, dob |
| PHI | condition, drug, injury, blood_type, medical_process |
| PCI | credit_card, credit_card_expiration, cvv |
| Other | language, organization, routing_number, religion |

Entity detection costs extra. Use it when results drive redaction, compliance, or structured extraction.

## Webhook Transcription

Set `webhook=true` on batch conversion to receive completion notification. Configure workspace webhooks first. Verify HMAC and handle idempotently.
