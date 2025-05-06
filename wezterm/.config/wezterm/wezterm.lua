local wezterm = require("wezterm")
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- Load the custom color scheme from colors.lua
local custom_colors = require("colors")
for name, scheme in pairs(custom_colors.color_schemes) do
	config.color_schemes = config.color_schemes or {}
	config.color_schemes[name] = scheme
end
config.color_scheme = "MaterialOcean"

-- Font configuration from Ghostty config
config.font = wezterm.font("FiraCode Nerd Font Mono SemBd")
config.font_size = 14
config.default_cursor_style = "SteadyBlock"
config.use_fancy_tab_bar = false
config.show_tabs_in_tab_bar = true
config.show_new_tab_button_in_tab_bar = false

-- Window appearance
config.color_scheme = "sRGB"
config.bold_brightens_ansi_colors = true

-- Shell integration
config.set_environment_variables = {
	TERM = "xterm-256color",
}

-- Theme switching based on system appearance
function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "MaterialOcean"
	else
		return "MaterialOcean"
	end
end
wezterm.on("window-config-reloaded", function(window, pane)
	local overrides = window:get_config_overrides() or {}
	local appearance = window:get_appearance()
	local scheme = scheme_for_appearance(appearance)
	if overrides.color_scheme ~= scheme then
		overrides.color_scheme = scheme
		window:set_config_overrides(overrides)
	end
end)

return config
