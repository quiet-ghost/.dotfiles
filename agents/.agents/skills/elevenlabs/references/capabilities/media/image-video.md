# Image & Video And Avatars

Image & Video creates visual content from text, reference images, videos, and audio, then supports refinement, upscaling, lip-sync, and avatar workflows.

## Availability

| Feature | Availability |
|---------|--------------|
| Image & Video | Beta |
| Free plan | Images only, limited requests per day |
| Video generation | Paid plans |
| Avatars | All paid plans |
| Avatar API | Not available at launch; planned later |

## Core Workflow

1. Explore community creations and prompts.
2. Generate image or video from text/reference assets.
3. Iterate with variations or refinement prompts.
4. Enhance with upscaling or lip-sync.
5. Export as file or send to ElevenCreative Studio.

## Capabilities

| Capability | Notes |
|------------|-------|
| Image generation | Text prompts or reference images |
| Video generation | Text-to-video, start/end frames, references, audio depending on model |
| Iterative refinement | Additional prompts and variations |
| Upscaling | Up to 4x resolution enhancement |
| Lip-sync | Still image or video driven by speech audio |
| Avatars | Persistent reusable visual identities |
| Flows | Avatar node for automated generation |

## Formats

| Type | Output |
|------|--------|
| Video | MP4, H.264/H.265, up to 4K with upscaling |
| Image | PNG high-resolution lossless |

## Avatars

Avatars combine a persistent person, character, or animal identity with any ElevenLabs voice to generate talking-head videos.

Create avatars from 3-5 reference images from different angles, or from a text prompt. Set a default voice if useful. Create styles for different angles, outfits, backgrounds, or lighting while retaining identity.

Avatar generation flow:

1. Pick avatar and style.
2. Choose voice or use default voice.
3. Enter script and generate speech.
4. Use speech to generate lip-sync video.
5. Optionally guide visuals with a prompt.

## Model Governance

Enterprise admins can control which image/video models are available to workspace members. Enterprise workspaces can have all models disabled by default until approved.

## Gotchas

| Gotcha | Fix |
|--------|-----|
| API needed for avatars | Not available at launch; verify current docs |
| Video on free plan | Requires paid plan |
| Model availability differs by region | Check workspace/model approvals |
| Need consistent avatar | Use persistent avatars and styles, not fresh prompts each time |
| Lip-sync quality poor | Use clear face/figure and clean speech audio |
| Cost estimation | Depends on model, resolution, duration, variations, settings |
