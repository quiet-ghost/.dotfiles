#!/bin/bash

# Add floating window rules for Process Killer

HYPR_CONFIG="/home/ghost-desktop/.dotfiles/hypr/.config/hypr/hyprland.conf"

# Check if rules already exist
if grep -q "title:^(Process Killer)" "$HYPR_CONFIG"; then
    echo "Window rules for Process Killer already exist"
    exit 0
fi

# Find the line with AUR installer rules and add Process Killer rules after them
sed -i '/windowrulev2 = center, title:\^(AUR Package Installer)/a\
\
# Process Killer floating window rules\
 windowrulev2 = float, title:^(Process Killer)\
 windowrulev2 = size 80% 80%, title:^(Process Killer)\
 windowrulev2 = center, title:^(Process Killer)' "$HYPR_CONFIG"

echo "✓ Floating window rules added for Process Killer"
echo "Reload Hyprland with \$mainMod + Shift + R to apply changes"
