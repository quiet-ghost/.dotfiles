# ElevenCreative

ElevenCreative is the no-code/studio surface for creating production audio and video workflows.

## Product Map

| Product | Use |
|---------|-----|
| Studio | End-to-end video/audio production workflow |
| Audiobooks | Long-form narration workflow |
| Flows | Visual multi-modal AI pipelines |
| Templates | Ready-made creative workflows |
| Music | Song generation and editing |
| Image & Video | Image generation, video generation, upscaling, lip-sync |
| Avatars | Persistent talking-head identities for reusable video generation |
| Dubbing | Translate media, edit transcripts, manage speakers |
| Transcripts/Subtitles | Editors for transcript and caption work |
| Voice Library | Browse, save, and share voices |
| Voice Cloning | Instant and Professional voice clones |
| Voice Design | Prompt-generated voices |
| Audio Native | Embed generated article audio on websites |
| Voiceover Studio | Long-form voiceover production |
| Voice Isolator | Clean noisy recordings |
| AI Speech Classifier | Detect AI-generated speech |

## When To Use ElevenCreative

| Need | Surface |
|------|---------|
| Human-directed production workflow | Studio or Voiceover Studio |
| Website article narration | Audio Native |
| Batch creative pipelines | Flows and Templates |
| Precise dubbing edits | Dubbing Studio |
| Custom music creation | Music |
| Image/video generation or avatars | Image & Video / Avatars |
| Non-developer voice management | My Voices / Voice Library |

## Audio Native

Audio Native embeds ElevenLabs-generated audio onto websites. Docs include React, Ghost, Squarespace, Framer, Webflow, WordPress, and Wix integrations.

Use Audio Native when the user wants website readers to listen to articles without building a custom TTS pipeline.

## Studio API

The Studio API covers projects, chapters, snapshots, muted tracks, project audio streams, conversion, content updates, podcast creation, and pronunciation dictionaries.

Read `../api-reference/endpoints.md` for endpoint family map. Fetch current Studio API docs before coding exact schemas.

## Skill Routing

If the user asks for programmatic TTS/STT/voices, use `../eleven-api/README.md` and capability references instead. If the user asks for UI workflows, editors, or no-code publishing, stay here.
