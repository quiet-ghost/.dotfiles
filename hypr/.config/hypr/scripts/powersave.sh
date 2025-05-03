#!/bin/bash
powerprofilesctl set power-saver
# Optional: Set CPU governor
sudo cpupower frequency-set -g powersave
notify-send "Power Profile" "Switched to Power-Saving Mode"
