# REVERT INSTRUCTIONS - Custom Keyboard Layout

## Quick Revert (Immediate)

If your keyboard is not working or you want to revert right now:

```bash
# Stop keyd temporarily (reverts immediately)
sudo systemctl stop keyd

# Your keyboard is back to normal instantly
```

## Permanent Revert (Disable completely)

```bash
# Stop and disable from boot
sudo systemctl disable --now keyd

# Remove the config
sudo rm /etc/keyd/default.conf

# Optional: Remove keyd completely
sudo pacman -R keyd
```

## Emergency Revert (If keys are stuck)

```bash
# Kill keyd immediately
sudo pkill keyd

# Or force kill
sudo pkill -9 keyd
```

## Automated Revert Script

A script is provided to do all of this automatically:

```bash
# Run the revert script
sudo bash ~/.dotfiles/keyboard/revert-keyboard.sh
```

This script will:
1. Stop the keyd service
2. Disable it from starting on boot
3. Remove the configuration file
4. Kill any remaining keyd processes

## After Reverting

If keys are still not working:
1. Unplug and reconnect your keyboard
2. Or reboot: `sudo reboot`

## Re-Enable Later

If you want to use the layout again later:

```bash
# Re-link the config
sudo ln -sf ~/.dotfiles/keyboard/keyd-default.conf /etc/keyd/default.conf

# Start keyd
sudo systemctl enable --now keyd
sudo keyd reload
```

## Troubleshooting Failed Start

If keyd didn't work on first try, common issues:

1. **Config syntax error:**
   ```bash
   sudo keyd -m  # Monitor mode to test
   ```

2. **Permission issues:**
   ```bash
   sudo ls -la /etc/keyd/default.conf
   # Should show the symlink to your dotfiles
   ```

3. **Service not starting:**
   ```bash
   sudo systemctl status keyd
   sudo journalctl -u keyd
   ```

4. **Conflicts with other key remappers:**
   - Check if xmodmap, kmonad, or kanata are running
   - Stop them: `pkill xmodmap` etc.

## What keyd Does

keyd runs as a system service that intercepts keyboard input at the kernel level.
It modifies keys BEFORE they reach applications, which is why:
- It works in all apps (including Wayland)
- It requires root access
- It affects ALL keyboards connected to your system
- Stopping it immediately restores normal behavior

## Backup

Your original layout is never permanently changed. keyd just intercepts and modifies the input stream. When keyd stops, everything goes back to normal immediately.
