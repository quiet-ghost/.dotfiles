# Quickstart

## Goal

Build a minimal Discord app that:
- receives interactions over HTTP
- responds to a slash command
- registers commands via the REST API

## Prerequisites

- Discord application in the Developer Portal
- Node.js 18+
- Public HTTPS URL for local development (for example ngrok)

## Required Secrets and IDs

- `APP_ID` (Application ID)
- `PUBLIC_KEY` (for interaction signature verification)
- `BOT_TOKEN` (if your app uses bot-authenticated endpoints)

Store these in `.env`. Never commit them.

## App Configuration Checklist

1. In Installation settings, enable supported contexts:
   - `Guild Install` for server installs
   - `User Install` for user installs
2. Add scopes:
   - User install: `applications.commands`
   - Guild install: `applications.commands` and `bot` (if needed)
3. Set least-privilege bot permissions.
4. Configure Interaction Endpoint URL to `https://<public-host>/interactions`.

## Minimal HTTP Interaction Server (Node + Express)

```js
import "dotenv/config";
import express from "express";
import nacl from "tweetnacl";

const app = express();

app.use(express.json({
  verify: (req, _res, buf) => {
    req.rawBody = buf.toString("utf8");
  },
}));

app.post("/interactions", (req, res) => {
  const signature = req.get("X-Signature-Ed25519") || "";
  const timestamp = req.get("X-Signature-Timestamp") || "";
  const rawBody = req.rawBody || "";

  const isValid = nacl.sign.detached.verify(
    Buffer.from(timestamp + rawBody),
    Buffer.from(signature, "hex"),
    Buffer.from(process.env.PUBLIC_KEY, "hex"),
  );

  if (!isValid) {
    return res.status(401).send("invalid request signature");
  }

  if (req.body.type === 1) {
    return res.json({ type: 1 }); // PING -> PONG
  }

  if (req.body.type === 2 && req.body?.data?.name === "ping") {
    return res.json({
      type: 4,
      data: {
        content: "pong",
        allowed_mentions: { parse: [] },
      },
    });
  }

  return res.status(400).json({ error: "unsupported interaction" });
});

app.listen(3000, () => {
  console.log("Listening on :3000");
});
```

Notes:
- Every interaction must receive an initial response within 3 seconds.
- Interaction tokens stay valid for follow-ups for 15 minutes.

## Register a Test Guild Command

Use guild commands first during development because they update quickly.

```bash
curl -X POST "https://discord.com/api/v10/applications/$APP_ID/guilds/$GUILD_ID/commands" \
  -H "Authorization: Bot $BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "ping",
    "description": "Health check",
    "type": 1
  }'
```

For global commands, replace `/guilds/$GUILD_ID/commands` with `/commands`.

## Smoke Test

1. Start app server.
2. Expose port via ngrok or equivalent.
3. Save Interaction Endpoint URL in app settings.
4. Install app to test server and/or user account.
5. Run `/ping` and verify bot responds.

## Next Reads

- [Interactions and Commands](./interactions-and-commands.md)
- [OAuth, Installation, and Permissions](./oauth-installation-and-permissions.md)
- [Production Readiness](./production-readiness.md)

## Source Docs

- https://docs.discord.com/developers/quick-start/getting-started
- https://docs.discord.com/developers/interactions/overview
