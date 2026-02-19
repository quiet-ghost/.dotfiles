#!/bin/bash
# Install custom XKB layout for Programmer QWERTY
# This creates a custom layout that works natively with Wayland/Hyprland

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if running as root (needed for system install)
if [ "$EUID" -ne 0 ]; then 
    echo "This script needs to install files to /usr/share/X11/xkb/"
    echo "Please run with sudo:"
    echo "  sudo $0"
    exit 1
fi

echo "Installing Programmer QWERTY XKB layout..."

# Create custom symbols file
if [ -f /usr/share/X11/xkb/symbols/custom ]; then
    echo "Backing up existing custom layout..."
    cp /usr/share/X11/xkb/symbols/custom /usr/share/X11/xkb/symbols/custom.bak.$(date +%Y%m%d%H%M%S)
fi

cp "$SCRIPT_DIR/programmer.xkb" /usr/share/X11/xkb/symbols/custom

echo "Custom layout installed to /usr/share/X11/xkb/symbols/custom"
echo ""
echo "To use this layout, add to your Hyprland input.conf:"
echo "  kb_layout = custom"
echo "  kb_variant = programmer"
echo ""
echo "Then reload Hyprland with: SUPER + SHIFT + R"
