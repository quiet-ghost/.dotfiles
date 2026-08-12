#!/usr/bin/env bash

if makoctl mode | grep -q 'do-not-disturb'; then
  echo '{"text": "", "tooltip": "Notifications off (Do Not Disturb)", "class": "active"}'
elif makoctl list | grep -Eq '^Notification [0-9]+:'; then
  echo '{"text": "󱅫", "tooltip": "You have notifications"}'
else
  echo '{"text": "󰂚", "tooltip": "Notifications active"}'
fi
