# Pacman

Use this file for normal package management and package-state inspection.

## Safe Defaults

- Prefer official repositories first.
- Use `--needed` when installing packages that may already exist.
- Reinstall a package with `pacman -S <pkg>` if files may be damaged.
- Query package ownership before deleting or overwriting files.
- If pacman itself is broken, switch to `recovery.md` or `gotchas.md`.

## Common Operations

| Task | Command |
|------|---------|
| Install package | `pacman -S --needed <pkg>` |
| Reinstall package | `pacman -S <pkg>` |
| Remove package and unused deps | `pacman -Rns <pkg>` |
| Search sync database | `pacman -Ss <term>` |
| Search installed packages | `pacman -Qs <term>` |
| Show package info | `pacman -Qi <pkg>` |
| List package files | `pacman -Ql <pkg>` |
| Show who owns a path | `pacman -Qo <path>` |
| Search remote file owner | `pacman -F <path-or-soname>` |
| Verify installed files | `pacman -Qkk <pkg>` |

## Package-State Inspection

Use these to understand what is installed and why:

```bash
pacman -Qe
pacman -Qdt
pacman -Qm
pactree <pkg>
pactree -r <pkg>
```

## When Packages Look Broken

1. Check `/var/log/pacman.log` for the last successful or failed transaction.
2. Verify files with `pacman -Qkk <pkg>`.
3. Check missing library ownership with `pacman -F <library>`.
4. Reinstall the damaged package or complete a full upgrade if the system is out of sync.

## Prefer Investigation Before Force

- Use `pacman -Qo <path>` before touching conflict files.
- Use `pacman -F <path>` before assuming a package is missing.
- Avoid `--overwrite`, `-Rdd`, or ad hoc file deletion unless the exact failure calls for it.

## ArchWiki

- `https://wiki.archlinux.org/title/Pacman`
- `https://wiki.archlinux.org/title/Pacman/Tips_and_tricks`
