# Changes to Sync to Other Devices

## Files Modified/Added:

### 1. TMux Config Directory (`~/.dotfiles/tmux/.config/tmux/`)
- **scripts/kill-process.sh** - The main process killer script
- **scripts/setup-kill-process-global.sh** - Setup script (can be deleted after sync)
- **scripts/add-floating-rules.sh** - Floating rules script (can be deleted after sync)

### 2. Bin Directory (`~/.dotfiles/bin/usr/bin/`)
- **kill-process** - Copy of kill-process.sh for global access

### 3. Hyprland Config (`~/.dotfiles/hypr/.config/hypr/hyprland.conf`)
- Added keybinding: `bind = $mainMod, K, exec, ghostty --title="Process Killer" ...`
- Added window rules for floating behavior (lines 64-67):
  - `windowrulev2 = float, title:^(Process Killer)`
  - `windowrulev2 = size 80% 80%, title:^(Process Killer)`
  - `windowrulev2 = center, title:^(Process Killer)`

## Symlinks to Verify on Other Device:
- `~/.config/tmux` -> `~/.dotfiles/tmux/.config/tmux` (should already exist)

## After Syncing to Laptop:
1. Pull the changes from your dotfiles repo
2. Reload Hyprland config with `$mainMod + Shift + R`
3. Test with `$mainMod + K` to launch the floating Process Killer

## Commands to commit these changes:
```bash
cd ~/.dotfiles
git add tmux/.config/tmux/scripts/kill-process.sh
git add tmux/.config/tmux/scripts/setup-kill-process-global.sh
git add tmux/.config/tmux/scripts/add-floating-rules.sh
git add bin/usr/bin/kill-process
git add hypr/.config/hypr/hyprland.conf
git commit -m "Add global Process Killer with Hyprland floating window support"
git push
```

## On your laptop after pulling:
The symlinks should already be in place, so just:
1. `git pull`
2. Reload Hyprland
3. Ready to use!