# Gotchas

Use this file for common Arch failure modes and commands that need extra care.

## Never By Default

- `pacman -Sy` without finishing a full upgrade
- `pacman -Rdd` except true last-resort dependency surgery
- `pacman --overwrite` unless the exact conflict is understood
- Blind downgrades before checking logs, Arch News, and known regressions
- Symlinking `/var/cache/pacman/pkg`

## Common Problems

### Pacman Lock File

1. Confirm pacman is not still running.
2. Check the lock holder with `fuser /var/lib/pacman/db.lck`.
3. Remove the lock only if no pacman process is active:

```bash
rm /var/lib/pacman/db.lck
```

### Conflicting Files

1. Check whether the path belongs to a package:

```bash
pacman -Qo <path>
```

2. If it is unowned, move it aside and retry.
3. Avoid `--overwrite` unless Arch guidance or a clearly understood local state requires it.

### Corrupted Package Or Keyring State

- Remove partial downloads from `/var/cache/pacman/pkg`.
- If signatures fail on a stale system, repair the keyring using documented Arch guidance, then finish the full upgrade immediately.
- Do not stop after updating sync databases only.

### Mirror Problems

- If packages cannot be retrieved, verify the package name and enabled repositories first.
- Refresh mirrors only when mirror staleness is the real problem.
- Use `pacman -Syyu` sparingly and only when you understand why a forced database refresh is needed.

### Missing Shared Libraries

- Usually indicates a partial upgrade or packages built against old libraries.
- Complete a full upgrade with `pacman -Syu`.
- Rebuild affected AUR packages after soname bumps.
- Do not fix library issues by symlinking random `.so` files.

### Pacnew And Pacsave Drift

- Review and merge with `pacdiff` from `pacman-contrib`.
- Resolve these promptly after upgrades so old config does not silently cause later failures.

### When Downgrades Are Reasonable

- Only after logs, Arch News, and current reports point to a regression.
- Treat downgrades as temporary containment, not the default repair path.
- Keep a recovery path ready before changing core packages.

## ArchWiki

- `https://wiki.archlinux.org/title/Pacman`
- `https://wiki.archlinux.org/title/System_maintenance`
- `https://wiki.archlinux.org/title/General_troubleshooting`
