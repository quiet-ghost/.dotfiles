#!/bin/bash
# Revert Keyboard Layout Script
# This script completely removes the custom keyboard layout and restores defaults

set -e

echo "=========================================="
echo "Keyboard Layout Revert Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script needs to run with sudo"
    echo "Usage: sudo bash revert-keyboard.sh"
    exit 1
fi

echo "Step 1: Stopping keyd service..."
if systemctl is-active --quiet keyd; then
    systemctl stop keyd
    echo "✓ keyd service stopped"
else
    echo "✓ keyd was not running"
fi

echo ""
echo "Step 2: Disabling keyd from starting on boot..."
if systemctl is-enabled --quiet keyd 2>/dev/null; then
    systemctl disable keyd
    echo "✓ keyd disabled from boot"
else
    echo "✓ keyd was not enabled"
fi

echo ""
echo "Step 3: Removing keyd configuration..."
if [ -f /etc/keyd/default.conf ]; then
    rm /etc/keyd/default.conf
    echo "✓ Removed /etc/keyd/default.conf"
else
    echo "✓ No config file found"
fi

# Optional: Remove the entire keyd directory if empty
if [ -d /etc/keyd ] && [ -z "$(ls -A /etc/keyd)" ]; then
    rmdir /etc/keyd
    echo "✓ Removed empty /etc/keyd directory"
fi

echo ""
echo "Step 4: Checking for leftover keyd processes..."
if pgrep -x "keyd" > /dev/null; then
    pkill -9 keyd
    echo "✓ Killed remaining keyd processes"
else
    echo "✓ No keyd processes running"
fi

echo ""
echo "=========================================="
echo "Revert Complete!"
echo "=========================================="
echo ""
echo "Your keyboard should now be back to normal."
echo ""
echo "If keys are still not working correctly:"
echo "1. Try unplugging and reconnecting your keyboard"
echo "2. Or reboot your system: sudo reboot"
echo ""
echo "To completely remove keyd from your system:"
echo "  sudo pacman -R keyd"
echo ""
