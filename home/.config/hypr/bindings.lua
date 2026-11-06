local terminal = "uwsm-app -- xdg-terminal-exec"

hl.unbind("SUPER + SHIFT + B")
hl.unbind("SUPER + F")
hl.unbind("SUPER + ALT + F")
hl.unbind("SUPER + C")
hl.unbind("SUPER + G")
hl.unbind("SUPER + L")
hl.unbind("SUPER + X")
hl.unbind("SUPER + T")
hl.unbind("SUPER + SHIFT + SPACE")
hl.unbind("SUPER + SPACE")
hl.unbind("SUPER + ALT + SPACE")
hl.unbind("ALT + SPACE")

o.bind("SUPER + CTRL + RETURN", "Herdr", { omarchy = "terminal-herdr" })
o.bind("SUPER + SHIFT + E", "File manager", terminal .. ' --title="yazi" -e yazi')
hl.unbind("SUPER + SHIFT + F")
hl.unbind("SUPER + E")
hl.unbind("SUPER + CTRL + SHIFT + E")
o.bind("SUPER + E", "File manager", { launch = "strata" })
o.bind("SUPER + CTRL + SHIFT + E", "File manager (cwd)", { launch = 'strata "$(omarchy-cmd-terminal-cwd)"' })
o.bind("SUPER + B", "Browser", { omarchy = "browser" })
o.bind("SUPER + SHIFT + B", "Browser (private)", { omarchy = "browser --private" })
o.bind("SUPER + N", "Editor", { omarchy = "editor" })
o.bind("SUPER + D", "Docker", { tui = "lazydocker" })
-- o.bind(
-- 	"SUPER + SHIFT + E",
-- 	"File manager (cwd)",
-- 	{ launch = "env GTK_THEME=rose-pine-gtk:light /usr/bin/thunar $(omarchy-cmd-terminal-cwd)" }
-- )
o.bind("SUPER + SHIFT + S", "Signal", { omarchy = "signal" })
o.bind(
	"SUPER + SHIFT + K",
	"Process Killer",
	terminal .. ' --title="Process Killer" --confirm-close-surface=false -e $HOME/.local/bin/kill-process'
)
o.bind("SUPER + SHIFT + O", "Omawrite", { launch = "omawrite" })

o.bind("SUPER + C", "Close window", hl.dsp.window.close())
o.bind("SUPER + F", "Full width", hl.dsp.window.fullscreen({ mode = "maximized" }))
o.bind("SUPER + ALT + F", "Force full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind("SUPER + SHIFT + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + L", "Lock system", "omarchy-system-lock")

o.bind("ALT + SPACE", "omacast launcher", hl.dsp.global("omacast:toggle"))
o.bind("F10", "Hex dictation (hold)", "hex dictation start")
o.bind("F10", "Hex dictation (release)", "hex dictation stop", { release = true })
o.bind("SUPER + SPACE", "Omarchy menu (fallback)", "omarchy-menu toggle root")
o.bind("ALT + P", "Screenshot of region", "omarchy-capture-screenshot region")
o.bind("ALT + CTRL + R", "Screen record a region", "omarchy-capture-screenrecording")
o.bind("ALT + SHIFT + R", "Screen record with audio", "omarchy-capture-screenrecording --with-desktop-audio")

o.bind("SUPER + H", "ChatGPT", { webapp = "https://chatgpt.com" })
o.bind("SUPER + G", "Grok", { webapp = "https://grok.com" })
o.bind("SUPER + Y", "YouTube", { webapp = "https://youtube.com/" })
o.bind("SUPER + SHIFT + Y", "YouTube Music", "omarchy-shell shell summon local.youtube-music")
o.bind("SUPER + X", "X", { webapp = "https://x.com/" })
o.bind("SUPER + T", "Monkeytype", { webapp = "https://monkeytype.com/" })

for workspace = 1, 10 do
	local key = "code:" .. tostring(workspace + 9)
	o.bind("ALT + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
	o.bind(
		"ALT + SHIFT + " .. key,
		"Move window to workspace " .. workspace,
		hl.dsp.window.move({ workspace = tostring(workspace) })
	)
end

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end
