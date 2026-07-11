# Speech Engine

Speech Engine adds ElevenLabs voice to your own chat agent. ElevenLabs handles ASR, TTS, turn-taking, and interruptions while your server provides LLM logic.

## Use Speech Engine When

| Need | Why Speech Engine Fits |
|------|------------------------|
| Voice-enable existing chat agent | Keep current server and LLM stack |
| Use custom/fine-tuned/self-hosted LLM | Your server owns inference |
| Full control over routing/tools/context | Your code handles conversation logic |
| Server-side app integration | Attach to Express, Fastify, FastAPI, Starlette, ASGI, etc. |

Use ElevenAgents instead if you want hosted LLM, knowledge base, tools, dashboard workflow, and managed agent configuration.

## Architecture

1. Browser sends user audio to ElevenLabs.
2. ElevenLabs transcribes and sends transcript/history to your server over WebSocket.
3. Your server calls its LLM and streams text back.
4. ElevenLabs converts text to speech and plays audio to the browser.

Each Speech Engine connection represents one conversation.

## JavaScript SDK

Package: `@elevenlabs/elevenlabs-js`.

Get engine resource:

```typescript
const engine = await elevenlabs.speechEngine.get("seng_...");
```

Attach to existing HTTP server:

```typescript
await elevenlabs.speechEngine.attach(engineId, httpServer, "/ws", {
  onTranscript(transcript, signal, session) {
    session.sendResponse(llmStream);
  },
});
```

Standalone server:

```typescript
const server = new SpeechEngine.Server({
  port: 3001,
  onTranscript(transcript, signal, session) {
    session.sendResponse("Hello, how can I help?");
  },
});

server.start();
```

## Key Methods And Events

| API | Use |
|-----|-----|
| `engine.attach(server, path, callbacks)` | Add Speech Engine WebSocket to existing server |
| `engine.verifyRequest(req)` | Verify manual WebSocket upgrade |
| `engine.createSession(ws)` | Wrap accepted WebSocket |
| `session.sendResponse(response)` | Send string, async iterable, or LLM stream |
| `session.close()` | Close conversation |
| `onTranscript(transcript, signal, session)` | Main LLM callback |
| `onInit`, `onClose`, `onDisconnect`, `onError` | Lifecycle callbacks |

The `AbortSignal` in `onTranscript` fires when the user interrupts mid-response. Pass it to your LLM call to cancel stale output.

## Supported LLM Streams

The JS SDK auto-extracts text from OpenAI Responses, OpenAI Chat Completions, Anthropic Messages, and Google Gemini stream formats. For other providers, pass a plain string or async iterable of strings.

## Security

Speech Engine request verification uses `X-Elevenlabs-Speech-Engine-Authorization` JWT signed with the SHA-256 hash of your API key. `attach()` and standalone server verify automatically.

If firewalling your server, allowlist ElevenLabs static egress IPs from the current docs. Residency environments have separate egress IPs.

## Gotchas

| Gotcha | Fix |
|--------|-----|
| Used when hosted agents needed | Use ElevenAgents instead |
| In-flight LLM keeps talking after interruption | Pass `signal` to LLM request and stop stream on abort |
| Manual upgrade lacks verification | Use `verifyRequest()` or `attach()` |
| Firewall blocks ElevenLabs | Allowlist documented egress IPs |
