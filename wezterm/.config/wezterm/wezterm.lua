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

-- Cursor style
config.default_cursor_style = "SteadyBlock"

-- Window appearance
config.window_background_opacity = 1.0 -- Adjust if background-blur is desired
config.macos_window_background_blur = 10 -- Enable blur if supported
config.color_scheme = "sRGB" -- Matches window-colorspace = srgb
config.enable_tab_bar = false -- Disable tab bar

-- Shell integration (approximating Ghostty's zsh integration)
config.set_environment_variables = {
	TERM = "xterm-256color", -- Common TERM setting for zsh
}

-- Enable bold text to use bright colors
config.bold_brightens_ansi_colors = true

-- Theme switching based on system appearance (matches window-theme = auto)
function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "MaterialOcean" -- Use MaterialOcean for dark mode
	else
		return "MaterialOcean" -- Use same or a light theme if desired
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
