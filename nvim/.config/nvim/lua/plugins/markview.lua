return {
  "OXY2DEV/markview.nvim",
  ft = { "markdown", "md" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("markview").setup({
      experimental = {
        check_rtp = false, -- Disable the warning if issues persist
      },
      preview = {
        icon_provider = "devicons", -- Use devicons for file icons
        enable = true,
        filetypes = { "markdown", "md" },
      },
    })
  end,
}
