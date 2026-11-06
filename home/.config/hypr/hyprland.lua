-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Keep core window-manager bindings. Personal app/web binds live in bindings.lua.
omarchy_preinstalled_bindings = false

require("default.hypr.omarchy")

require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Strata opens floating and centered.
o.window({ class = "^io[.]github[.]lgse[.]Strata$" }, {
	float = true,
	center = true,
})

require("default.hypr.toggles")

-- Added by hyprmoncfg: its generated monitor rules load last, so nothing before this can override the applied layout.
do
	local path = (os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/hypr/hyprmoncfg-monitors.lua"
	local file = io.open(path, "r")
	if file then
		file:close()
		dofile(path)
	end
end
