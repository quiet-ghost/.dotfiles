-- Extra autostart processes.

local home = os.getenv("HOME") or ""
local terminal = "uwsm app -- $TERMINAL"

-- Automatic TV/laptop display switching.
o.exec_on_start(home .. "/.local/bin/hypr-display-monitor")

o.window("^(legcord)$", { workspace = "1 silent" })
o.window("^(signal)$", { workspace = "1 silent" })
o.window("^(helium)$", { workspace = "2 silent" })
o.window("^(zen)$", { workspace = "2 silent" })
o.window("^(jetbrains-idea)$", { workspace = "4 silent" })
o.window("^(steam)$", { workspace = "4 silent" })
o.window("^(Cursor)$", { workspace = "4 silent" })
o.window("^(Code)$", { workspace = "4 silent" })
o.window("^(gimp)$", { workspace = "5 silent" })
o.window("^(com.github.th_ch.youtube_music)$", { workspace = "6 silent" })
o.window("^(Proton Mail)$", { workspace = "7 silent" })
o.window("^(com.obsproject.Studio)$", { workspace = "8 silent" })
o.window("^(de.feschber.LanMouse)$", { workspace = "8 silent" })
o.window("^(Slack)$", { workspace = "9 silent" })
o.window("^(teams-for-linux)$", { workspace = "10 silent" })
o.window("^(Chromium)$", { tile = true })

o.exec_on_start(terminal .. " & hyprctl dispatch workspace 3")
o.exec_on_start("helium")
o.exec_on_start("legcord")
o.exec_on_start("signal")
o.exec_on_start("Slack")
