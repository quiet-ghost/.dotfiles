# ElevenAgents Patterns

## Tool Types

| Tool Type | Runs Where | Use For |
|-----------|------------|---------|
| Client tool | User app/browser/mobile | UI actions, DOM updates, local app callbacks |
| Webhook tool | ElevenLabs server calling your API | Data lookup, actions, CRM, scheduling, order status |
| MCP server | External MCP server | Tool/resource ecosystem integration |
| System tool | ElevenLabs platform | End call, transfer, language detection, DTMF, voicemail |

## Tool Design Rules

| Rule | Reason |
|------|--------|
| Use intuitive names | The LLM selects tools by name and description |
| Avoid acronyms | Reduces wrong tool calls |
| Describe parameter formats | Helps extraction and validation |
| Add sequence rules to prompt | Tool orchestration needs explicit instructions |
| Mock tools in tests | Prevents live side effects during simulation |
| Use high-intelligence LLMs for tools | Some models struggle with parameter extraction |

## Client Tool Pattern

Use client tools for local effects. The tool and parameter names are case-sensitive and must match registered code.

Typical config fields:

| Field | Meaning |
|-------|---------|
| `type: "client"` | Tool executes in client app |
| `expects_response` | Agent waits for result when true |
| `parameters` | LLM-filled parameter schema |

Register in JS client:

```typescript
const conversation = await Conversation.startSession({
  agentId,
  clientTools: {
    logMessage: async ({ message }) => {
      console.log(message);
    },
  },
});
```

## Webhook Tool Pattern

Use webhook tools for server APIs. Prefer least-privilege auth connections or secret headers.

Typical config fields:

| Field | Meaning |
|-------|---------|
| `type: "webhook"` | Tool calls external API |
| `api_schema.url` | Endpoint URL, may include `{path_param}` |
| `method` | GET, POST, PUT, PATCH, DELETE |
| `path_params_schema` | LLM-extracted path values |
| `query_params_schema` | LLM-extracted query values |
| `request_body_schema` | LLM-extracted body values |
| `assignments` | Dynamic variables updated from JSON response |

Supported auth patterns include OAuth2 client credentials, OAuth2 JWT, Basic Auth, bearer token, and custom headers.

## MCP Pattern

ElevenLabs supports MCP servers over SSE and HTTP streamable transport. Use MCP when a third-party or internal tool server already exposes an MCP interface.

Security posture:

| Approval Mode | Use |
|---------------|-----|
| Always Ask | Default for external or write-capable tools |
| Fine-Grained | Auto-approve read-only tools, require approval for writes |
| No Approval | Only for trusted low-risk private servers |

MCP is not currently available for Zero Retention Mode or HIPAA-required users.

## Telephony Patterns

| Integration | Use |
|-------------|-----|
| Native Twilio | Import Twilio numbers or verified caller IDs |
| SIP trunking | Existing PBX/SIP infrastructure |
| Batch calls | Programmatic outbound campaigns |
| WhatsApp | Messaging channel integrations |

For SIP production, prefer TLS transport and required media encryption. Systems must support G711 or G722 codecs or resample.

## Post-Call Automation

Use post-call webhooks to store transcripts, update CRM records, trigger follow-ups, and persist state for future calls.

Stateful pattern:

1. Pass app user ID as a dynamic variable at conversation start.
2. On post-call webhook, store `conversation_id`, transcript summary, collected data, and outcomes.
3. On next call, retrieve previous state and pass it as dynamic variables.
4. Tell the prompt how to use previous context without over-sharing.

## Testing Pattern

| Test Type | Use |
|-----------|-----|
| Scenario | Evaluate one next response with LLM criteria |
| Tool Call | Verify exact tool and parameter use |
| Simulation | End-to-end multi-turn conversation |
| Probabilistic | Repeat 2-20 times to measure flakiness |

Run from CLI:

```bash
elevenlabs agents test agent_7101k5zvyjhmfg983brhmhkd98n6
```

Use `repeat_count` via API/SDK for probabilistic testing.
