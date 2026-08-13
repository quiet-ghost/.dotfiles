-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

hl.env("GDK_SCALE", "2")
hl.config({ xwayland = { force_zero_scaling = true } })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

local local_config = (os.getenv("HOME") or "") .. "/.config/hypr/monitors_local.lua"
local file = io.open(local_config, "r")
if file then
	file:close()
	dofile(local_config)
end

-- Gaming.
o.window({ title = "^(Slay the Spire)$" }, { fullscreen = true })
o.window({ class = "^(SlayTheSpire)$" }, { maximize = true })
o.window({ title = "^(World of Warcraft)$" }, { fullscreen = true })
o.window({ class = "^(World of Warcraft)$" }, { maximize = true })

-- Process Killer.
o.window({ class = "^(com.mitchellh.ghostty)$", title = "^(Process Killer)$" }, {
	float = true,
	size = { "100%", "100%" },
	center = true,
})

-- Yazi stays tiled and fills its available area.
o.window({ class = "^(com.mitchellh.ghostty)$", title = "^(.*yazi.*)$" }, {
	float = false,
	size = { "100%", "100%" },
	center = true,
})
