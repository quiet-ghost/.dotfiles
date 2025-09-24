#!/bin/bash
powerprofilesctl set performance
# Optional: Set CPU governor
sudo cpupower frequency-set -g performance
notify-send "Power Profile" "Switched to Performance Mode"
