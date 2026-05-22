# Recovery

Use this file when the system no longer boots normally, pacman cannot repair in place, or a live ISO is required.

## Recovery Principles

- Use a recent Arch install ISO when possible.
- Identify the real root, boot, and ESP mounts before changing anything.
- Mount all required partitions and Btrfs subvolumes before `arch-chroot`.
- Prefer repairing the existing install over reinstalling blindly.

## Basic Live ISO Flow

1. Inspect the disk layout with `lsblk -f`.
2. Mount root to `/mnt`.
3. Mount boot, ESP, and any required subvolumes under `/mnt`.
4. Enter the system with `arch-chroot /mnt`.
5. Inspect `pacman.log`, `fstab`, and the journal.
6. Finish the interrupted or pending upgrade.
7. Rebuild initramfs or reinstall the bootloader if the symptom points there.

## Common Commands

```bash
lsblk -f
mount /dev/<root> /mnt
mount /dev/<boot-or-esp> /mnt/boot
arch-chroot /mnt
pacman -Syu
mkinitcpio -P
```

Choose the bootloader repair that matches the installed system:

- systemd-boot: `bootctl install`
- GRUB: `grub-install <target>` then `grub-mkconfig -o /boot/grub/grub.cfg`

## If Pacman Cannot Run In The Installed System

Use the live environment to operate on the mounted system:

```bash
pacman --sysroot /mnt -Syu
```

If the failure was an interrupted upgrade, inspect `/mnt/var/log/pacman.log` and complete the intended transaction instead of doing random package surgery.

## Btrfs And Special Layouts

- Mount all subvolumes listed in the installed system's `fstab` before `arch-chroot`.
- Mount the ESP if bootloader or kernel artifacts may need repair.
- If encryption or RAID is involved, assemble or unlock those layers first.

## Recovery Targets

- Interrupted upgrade: finish the upgrade, then verify damaged packages.
- Initramfs issue: repair hooks or kernel packages, then run `mkinitcpio -P`.
- Bootloader issue: reinstall or regenerate bootloader config.
- Wrong `fstab` or missing mount: correct the config before reboot.

## ArchWiki

- `https://wiki.archlinux.org/title/Chroot`
- `https://wiki.archlinux.org/title/General_troubleshooting`
- `https://wiki.archlinux.org/title/Pacman`
