# ElevenAgents

ElevenAgents builds real-time multimodal voice agents that combine ASR, an LLM or custom LLM, TTS, and turn-taking.

## Read First

| Task | Files |
|------|-------|
| Create an agent | `README.md` + `api.md` |
| Configure behavior | `configuration.md` |
| Add tools, MCP, telephony, tests | `patterns.md` |
| Integrate custom clients | `api.md` |
| Debug auth, calls, privacy, latency | `gotchas.md` |

## Architecture

ElevenAgents coordinates:

| Component | Purpose |
|-----------|---------|
| ASR | Speech recognition from user audio |
| LLM | Agent reasoning; built-in or custom |
| TTS | Voice output across ElevenLabs voices |
| Turn-taking | Timing, interruptions, and conversation flow |

## Build Lifecycle

| Phase | Work |
|-------|------|
| Configure | System prompt, first message, voice, model, language, KB, tools |
| Deploy | Web widget, React/mobile SDKs, WebSocket, SIP, Twilio, WhatsApp |
| Operate | Tests, simulations, analytics, conversation search, post-call webhooks |
| Govern | Auth, allowlists, privacy, retention, data residency, HIPAA/BAA if needed |

## Quickstart Options

| Method | Use When |
|--------|----------|
| Dashboard | Fastest for manual setup and testing |
| CLI | Agents-as-code workflow |
| API/SDK | Provisioning agents programmatically |

Dashboard widget embed:

```html
<elevenlabs-convai agent-id="agent-id"></elevenlabs-convai>
<script src="https://unpkg.com/@elevenlabs/convai-widget-embed" async type="text/javascript"></script>
```

CLI flow:

```bash
npm install -g @elevenlabs/cli
elevenlabs agents init
elevenlabs auth login
elevenlabs agents add "My Assistant" --template assistant
elevenlabs agents push --agent "My Assistant"
```

## Agent Configuration Areas

| Area | Use |
|------|-----|
| First message | Initial spoken greeting |
| System prompt | Behavior, scope, style, policy, procedure |
| Knowledge base | Docs, FAQs, URLs, files, RAG grounding |
| Voice and language | TTS voice, model, speed, multilingual settings |
| Conversation flow | Interruptions, turn-taking, timeout behavior |
| Tools | Client, webhook, MCP, and system tools |
| Personalization | Dynamic variables and overrides |
| Analysis | Success evaluation and data collection |
| Tests | Scenario, tool call, simulation, probabilistic runs |
| Privacy | Retention, audio saving, redaction |

## Good Agent Defaults

| Need | Default |
|------|---------|
| Public demo | Widget with allowlist or signed URL if sensitive |
| Private app | Signed URL generated server-side |
| Real-time quality | Flash TTS, high-quality LLM, short agent responses |
| Tool calling | Clear names, descriptions, parameter formats, prompt instructions |
| Production release | Automated tests plus live monitoring and post-call webhooks |
