#!/bin/bash

# Setup script to make kill-process available globally via Hyprland

echo "Setting up global kill-process keybinding..."

# 1. Copy the script to bin directory
echo "Copying kill-process to bin directory..."
cp /home/ghost-desktop/.dotfiles/tmux/.config/tmux/scripts/kill-process.sh /home/ghost-desktop/.dotfiles/bin/usr/bin/kill-process
chmod +x /home/ghost-desktop/.dotfiles/bin/usr/bin/kill-process

# 2. Add keybinding to Hyprland config if not already present
HYPR_CONFIG="/home/ghost-desktop/.dotfiles/hypr/.config/hypr/hyprland.conf"

if ! grep -q "kill-process" "$HYPR_CONFIG"; then
    echo "Adding keybinding to Hyprland config..."
    
    # Find the line with aur-install and add our keybinding after it
    sed -i '/bind = $mainMod, A, exec, ghostty.*aur-install/a\bind = $mainMod, K, exec, ghostty --title="Process Killer" --confirm-close-surface=false -e /home/ghost-desktop/.dotfiles/bin/usr/bin/kill-process' "$HYPR_CONFIG"
    
    echo "✓ Keybinding added: \$mainMod + K"
else
    echo "Keybinding already exists in Hyprland config"
fi

echo ""
echo "Setup complete! You can now:"
echo "1. Reload Hyprland config with: \$mainMod + Shift + R"
echo "2. Use \$mainMod + K to launch the process killer from anywhere"
echo ""
echo "Note: You can change 'K' to any other key by editing:"
echo "  $HYPR_CONFIG"