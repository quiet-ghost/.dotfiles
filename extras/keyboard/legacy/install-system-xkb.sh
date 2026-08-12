#!/bin/bash
# Install Programmer QWERTY XKB layout to system

set -e

echo "Installing Programmer QWERTY XKB layout..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script needs to install files to /usr/share/X11/xkb/symbols/"
    echo "Please run with sudo:"
    echo "  sudo $0"
    exit 1
fi

# Copy the layout to system location
cp ~/.config/xkb/symbols/programmer /usr/share/X11/xkb/symbols/programmer
chmod 644 /usr/share/X11/xkb/symbols/programmer

echo "Layout installed to /usr/share/X11/xkb/symbols/programmer"
echo ""
echo "Reloading Hyprland to apply..."
su - ghost -c "hyprctl reload" 2>/dev/null || echo "Please reload Hyprland manually: SUPER + SHIFT + R"
