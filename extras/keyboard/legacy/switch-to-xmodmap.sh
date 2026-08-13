#!/bin/bash
# Switch from keyd to xmodmap for keyboard remapping

echo "Switching from keyd to xmodmap..."

# Stop and disable keyd
echo "Stopping keyd service..."
sudo systemctl stop keyd
sudo systemctl disable keyd

# Load xmodmap configuration
echo "Loading xmodmap configuration..."
xmodmap ~/.dotfiles/extras/keyboard/legacy/.Xmodmap

echo "Done! Keyboard remapping is now handled by xmodmap."
echo ""
echo "To make this permanent, add this to your Hyprland autostart.conf:"
echo "  exec-once = xmodmap ~/.dotfiles/extras/keyboard/legacy/.Xmodmap"
echo ""
echo "Or add to your ~/.bashrc or ~/.zshrc:"
echo "  xmodmap ~/.dotfiles/extras/keyboard/legacy/.Xmodmap 2>/dev/null || true"
