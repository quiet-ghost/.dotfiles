# Arch Linux Baseline

Start here for any Arch Linux system-management or troubleshooting task.

## Baseline Rules

- Confirm the host is really Arch before applying Arch-specific guidance.
- No partial upgrades. Do not use `pacman -Sy` by itself.
- Prefer official repositories over AUR or unofficial repos when both exist.
- Keep the exact error, command, unit name, and recent package changes intact.
- If the system is important, make sure recovery media and backups exist before large changes.

## First-Pass Triage

1. Identify the problem class.
2. Capture the current system state.
3. Route to the right reference before making changes.

| Question | Command |
|----------|---------|
| Is this Arch? | `cat /etc/os-release` |
| Is the system degraded? | `systemctl is-system-running` |
| What failed? | `systemctl --failed` |
| What is the current boot saying? | `journalctl -b -p warning..alert` |
| Any recent package changes? | `less /var/log/pacman.log` |
| Any foreign packages? | `pacman -Qm` |
| Disk layout? | `lsblk -f` |
| Space pressure? | `df -h` |

## Route By Symptom

- Routine upgrades, cleanup, pacnew review: `maintenance.md`
- Installing, removing, searching, or verifying packages: `pacman.md`
- Failed service, boot issue, regression, or runtime errors: `diagnostics.md`
- Unbootable system or live ISO repair: `recovery.md`
- Lockfiles, keyring, file conflicts, or dangerous flags: `gotchas.md`

## Command Baseline

Use these before deeper diagnosis:

```bash
systemctl --failed
journalctl -b -p err..alert
journalctl -k -b
lsblk -f
df -h
```

## ArchWiki Entry Points

- Main page: `https://wiki.archlinux.org/title/Main_page`
- General troubleshooting: `https://wiki.archlinux.org/title/General_troubleshooting`
- System maintenance: `https://wiki.archlinux.org/title/System_maintenance`
- pacman: `https://wiki.archlinux.org/title/Pacman`
- chroot: `https://wiki.archlinux.org/title/Chroot`
