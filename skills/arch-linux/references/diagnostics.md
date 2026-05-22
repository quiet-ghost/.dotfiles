# Diagnostics

Use this file for first-pass troubleshooting of services, boots, regressions, and runtime failures.

## General Flow

1. Reproduce the issue and keep the exact error.
2. Check the relevant unit, journal, or application output.
3. Decide whether the problem is package state, configuration, hardware, or a recent upgrade.
4. Escalate to recovery only if the system cannot boot or pacman cannot repair in place.

## Service And App Failures

| Task | Command |
|------|---------|
| Unit status | `systemctl status <unit>` |
| Unit logs from current boot | `journalctl -u <unit> -b` |
| All failed units | `systemctl --failed` |
| Run app with terminal output | `<app> --verbose` or `<app> --debug` when supported |

## System-Wide And Boot Failures

| Task | Command |
|------|---------|
| Current boot journal | `journalctl -b` |
| Previous boot journal | `journalctl -b -1` |
| Current boot errors only | `journalctl -p err -b` |
| Kernel messages | `journalctl -k -b` |
| Fallback kernel buffer view | `dmesg --level=err,warn` |

## Disk, Filesystem, And Space Checks

| Task | Command |
|------|---------|
| Filesystems and UUIDs | `lsblk -f` |
| Mounted filesystems | `findmnt` |
| Free space | `df -h` |
| Recent package activity | `less /var/log/pacman.log` |

## Regression Clues

- If the issue started right after updates, inspect `/var/log/pacman.log` first.
- Check Arch News and current forum reports before improvising.
- If AUR packages link against old libraries, rebuild them after soname bumps.
- For freezes or panics, consider firmware, graphics drivers, and kernel regressions, not just user-space changes.

## Data To Preserve When Asking For Help

- Full failing command output
- `systemctl status <unit>` for affected units
- Relevant `journalctl` output from the current or previous boot
- Exact package versions involved
- Relevant config files

## ArchWiki

- `https://wiki.archlinux.org/title/General_troubleshooting`
- `https://wiki.archlinux.org/title/Step-by-step_debugging_guide`
