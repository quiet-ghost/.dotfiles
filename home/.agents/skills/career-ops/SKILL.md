---
name: career-ops
description: Standalone OpenCode job search command center for evaluating offers, generating CVs, scanning portals, and tracking applications
---

# Career-Ops

## Roots

- Package root: `/home/ghost/.dotfiles/home/.config/opencode/career-ops`
- Data root: `/home/ghost/.local/share/career-ops`

The package root is read-mostly runtime logic, prompts, templates, fonts, and scripts.
The data root is the user's mutable workspace.

## Mutable Files

- `/home/ghost/.local/share/career-ops/cv.md`
- `/home/ghost/.local/share/career-ops/article-digest.md`
- `/home/ghost/.local/share/career-ops/config/profile.yml`
- `/home/ghost/.local/share/career-ops/portals.yml`
- `/home/ghost/.local/share/career-ops/data/applications.md`
- `/home/ghost/.local/share/career-ops/data/pipeline.md`
- `/home/ghost/.local/share/career-ops/data/scan-history.tsv`
- `/home/ghost/.local/share/career-ops/reports/`
- `/home/ghost/.local/share/career-ops/output/`
- `/home/ghost/.local/share/career-ops/jds/`
- `/home/ghost/.local/share/career-ops/batch/`

## Package Files

- `/home/ghost/.dotfiles/home/.config/opencode/career-ops/modes/`
- `/home/ghost/.dotfiles/home/.config/opencode/career-ops/templates/`
- `/home/ghost/.dotfiles/home/.config/opencode/career-ops/batch/batch-prompt.md`
- `/home/ghost/.dotfiles/home/.config/opencode/career-ops/generate-pdf.mjs`
- `/home/ghost/.dotfiles/home/.config/opencode/career-ops/merge-tracker.mjs`
- `/home/ghost/.dotfiles/home/.config/opencode/career-ops/verify-pipeline.mjs`

## First-Run Onboarding

Before doing anything else, silently check whether these files exist in the data root:

1. `cv.md`
2. `config/profile.yml`
3. `portals.yml`

If any are missing, enter onboarding mode and do not proceed with evaluation/scan/batch work until the basics exist.

### Step 1: CV

If `cv.md` is missing, ask:

> I don't have your CV yet. You can either:
> 1. Paste your CV here and I'll convert it to markdown
> 2. Paste your LinkedIn URL and I'll extract the key info
> 3. Tell me about your experience and I'll draft a CV for you
>
> Which do you prefer?

Create `/home/ghost/.local/share/career-ops/cv.md`.

### Step 2: Profile

If `config/profile.yml` is missing, copy the package template from `/home/ghost/.dotfiles/home/.config/opencode/career-ops/config/profile.example.yml` and then ask:

> I need a few details to personalize the system:
> - Your full name and email
> - Your location and timezone
> - What roles are you targeting?
> - Your salary target range
>
> I'll set everything up for you.

Fill in `/home/ghost/.local/share/career-ops/config/profile.yml`.

### Step 3: Portals

If `portals.yml` is missing, copy the package template from `/home/ghost/.dotfiles/home/.config/opencode/career-ops/templates/portals.example.yml` and ask whether the search keywords should be customized for the target roles.

### Step 4: Tracker

If `data/applications.md` is missing, create:

```markdown
# Applications Tracker

| # | Date | Company | Role | Score | Status | PDF | Report | Notes |
|---|------|---------|------|-------|--------|-----|--------|-------|
```

If `data/pipeline.md` is missing, create:

```markdown
# Pipeline

## Pending
```

If `data/scan-history.tsv` is missing, create:

```text
url	first_seen	portal	title	company	status
```

## Routing

Determine the mode from the user request:

- empty request: discovery
- JD text or a job URL: `auto-pipeline`
- `oferta`: `oferta`
- `ofertas`: `ofertas`
- `contacto`: `contacto`
- `deep`: `deep`
- `pdf`: `pdf`
- `training`: `training`
- `project`: `project`
- `tracker`: `tracker`
- `pipeline`: `pipeline`
- `apply`: `apply`
- `scan`: `scan`
- `batch`: `batch`

If it is not a known subcommand and does not look like a JD, show the discovery menu.

## Discovery Menu

Show:

```text
career-ops -- Command Center

Available commands:
  /career-ops {JD}      -> AUTO-PIPELINE: evaluate + report + PDF + tracker
  /career-ops pipeline  -> Process pending URLs from inbox
  /career-ops oferta    -> Evaluation only A-F
  /career-ops ofertas   -> Compare and rank multiple offers
  /career-ops contacto  -> Draft LinkedIn outreach
  /career-ops deep      -> Deep company research prompt
  /career-ops pdf       -> PDF only, ATS-optimized CV
  /career-ops training  -> Evaluate course/cert
  /career-ops project   -> Evaluate portfolio project idea
  /career-ops tracker   -> Application status overview
  /career-ops apply     -> Live application assistant
  /career-ops scan      -> Scan portals and discover new offers
  /career-ops batch     -> Batch processing with parallel workers
```

## Context Loading

For these modes, read both package files before acting:

- `/home/ghost/.dotfiles/home/.config/opencode/career-ops/modes/_shared.md`
- `/home/ghost/.dotfiles/home/.config/opencode/career-ops/modes/{mode}.md`

Applies to:

- `auto-pipeline`
- `oferta`
- `ofertas`
- `pdf`
- `contacto`
- `apply`
- `pipeline`
- `scan`
- `batch`

For standalone modes, read only `modes/{mode}.md`.

## OpenCode Runtime Rules

- This package is OpenCode-only. Ignore any Claude-specific wording left in imported content and follow the OpenCode runtime model instead.
- Use the package root for prompts/templates/scripts and the data root for mutable user data.
- When a mode needs a file path from the old repo layout, translate it to the data root or package root as appropriate.
- For heavy work like large scans or pipeline batches, you may delegate using Task if it helps keep context clean.
- For batch automation, use `/home/ghost/.dotfiles/home/.config/opencode/career-ops/batch/batch-runner.sh` or `opencode run --command career-ops ...`, never `claude -p`.
- Never write new tracker rows directly into `applications.md`; write TSV additions into `/home/ghost/.local/share/career-ops/batch/tracker-additions/` and merge with the package script.
- Reports live in `/home/ghost/.local/share/career-ops/reports/` and PDFs live in `/home/ghost/.local/share/career-ops/output/`.

## Personalization

The user expects this system to be directly editable. If they ask to change archetypes, scoring, portal queries, templates, or wording, edit the package files or data files directly.
