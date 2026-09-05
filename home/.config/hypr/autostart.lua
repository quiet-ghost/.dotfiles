local home = os.getenv("HOME") or ""

-- Hardware-specific display management.
o.exec_on_start(home .. "/.local/bin/hypr-display-monitor")
o.exec_on_start(home .. "/.local/bin/hypr-odyssey-240")
o.exec_on_start(home .. "/.local/bin/omarchy-idle-policy")

o.window("^(vesktop)$", { workspace = "1 silent" })
o.window("^(signal)$", { workspace = "1 silent" })
o.window("^(slack)$", { workspace = "1 silent" })
o.window("^(helium)$", { workspace = "2 silent" })
o.window("^(com.mitchellh.ghostty)$", { workspace = "3 silent" })
o.window("^(steam)$", { workspace = "4 silent" })
o.window("^(Cursor)$", { workspace = "4 silent" })
o.window("^(gimp)$", { workspace = "5 silent" })
o.window("^(com.github.th_ch.youtube_music)$", { workspace = "6 silent" })
o.window("^(com.obsproject.Studio)$", { workspace = "8 silent" })
o.window("^(teams-for-linux)$", { workspace = "10 silent" })
o.window("^(notion)$", { workspace = "10 silent" })
o.window("^(linear)$", { workspace = "10 silent" })

o.exec_on_start("uwsm-app -- xdg-terminal-exec & hyprctl dispatch workspace 3")
o.launch_on_start("helium-browser")
o.launch_on_start("vesktop")
