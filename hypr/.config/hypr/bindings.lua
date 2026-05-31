-- Application bindings.

local terminal = "uwsm app -- $TERMINAL"
local browser = "omarchy-launch-browser"

o.bind("SUPER + ALT + RETURN", "Tmux", 'uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" tmux new')
o.bind("SUPER + C", nil, hl.dsp.window.close())
o.bind("SUPER + RETURN", "Terminal", terminal .. " --dir=$(omarchy-cmd-terminal-cwd)")
o.bind("SUPER + SHIFT + E", "File manager", 'uwsm app -- thunar "$(omarchy-cmd-terminal-cwd)"')
o.bind("SUPER + E", "File manager", terminal .. ' --title="yazi" -e yazi')
o.bind("SUPER + B", "Browser", browser)
o.bind("SUPER + SHIFT + B", "Browser (private)", browser .. " --private")
o.bind("SUPER + N", "Editor", "omarchy-launch-editor")
o.bind("SUPER + D", "Docker", "omarchy-launch-tui lazydocker")
o.bind("SUPER + SHIFT + S", "Signal", 'omarchy-launch-or-focus signal "uwsm app -- signal-desktop"')

hl.unbind("SUPER + O")
o.bind("SUPER + O", "Pop window out (float & pin)", "omarchy-hyprland-window-pop")
o.bind("SUPER + SLASH", "Passwords", "uwsm app -- 1password")
o.bind("ALT + SPACE", "Launch apps", 'walker -p "Start..."')
o.bind("ALT + P", "Screenshot of region", "omarchy-capture-screenshot region")
o.bind("ALT + CTRL + R", "Screen record a region", "omarchy-capture-screenrecording")
o.bind("ALT + SHIFT + R", "Screen record with audio", "omarchy-capture-screenrecording --with-desktop-audio")
o.bind("SUPER + ALT + F", "Force full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind("SUPER + F", "Full width", hl.dsp.window.fullscreen({ mode = "maximized" }))

hl.unbind("SUPER + J")
o.bind("SUPER + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + SHIFT + K", "Show key bindings", "omarchy-menu-keybindings")

hl.unbind("SUPER + SHIFT + SPACE")
o.bind("SUPER + SHIFT + SPACE", "Omarchy menu", "omarchy-menu")

hl.unbind("SUPER + K")
o.bind("SUPER + K", "Process Killer", terminal .. " --title=\"Process Killer\" --confirm-close-surface=false -e $HOME/.dotfiles/bin/usr/bin/kill-process")

hl.unbind("ALT + PRINT")

-- Web-app bindings.
o.bind("SUPER + H", "ChatGPT", { webapp = "https://chatgpt.com" })
o.bind("SUPER + G", "Grok", { webapp = "https://grok.com" })
o.bind("SUPER + Y", "YouTube", { webapp = "https://youtube.com/" })
o.bind("SUPER + X", "X", { webapp = "https://x.com/" })
o.bind("SUPER + T", "Monkeytype", { webapp = "https://monkeytype.com/" })

-- Workspace switching with keycodes.
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind("ALT + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind("ALT + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
end

hl.unbind("SUPER + W")
hl.unbind("SUPER + SPACE")
hl.unbind("SUPER + ALT + SPACE")
