local wezterm = require("wezterm")
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- Load the custom color scheme from colors.lua
local custom_colors = require("colors")
for name, scheme in pairs(custom_colors.color_schemes) do
	config.color_schemes = config.color_schemes or {}
	config.color_schemes[name] = scheme
end

-- Set the color scheme to the custom one
config.color_scheme = "MaterialOcean"

-- Font configuration from Ghostty config
config.font = wezterm.font("FiraCode Nerd Font Mono SemBd")
config.font_size = 14

-- Cursor style
config.default_cursor_style = "SteadyBlock"

-- Window appearance
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.window_padding = {
	top = 0,
	right = 0,
	bottom = 0,
	left = 0,
}

-- Shell integration (approximating Ghostty's zsh integration)
config.set_environment_variables = { TERM = "xterm-256color" }

-- Enable bold text to use bright colors
config.bold_brightens_ansi_colors = true

-- Position the tab bar at the top
config.tab_bar_at_bottom = false

-- Explicitly set tab bar colors to match Catppuccin Mocha
config.colors = {
	tab_bar = {
		background = "#0F111A", -- Matches tmux bar background
		active_tab = {
			bg_color = "#0F111A", -- Muted cyan to match tmux active window
			fg_color = "#AEBAC0",
			intensity = "Normal", -- No bold, matches tmux
		},
		inactive_tab = {
			bg_color = "#0F111A", -- Matches tmux inactive window background
			fg_color = "#414752", -- Matches tmux inactive window text
		},
		new_tab = {
			bg_color = "#0F111A",
			fg_color = "#414752",
		},
	},
}

--Session Config
config.unix_domains = {
	{
		name = "unix",
	},
}

-- This causes `wezterm` to act as though it was started as
-- `wezterm connect unix` by default, connecting to the unix
-- domain on startup.
-- If you prefer to connect manually, leave out this line.
config.default_gui_startup_args = { "connect", "unix" }

return config
