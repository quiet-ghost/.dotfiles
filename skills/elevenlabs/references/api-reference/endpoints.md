# Endpoint Family Map

This is a representative endpoint map, not a complete schema reference.

## ElevenAgents

| Category | Representative Operations |
|----------|---------------------------|
| Agent lifecycle | Create, get, list, update, delete, duplicate, get link, simulate, stream simulate |
| Versioning | Branches list/create/get/update/merge, drafts create/delete, deployments create, version metadata |
| Conversations | List/get/delete, audio, signed URL, WebRTC token, feedback, file upload/delete, SIP messages |
| Conversation intelligence | Run analysis/evaluation, text search, smart search, topics, tags CRUD/assign |
| Tools | Tool CRUD, dependent agents, tool executions |
| Knowledge base/RAG | Documents from URL/text/file, content, chunks, source URL, refresh, folders, RAG compute/get/overview/batch/delete, search, size, summaries |
| Testing/ops | Tests CRUD/run/summaries, test folders, invocations, users, analytics live count |
| Telephony/channels | Phone numbers CRUD/import, SIP outbound, Twilio outbound/register, Exotel outbound, WhatsApp accounts and outbound calls/messages, batch calling jobs |
| Platform config | Widget, workspace settings, secrets, dashboard, environment variables, LLM list/calculate, MCP servers/tools/approval policies/tool config |
| Realtime | Agent WebSockets |

## Media And Audio APIs

| Category | Representative Operations |
|----------|---------------------------|
| Text to Speech | WebSocket, multi-context WebSocket, create speech, speech with timestamps, stream, stream with timestamps |
| Speech to Text | Realtime, create transcript, get transcript, delete transcript |
| Music | Compose, stream, detailed compose, composition plan, video-to-music, upload music, stem separation |
| Speech Engine | WebSocket, engine create/get/update/delete/list |
| Voices | List/get/update/delete, similar voices, shared library, IVC, PVC, samples, verification, settings |
| Text to Dialogue | Create/stream dialogue, with or without timestamps |
| Voice Changer | Speech-to-speech convert and stream |
| Voice Design/Remix | Design voice, create voice, remix voice, stream preview |
| Sound Effects | Create sound effect |
| Audio Isolation | Convert, stream, history list/delete |
| Dubbing | List/create/get/delete dub, dubbed audio, transcripts, beta segment/speaker/render/language operations |
| Forced Alignment | Create alignment |
| Pronunciation Dictionaries | Create from file/rules, get/update/download/list, add/remove rules |
| Audio Native | Create project, get settings, update project/content from URL |

## ElevenCreative Studio API

| Category | Representative Operations |
|----------|---------------------------|
| Projects | CRUD, convert, update content, snapshots, muted tracks |
| Audio | Stream project/chapter audio, archive snapshot |
| Chapters | CRUD, convert, snapshots |
| Creation | Create podcast, pronunciation dictionaries |

## Core Resources

| Category | Representative Operations |
|----------|---------------------------|
| History | List/get/delete generated items, get audio, download batch |
| Models | List models |
| Tokens | Create single-use token |

## Workspace And Admin

| Category | Representative Operations |
|----------|---------------------------|
| Usage | Usage metrics, user/subscription |
| Service accounts | Create/list/update/delete service accounts and API keys, disable keys |
| Access | Auth connections, groups, members, invites |
| Resources | Share/unshare workspace resources |
| Analytics | Workspace usage analytics, API request analytics |
| Webhooks | Webhook CRUD |

## Legacy Areas

| Category | Representative Operations |
|----------|---------------------------|
| Legacy voices | List/design/save preview |
| Legacy knowledge base | Add |
| Legacy dubbing | Transcript operations |

## Notable Library Docs

| Library/Guide | Use |
|---------------|-----|
| ElevenAgents Python, React, React Native, JavaScript, Kotlin, Swift | Agent app integration |
| ElevenAgents WebSocket docs | Custom real-time clients |
| Speech Engine JS/Python refs | Speech Engine class/method/event details |
| Scribe JS and React `useScribe` | Realtime STT in web apps |
| Vercel AI SDK STT | Speech-to-text provider integration |
| Next.js and Vite quickstarts | Web agent examples |
| Expo React Native | Cross-platform mobile agents |
| Twilio and SIP docs | Telephony integration |
| Audio Native platform guides | Website audio embeds |
