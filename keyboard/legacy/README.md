# Legacy Keyboard Configurations

This directory contains older keyboard remapping configurations that were used before settling on the XKB solution.

## Contents

- `keyd-default.conf` - Original keyd configuration (kernel-level remapping)
- `REVERT.md` - Instructions for reverting keyd setup
- `revert-keyboard.sh` - Script to revert keyd
- `.Xmodmap` - Xmodmap configuration (X11-level remapping, doesn't work well with Wayland/Hyprland)
- `switch-to-xmodmap.sh` - Script to switch from keyd to xmodmap
- `install-xkb-layout.sh` - Old installer script
- `install-system-xkb.sh` - Old system installer script
- `programmer.xkb` - Draft XKB layout file

## Why These Were Abandoned

### keyd
- Works at kernel level
- Conflicts with Hyprland's key binding detection
- ALT+workspace switching doesn't work properly

### xmodmap
- X11 tool, doesn't work well with Wayland
- Layout applies but applications don't receive remapped keysyms correctly

### XKB (Current Solution)
- Works at display server level
- Compatible with Wayland/Hyprland
- ThePrimeagen uses this successfully
- Workspace switching with ALT works correctly

## Current Setup

See `../XKB.md` for the current working setup using XKB.
