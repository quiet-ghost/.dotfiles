local wezterm = require("wezterm")

local colors = {
	foreground = "#B0BEC5", -- Light gray for text, matching original
	background = "#0F111A", -- Dark navy background, as requested
	cursor_bg = "#26C6DA", -- Cyan cursor
	cursor_fg = "#0F111A", -- Dark cursor text
	cursor_border = "#26C6DA", -- Cyan cursor border
	selection_bg = "#3E4451", -- Darker gray for selection
	selection_fg = "#B0BEC5", -- Light gray for selected text
	scrollbar_thumb = "#3E4451", -- Scrollbar color
	split = "#3E4451", -- Split pane divider
	tab_bar = {
		background = "#0F111A", -- Same as window background
		active_tab = { bg_color = "#26C6DA", fg_color = "#0F111A", intensity = "Bold" },
		inactive_tab = { bg_color = "#3E4451", fg_color = "#B0BEC5" },
		new_tab = { bg_color = "#0F111A", fg_color = "#B0BEC5" },
	},
}

return {
	color_schemes = {
		["MaterialOcean"] = colors,
	},
}
