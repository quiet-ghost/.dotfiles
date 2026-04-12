# career-ops

## Overview

`career-ops` is a standalone OpenCode-only package for job-search workflows. It is invoked with `/career-ops` and is not a Claude Code package.

```text
Command: /career-ops
Package root: /home/ghost/.dotfiles/opencode/.config/opencode/career-ops
Data root: ~/.local/share/career-ops
```

## Layout

The package root stores prompts, templates, scripts, and command assets. The data root stores all mutable user files.

```text
/home/ghost/.dotfiles/opencode/.config/opencode/career-ops/
├── modes/
├── templates/
├── batch/
└── scripts...

~/.local/share/career-ops/
├── cv.md
├── config/profile.yml
├── portals.yml
├── data/
├── reports/
└── output/
```

## First Run

On first run, onboarding should ensure `cv.md`, `config/profile.yml`, and `portals.yml` exist in the data root. If any are missing, onboarding should prompt the user and create or fill them there.

```text
Required files:
- ~/.local/share/career-ops/cv.md
- ~/.local/share/career-ops/config/profile.yml
- ~/.local/share/career-ops/portals.yml
```

## Usage

Use `/career-ops` to open the package entrypoint and common workflows. Use subcommands for scanning, pipeline processing, PDF generation, and batch runs.

```text
/career-ops
/career-ops scan
/career-ops pipeline
/career-ops pdf
/career-ops batch
```

## Batch

Batch scripts live in the package root under the dotfiles-managed OpenCode package.

```text
/home/ghost/.dotfiles/opencode/.config/opencode/career-ops/batch/batch-runner.sh
```
