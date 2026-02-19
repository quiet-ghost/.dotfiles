# XKB Programmer Layout Setup

This directory contains a custom XKB keyboard layout for Programmer QWERTY that works properly with Hyprland.

## Why XKB?

We switched from **keyd** to **XKB** because:
- keyd remaps at the kernel level, which conflicts with Hyprland's key binding detection
- XKB works at the display server level, compatible with Wayland/Hyprland
- ThePrimeagen uses XKB with Hyprland successfully

## Installation

### 1. Copy the layout to system location

```bash
sudo cp ~/.dotfiles/keyboard/xkb/programmer /usr/share/X11/xkb/symbols/
sudo chmod 644 /usr/share/X11/xkb/symbols/programmer
```

### 2. Verify Hyprland configuration

Your `~/.dotfiles/hypr/.config/hypr/input.conf` should have:

```conf
input {
  kb_layout = programmer,us
  kb_options = ctrl:nocaps
  ...
}
```

### 3. Reload Hyprland

```bash
hyprctl reload
# Or: SUPER + SHIFT + R
```

### 4. Test the layout

Open a text editor and press:
- `1` → should type `+`
- `Shift+1` → should type `1`
- `ALT+1` → should switch to workspace 1
- `ALT+Shift+1` → should move window to workspace 1

## Uninstall / Revert to Standard Layout

### Quick Revert (Temporary)

Switch to standard US layout without removing files:

```bash
# Edit Hyprland input.conf
sed -i 's/kb_layout = programmer,us/kb_layout = us/' ~/.dotfiles/hypr/.config/hypr/input.conf

# Reload Hyprland
hyprctl reload
```

Your keyboard is back to normal immediately.

### Complete Uninstall (Permanent)

Remove the custom layout entirely:

```bash
# 1. Stop using the layout in Hyprland
sed -i 's/kb_layout = programmer,us/kb_layout = us/' ~/.dotfiles/hypr/.config/hypr/input.conf

# 2. Remove from system
sudo rm /usr/share/X11/xkb/symbols/programmer

# 3. Reload Hyprland
hyprctl reload

# 4. (Optional) Remove from dotfiles
rm -rf ~/.dotfiles/keyboard/xkb/
```

### Emergency Reset

If your keyboard stops working:

```bash
# Reset to standard layout immediately
hyprctl keyword input:kb_layout us
```

Or use a different TTY (Ctrl+Alt+F3), login, and:
```bash
sudo rm /usr/share/X11/xkb/symbols/programmer
reboot
```

## Troubleshooting

### Layout not applying

Check if the file is in the right place:
```bash
ls -la /usr/share/X11/xkb/symbols/programmer
```

### Hyprland shows "Invalid keyboard layout"

The layout file might have syntax errors. Check:
```bash
# Test the layout
setxkbmap -layout programmer -variant basic
```

### Workspace switching doesn't work

Make sure you're using keycodes in `bindings.conf`:
```conf
# Correct - uses keycodes
bind = ALT, code:10, workspace, 1

# Incorrect - uses keysyms (conflicts with XKB remapping)
bind = ALT, 1, workspace, 1
```

### Keys show wrong symbols

Verify the layout is loaded:
```bash
hyprctl getoption input:kb_layout
# Should show: programmer,us
```

## Layout Definition

The layout file (`xkb/programmer`) defines:

```
key <AE01> { [ plus, 1 ] };          # 1 key: + on base, 1 on shift
key <AE02> { [ bracketleft, 2 ] };   # 2 key: [ on base, 2 on shift
key <AE03> { [ braceleft, 3 ] };     # 3 key: { on base, 3 on shift
...
```

See the full file at `~/.dotfiles/keyboard/xkb/programmer`

## References

- ThePrimeagen's setup: https://github.com/ThePrimeagen/dev/tree/master/env/.config/xkb
- Arch Wiki - XKB: https://wiki.archlinux.org/title/X_keyboard_extension
- Hyprland Keyboard: https://wiki.hyprland.org/Configuring/Variables/#input
