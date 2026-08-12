local terminal = "uwsm-app -- xdg-terminal-exec"

hl.unbind("SUPER + SHIFT + B")
hl.unbind("SUPER + F")
hl.unbind("SUPER + ALT + F")

o.bind("SUPER + CTRL + RETURN", "Herdr", { omarchy = "terminal-herdr" })
o.bind("SUPER + E", "File manager", terminal .. ' --title="yazi" -e yazi')
o.bind("SUPER + B", "Browser", { omarchy = "browser" })
o.bind("SUPER + SHIFT + B", "Browser (private)", { omarchy = "browser --private" })
o.bind("SUPER + N", "Editor", { omarchy = "editor" })
o.bind("SUPER + D", "Docker", { tui = "lazydocker" })
o.bind("SUPER + SHIFT + E", "File manager (cwd)", { omarchy = "nautilus-cwd" })
o.bind("SUPER + SHIFT + S", "Signal", { omarchy = "signal" })
o.bind("SUPER + SHIFT + K", "Process Killer", terminal .. ' --title="Process Killer" --confirm-close-surface=false -e $HOME/.local/bin/kill-process')

o.bind("SUPER + F", "Full width", hl.dsp.window.fullscreen({ mode = "maximized" }))
o.bind("SUPER + ALT + F", "Force full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

o.bind("ALT + SPACE", "Launch apps", "omarchy-menu toggle")
o.bind("ALT + P", "Screenshot of region", "omarchy-capture-screenshot region")
o.bind("ALT + CTRL + R", "Screen record a region", "omarchy-capture-screenrecording")
o.bind("ALT + SHIFT + R", "Screen record with audio", "omarchy-capture-screenrecording --with-desktop-audio")

o.bind("SUPER + H", "ChatGPT", { webapp = "https://chatgpt.com" })
o.bind("SUPER + SHIFT + ALT + A", "Grok", { webapp = "https://grok.com" })
o.bind("SUPER + Y", "YouTube", { webapp = "https://youtube.com/" })
o.bind("SUPER + SHIFT + X", "X", { webapp = "https://x.com/" })
o.bind("SUPER + SHIFT + T", "Monkeytype", { webapp = "https://monkeytype.com/" })

for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind("ALT + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind("ALT + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
end
