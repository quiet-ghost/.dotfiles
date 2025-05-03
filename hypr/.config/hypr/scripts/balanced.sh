#!/bin/bash
powerprofilesctl set balanced
# Optional: Set CPU governor
sudo cpupower frequency-set -g schedutil
notify-send "Power Profile" "Switched to Balanced Mode"
