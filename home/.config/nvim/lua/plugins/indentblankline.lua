return {
  "lukas-reineke/indent-blankline.nvim",
  event = { "BufReadPost", "BufNewFile" }, -- Load on buffer open
  main = "ibl", -- Main module for v3.x
  opts = {
    indent = {
      char = "│", -- Vertical line for indent guides
      highlight = {
        "RainbowRed",
        "RainbowYellow",
        "RainbowBlue",
        "RainbowOrange",
        "RainbowGreen",
        "RainbowViolet",
        "RainbowCyan",
      },
    },
    scope = {
      enabled = true, -- Highlight current scope
      show_start = false,
      show_end = false,
    },
  },
  config = function(_, opts)
    -- Define rainbow colors
    vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#FF5555" })
    vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#FFFF55" })
    vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#55FFFF" })
    vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#FFAA55" })
    vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#55FF55" })
    vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#AA55FF" })
    vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#55AAFF" })

    -- Setup the plugin
    require("ibl").setup(opts)
  end,
}
