local wezterm = require("wezterm")

local colors = {
	foreground = "#AEBAC0", -- Softer light gray
	background = "#0F111A", -- Unchanged dark navy
	cursor_bg = "#529CA6", -- Muted cyan
	cursor_fg = "#0F111A", -- Unchanged
	cursor_border = "#529CA6", -- Muted cyan
	selection_bg = "#414752", -- Softer dark gray
	selection_fg = "#AEBAC0", -- Softer light gray
	scrollbar_thumb = "#414752", -- Softer dark gray
	split = "#414752", -- Softer dark gray
	tab_bar = {
		background = "#0F111A", -- Matches tmux bar background
		active_tab = {
			bg_color = "#5C8370", -- Muted green to match tmux active window
			fg_color = "#0F111A", -- Dark text
			intensity = "Normal", -- No bold, matches tmux
		},
		inactive_tab = {
			bg_color = "#414752", -- Matches tmux inactive window background
			fg_color = "#AEBAC0", -- Matches tmux inactive window text
		},
		new_tab = {
			bg_color = "#0F111A",
			fg_color = "#AEBAC0",
		},
	},
}
return {
	color_schemes = {
		["Catppuccin Mocha"] = colors,
	},
}
