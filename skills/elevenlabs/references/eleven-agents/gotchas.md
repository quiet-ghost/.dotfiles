# ElevenAgents Gotchas

## Authentication

| Problem | Fix |
|---------|-----|
| API key in browser | Replace with signed URL or public agent if intended |
| Signed URL expired | Generate a fresh URL; it must start within 15 minutes |
| Signed URL reused across users | Generate one per authenticated session |
| Allowlist blocks local dev | Add exact dev hostname like `localhost:3000` |
| Signed URL and allowlist both configured | Pick one auth mode per agent |

## Tools

| Problem | Fix |
|---------|-----|
| Agent calls wrong tool | Improve tool name, description, and prompt routing |
| Missing parameters | Add required flags and parameter descriptions with formats |
| Client tool not invoked | Ensure code registration name exactly matches config |
| Webhook tool leaks secrets | Use auth connections or secret headers, not prompt vars |
| MCP server risky | Use Always Ask or fine-grained approvals |
| Tool result not remembered | Configure `expects_response` or dynamic variable assignments |

## Telephony

| Problem | Fix |
|---------|-----|
| Twilio verified caller ID cannot receive calls | Verified caller IDs are outbound-only |
| SIP call URI missing identifier | Use `sip:+19991234567@sip.rtc.elevenlabs.io:5060` shape |
| SIP TLS fails | Validate certificates, TLS 1.2+, remote domains for follow-up connections |
| SIP one-way audio | Check UDP RTP firewall, NAT, codec, SRTP settings |
| SIP BYE returns 481 | Send follow-up BYE to Contact URI, not generic shared host |
| Poor call audio | Verify G711/G722 compatibility, jitter, packet loss, bandwidth |

## Privacy And Compliance

| Problem | Fix |
|---------|-----|
| Need HIPAA | Contact Sales and complete BAA before PHI workflows |
| MCP with ZRM/HIPAA | Not supported; choose other integration path |
| Need no retained audio | Disable audio saving and configure retention |
| Need redaction | Enterprise conversation history redaction |
| Post-call webhook in HIPAA mode | Failed webhooks may not retry; design reliable endpoint |

## Latency

| Cause | Mitigation |
|-------|------------|
| High-quality voice/model | Use Flash model, default/synthetic/IVC voices |
| Long agent responses | Prompt for concise replies |
| Slow tool | Play tool-call sound, stream status, optimize backend |
| Geographic distance | Use residency/global routing appropriately |
| WebSocket buffering | Use `flush: true` at turn end and sensible chunking |

## WebSocket Custom Clients

| Requirement | Note |
|-------------|------|
| Ping/pong | Reply to `ping` with `pong` and event ID |
| Audio playback | Queue chunks to prevent overlap |
| Microphone permission | Explain why audio access is needed |
| Cleanup | Close WebSocket and stop microphone streams on unmount |
| Context updates | Use `contextual_update` for non-interrupting state |

## Testing

One passing call is not enough. Agent behavior is probabilistic. Use scenario tests for single-turn quality, tool call tests for action safety, simulation tests for multi-turn flow, and repeated runs for reliability.
