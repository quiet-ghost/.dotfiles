---
name: arch-linux
description: "Manage Arch Linux systems safely: full-system pacman upgrades, routine maintenance, systemd/journal diagnostics, and live-ISO recovery with arch-chroot. Use for package management, failed services, boot issues, mirror/keyring problems, and post-upgrade breakage on Arch hosts."
references:
  - references/README.md
  - references/maintenance.md
  - references/pacman.md
  - references/diagnostics.md
  - references/recovery.md
  - references/gotchas.md
---

# Arch Linux Skill

Use this skill for Arch host maintenance, package operations, troubleshooting, and rescue work.

## Core Principles

- Treat Arch as a rolling release: no partial upgrades; prefer `pacman -Syu`.
- Read exact errors first. Prefer `journalctl` and `systemctl` over guessing.
- Prefer official repositories; treat AUR and unofficial repos as extra-risk inputs.
- Keep fixes minimal and reversible. Preserve logs and exact failing commands.
- For unbootable systems, use current install media plus `arch-chroot`.
- Avoid risky pacman flags unless exact Arch guidance calls for them.

## Quick Router

What do you need?

```text
Routine upkeep or upgrade hygiene?
├─ Read Arch News, upgrade, reboot checks, cache cleanup -> references/maintenance.md
└─ Orphans, foreign packages, pacnew review -> references/maintenance.md

Package install/remove/query issue?
├─ Normal pacman operations -> references/pacman.md
└─ Conflicts, lockfiles, keyring, mirror failures -> references/gotchas.md

Service, boot, kernel, or runtime failure?
├─ systemd unit or app failure -> references/diagnostics.md
├─ previous boot or crash evidence -> references/diagnostics.md
└─ system no longer boots -> references/recovery.md

Broken upgrade or live ISO rescue?
└─ Mount, chroot, finish upgrade, rebuild boot assets -> references/recovery.md
```

## Working Style

1. Confirm it is really Arch and capture current symptoms.
2. Collect state before changing anything: package logs, journal, failed units, disk layout.
3. Prefer the smallest safe fix that matches the observed error.
4. Warn before risky actions like package downgrades, bootloader changes, or live recovery.
5. After repairs, re-check the specific failure and whether a reboot is still required.

## Reading Order

| Task | Files to Read |
|------|---------------|
| New Arch task | `references/README.md` |
| Routine maintenance | `references/maintenance.md` |
| Package management | `references/pacman.md` |
| Diagnose failures | `references/diagnostics.md` |
| Unbootable system | `references/recovery.md` |
| Edge cases and unsafe commands | `references/gotchas.md` |

## In This Reference

| File | Purpose |
|------|---------|
| [README.md](./references/README.md) | Baseline triage flow and Arch safety rules |
| [maintenance.md](./references/maintenance.md) | Safe upgrade and upkeep workflow |
| [pacman.md](./references/pacman.md) | Install, remove, query, verify, and inspect packages |
| [diagnostics.md](./references/diagnostics.md) | Systemd, journal, kernel, storage, and regression triage |
| [recovery.md](./references/recovery.md) | Live ISO rescue, mounting, chroot, and boot repair |
| [gotchas.md](./references/gotchas.md) | High-risk commands, narrow exceptions, and common failure modes |

## Scope Notes

- This skill is Arch-focused and assumes official Arch guidance, not generic distro advice.
- When a fix is high risk or the symptoms are unusual, open the exact ArchWiki page linked from the relevant reference.
- For Arch-based but non-Arch distributions, use extra caution; support expectations and packaging state may differ.
