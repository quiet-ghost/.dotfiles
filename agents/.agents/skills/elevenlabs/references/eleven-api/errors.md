# Errors And Recovery

ElevenLabs API errors use HTTP status codes and usually return JSON with `detail`.

## Error Shape

```json
{
  "detail": {
    "type": "validation_error",
    "code": "invalid_parameters",
    "message": "The 'keyterms' parameter is only supported with the 'scribe_v2' model.",
    "request_id": "3c807fc4c3a1705f9638ecc764a91c01",
    "param": "keyterms"
  }
}
```

Use `code`, not legacy `status`, for logic. Include `request_id` when contacting support.

## Error Types

| Type | HTTP | Meaning | Recovery |
|------|------|---------|----------|
| `validation_error` | 400 | Invalid parameter | Fix payload, model, format, or field |
| `invalid_request` | 400 | Malformed body/content type | Fix JSON, headers, required fields |
| `authentication_error` | 401 | Missing/invalid credential | Check API key, signed URL, token |
| `payment_required` | 402 | Insufficient credits | Stop retries, alert billing owner |
| `authorization_error` | 403 | Missing permission or feature | Check key scopes, plan, resource sharing |
| `not_found` | 404 | Resource ID missing | Verify IDs and workspace/environment |
| `conflict` | 409 | State conflict or duplicate | Refresh state or retry safely |
| `rate_limit_error` | 429 | Rate or concurrency exceeded | Backoff or local queue |
| `internal_error` | 500 | Server issue | Retry with backoff, capture IDs |
| `service_unavailable` | 503 | Temporary outage/capacity | Retry later with backoff |

## Common Codes

| Code | Likely Cause |
|------|--------------|
| `voice_not_found` | Wrong voice ID or resource not shared to workspace/key |
| `model_not_found` | Bad model ID or environment mismatch |
| `unsupported_model` | Model not valid for endpoint or feature |
| `text_too_long` | Exceeded model request character limit |
| `invalid_audio_format` | Unsupported file/codec/container |
| `audio_too_long` | File exceeds endpoint duration limit |
| `invalid_api_key` | Wrong or revoked key |
| `insufficient_permissions` | Key scope or user lacks permission |
| `feature_not_available` | Plan or Enterprise feature missing |
| `concurrent_limit_exceeded` | Active request/job cap hit |
| `rate_limit_exceeded` | Request rate cap hit |
| `system_busy` | Temporary platform capacity pressure |
| `insufficient_credits` | Account quota exhausted |

## SDK Handling

Python:

```python
from elevenlabs import ApiError

try:
    audio = client.text_to_speech.convert(...)
except ApiError as error:
    detail = (error.body or {}).get("detail", {})
    request_id = detail.get("request_id")
    code = detail.get("code")
```

TypeScript SDKs expose typed ElevenLabs errors with `statusCode` and `body` in current docs. Check package version and docs for exact class names.

## Retry Policy

| Status/Code | Retry? | Notes |
|-------------|--------|-------|
| 400 validation | No | Payload bug |
| 401/403 | No | Auth or permission bug |
| 402 | No | Needs billing action |
| 404 | Usually no | ID/workspace mismatch |
| 409 | Maybe | Safe if operation is idempotent |
| 429 rate | Yes | Exponential backoff with jitter |
| 429 concurrency | Wait | Queue until in-flight work completes |
| 500/503 | Yes | Bounded retries with jitter |

## Debug Checklist

1. Capture `request-id`, `x-trace-id`, and full `detail`.
2. Confirm API key belongs to the same workspace and residency environment.
3. Confirm feature and model are available on plan.
4. Check model-specific limits and endpoint support.
5. For client issues, ensure no API key is exposed and tokens are fresh.
6. For webhooks, verify raw body signature handling.
