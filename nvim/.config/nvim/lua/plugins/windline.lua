return {
  "windwp/windline.nvim",
  config = function()
    local windline = require("windline")
    -- Override the colors_name function
    local original_setup = windline.setup
    windline.setup = function(opts)
      opts = opts or {}
      opts.colors_name = function(colors)
        -- Material theme colors
        colors.magenta = "#e066ff"
        colors.blue = "#7cb7ff"
        colors.white = "#D5CED9"
        colors.green = "#96E072"
        colors.red = "#ee5d43"
        colors.yellow = "#FFE66D"
        colors.cyan = "#00e8c6"
        colors.orange = "#f39c12"
        colors.black = "#23262E"
        colors.gray = "#746f77"
        return colors
      end
      return original_setup(opts)
    end
    require("wlsample.evil_line")
  end,
}
