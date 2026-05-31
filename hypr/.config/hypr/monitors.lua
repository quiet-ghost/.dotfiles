-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and resolutions possible: hyprctl monitors all

hl.env("GDK_SCALE", "2")

hl.config({
  xwayland = {
    force_zero_scaling = true,
  },
})

-- Desktop-Main.
hl.monitor({ output = "desc:Acer Technologies XV272U W2 B5400FDEC4223", mode = "2560x1440@240", position = "-2560x0", scale = 1 })
hl.monitor({ output = "desc:Samsung Electric Company Odyssey G81SF HNAY402474", mode = "3840x2160@240", position = "0x0", scale = 1.5 })

-- Desktop-streaming.
hl.monitor({ output = "desc:Samsung Electric Company LS28AG700N HCJT903129", mode = "3840x2160@144", position = "2393x0", scale = 1.5, transform = 2 })
hl.monitor({ output = "desc:Samsung Electric Company LS27FG53x H9DY803455", mode = "2560x1440@200", position = "4953x0", scale = 1, transform = 3 })

-- Elgato capture card.
hl.monitor({
  output = "desc:Elgato Systems LLC Elgato 4K X 0x00000001",
  mode = "3840x2160@60",
  position = "0x0",
  scale = 1,
  mirror = "desc:Samsung Electric Company Odyssey G81SF HNAY402474",
})

-- Laptop - X1 Carbon.
hl.monitor({ output = "eDP-1", mode = "2880x1800@120", position = "0x0", scale = 1.8 })
hl.monitor({ output = "desc:Samsung Electric Company SAMSUNG 0x01000E00", mode = "3840x2160@60", position = "auto", scale = 1.8 })

-- Workspaces.
hl.workspace_rule({ workspace = "1", monitor = "desc:Acer Technologies XV272U W2 B5400FDEC4223", default = true })
hl.workspace_rule({ workspace = "6", monitor = "desc:Acer Technologies XV272U W2 B5400FDEC4223" })
hl.workspace_rule({ workspace = "7", monitor = "desc:Acer Technologies XV272U W2 B5400FDEC4223" })
hl.workspace_rule({ workspace = "8", monitor = "desc:Acer Technologies XV272U W2 B5400FDEC4223" })
hl.workspace_rule({ workspace = "9", monitor = "desc:Acer Technologies XV272U W2 B5400FDEC4223" })
hl.workspace_rule({ workspace = "0", monitor = "desc:Acer Technologies XV272U W2 B5400FDEC4223" })

hl.workspace_rule({ workspace = "2", monitor = "desc:Samsung Electric Company Odyssey G81SF HNAY402474", default = true })
hl.workspace_rule({ workspace = "3", monitor = "desc:Samsung Electric Company Odyssey G81SF HNAY402474" })
hl.workspace_rule({ workspace = "4", monitor = "desc:Samsung Electric Company Odyssey G81SF HNAY402474" })
hl.workspace_rule({ workspace = "5", monitor = "desc:Samsung Electric Company Odyssey G81SF HNAY402474" })

-- Gaming.
o.window({ title = "^(Slay the Spire)$" }, { fullscreen = true })
o.window({ class = "^(SlayTheSpire)$" }, { maximize = true })
o.window({ title = "^(World of Warcraft)$" }, { fullscreen = true })
o.window({ class = "^(World of Warcraft)$" }, { maximize = true })

-- Process Killer floating window rules.
o.window({ class = "^(com.mitchellh.ghostty)$", title = "^(Process Killer)$" }, { float = true })
o.window({ class = "^(com.mitchellh.ghostty)$", title = "^(Process Killer)$" }, { size = { "monitor_w", "monitor_h" } })
o.window({ class = "^(com.mitchellh.ghostty)$", title = "^(Process Killer)$" }, { center = true })

-- Yazi terminal rules.
o.window({ class = "^(com.mitchellh.ghostty)$", title = "^(.*yazi.*)$" }, { tile = true })
o.window({ class = "^(com.mitchellh.ghostty)$", title = "^(.*yazi.*)$" }, { size = { "monitor_w", "monitor_h" } })
o.window({ class = "^(com.mitchellh.ghostty)$", title = "^(.*yazi.*)$" }, { center = true })
