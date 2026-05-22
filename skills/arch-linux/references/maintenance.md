# Maintenance

Use this file for safe routine upkeep, upgrades, and post-upgrade cleanup.

## Before Upgrading

- Read Arch News if the upgrade may touch core packages or the machine matters.
- Make sure you have time to recover from breakage before running upgrades.
- Keep install media available for rescue.
- If the system uses AUR packages or out-of-tree modules, plan to rebuild them after ABI or soname changes.

## Safe Upgrade Flow

1. Optionally preview updates with `checkupdates` from `pacman-contrib`.
2. Perform a full upgrade with `pacman -Syu`.
3. Read pacman output and act on alerts immediately.
4. Review `.pacnew` and `.pacsave` files.
5. Restart services or reboot if kernel, systemd, glibc, drivers, or core libraries changed.

Helper tools used below:

- `checkupdates`, `pacdiff`, and `paccache` come from `pacman-contrib`.
- `checkservices` comes from `archlinux-contrib`.

## Useful Commands

| Task | Command |
|------|---------|
| Preview updates safely | `checkupdates` |
| Full system upgrade | `pacman -Syu` |
| Review pacnew files | `pacdiff` |
| Find outdated processes | `checkservices` |
| List orphans | `pacman -Qtd` |
| List foreign packages | `pacman -Qm` |
| Clean package cache conservatively | `paccache -r` |

## Post-Upgrade Checks

- Re-run the failing workflow if the upgrade was meant to fix a bug.
- Check for failed services with `systemctl --failed`.
- Review `journalctl -b` if boot or service behavior changed.
- Reboot after kernel upgrades instead of assuming modules stayed in sync.

## Maintenance Notes

- Keep `linux-lts` installed if you want a fallback kernel.
- Prefer `paccache` over aggressive cache deletion.
- Remove orphans only after confirming they are truly unused.
- Keep the mirrorlist healthy if package downloads are slow or stale.

## ArchWiki

- `https://wiki.archlinux.org/title/System_maintenance`
- `https://wiki.archlinux.org/title/Pacman/Pacnew_and_Pacsave`
