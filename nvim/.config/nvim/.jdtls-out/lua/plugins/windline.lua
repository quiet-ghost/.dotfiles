return {
  "windwp/windline.nvim",
  event = "VeryLazy",
  config = function()
    local windline = require("windline")
    -- Override the colors_name function
    local original_setup = windline.setup
    windline.setup = function(opts)
      opts = opts or {}
      opts.colors_name = function(colors)
        -- Rose Pine Moon theme colors
        colors.magenta = "#c4a7e7" -- iris
        colors.blue = "#9ccfd8" -- foam
        colors.white = "#e0def4" -- text
        colors.green = "#3e8fb0" -- pine
        colors.red = "#eb6f92" -- love
        colors.yellow = "#f6c177" -- gold
        colors.cyan = "#9ccfd8" -- foam
        colors.orange = "#ea9a97" -- rose
        colors.black = "#191724" -- base
        colors.gray = "#908caa" -- muted
        return colors
      end
      return original_setup(opts)
    end
    require("wlsample.evil_line")
    windline.remove_status_by_ft({ "qf", "Trouble" })
  end,
}
