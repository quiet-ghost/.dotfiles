#!/bin/bash

# Exit on any error
set -e

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

echo "Starting Arch Linux maintenance..."

# Step 1: Create a Timeshift snapshot
echo "Creating Timeshift snapshot..."
timeshift --create --comments "Pre-maintenance snapshot $(date +%Y-%m-%d_%H-%M-%S)"

# Step 2: Update package database and upgrade packages
echo "Updating package database and upgrading packages..."
pacman -Syu --noconfirm

# Step 3: Remove orphaned packages
echo "Removing orphaned packages..."
pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || true

# Step 4: Clean package cache (keep last 2 versions of packages)
echo "Cleaning package cache..."
paccache -r -k 2

# Step 5: Check for broken dependencies
echo "Checking for broken dependencies..."
pacman -Dk || echo "Run 'pacman -S <missing-package>' to fix broken dependencies."

# Step 6: Check for filesystem issues (optional, read-only check)
echo "Checking filesystem (read-only)..."
fsck -n / || echo "Filesystem issues detected. Run 'fsck' manually to repair."

echo "Maintenance complete!"

# Optional: Create a post-maintenance snapshot
echo "Creating post-maintenance Timeshift snapshot..."
timeshift --create --comments "Post-maintenance snapshot $(date +%Y-%m-%d_%H-%M-%S)"
