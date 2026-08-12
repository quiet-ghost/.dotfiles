local terminal = "uwsm-app -- xdg-terminal-exec"

for _, keys in ipairs({
  "SUPER + RETURN",
  "SUPER + SHIFT + B",
  "SUPER + O",
  "SUPER + SLASH",
  "SUPER + C",
  "SUPER + F",
  "SUPER + ALT + F",
  "SUPER + J",
  "SUPER + SHIFT + SPACE",
  "SUPER + K",
  "SUPER + G",
  "SUPER + T",
  "SUPER + X",
}) do
  hl.unbind(keys)
end

o.bind("SUPER + ALT + RETURN", "Herdr", 'uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" herdr')
o.bind("SUPER + C", "Close window", hl.dsp.window.close())
o.bind("SUPER + RETURN", "Terminal", terminal .. " --dir=$(omarchy-cmd-terminal-cwd)")
o.bind("SUPER + SHIFT + E", "File manager", "omarchy-launch-nautilus-cwd")
o.bind("SUPER + E", "File manager", terminal .. ' --title="yazi" -e yazi')
o.bind("SUPER + B", "Browser", "omarchy-launch-browser")
o.bind("SUPER + SHIFT + B", "Browser (private)", "omarchy-launch-browser --private")
o.bind("SUPER + N", "Editor", "omarchy-launch-editor")
o.bind("SUPER + D", "Docker", "omarchy-launch-tui lazydocker")
o.bind("SUPER + SHIFT + S", "Signal", 'omarchy-launch-or-focus signal "uwsm-app -- signal-desktop"')
o.bind("SUPER + O", "Pop window out (float & pin)", "omarchy-hyprland-window-pop")
o.bind("SUPER + SLASH", "Passwords", "uwsm-app -- 1password")
o.bind("ALT + SPACE", "Launch apps", "omarchy-menu toggle")
o.bind("ALT + P", "Screenshot of region", "omarchy-capture-screenshot region")
o.bind("ALT + CTRL + R", "Screen record a region", "omarchy-capture-screenrecording")
o.bind("ALT + SHIFT + R", "Screen record with audio", "omarchy-capture-screenrecording --with-desktop-audio")
o.bind("SUPER + ALT + F", "Force full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind("SUPER + F", "Full width", hl.dsp.window.fullscreen({ mode = "maximized" }))
o.bind("SUPER + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + SHIFT + K", "Show key bindings", "omarchy-menu-keybindings")
o.bind("SUPER + SHIFT + SPACE", "Omarchy menu", "omarchy-menu toggle root")
o.bind("SUPER + K", "Process Killer", terminal .. ' --title="Process Killer" --confirm-close-surface=false -e $HOME/.local/bin/kill-process')

o.bind("SUPER + H", "ChatGPT", { webapp = "https://chatgpt.com" })
o.bind("SUPER + G", "Grok", { webapp = "https://grok.com" })
o.bind("SUPER + Y", "YouTube", { webapp = "https://youtube.com/" })
o.bind("SUPER + X", "X", { webapp = "https://x.com/" })
o.bind("SUPER + T", "Monkeytype", { webapp = "https://monkeytype.com/" })

for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind("ALT + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind("ALT + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
end

hl.unbind("ALT + PRINT")
hl.unbind("SUPER + W")
hl.unbind("SUPER + SPACE")
hl.unbind("SUPER + ALT + SPACE")
