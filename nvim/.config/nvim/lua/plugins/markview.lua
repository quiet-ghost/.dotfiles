return {
  "OXY2DEV/markview.nvim",
  lazy = false,
  priority = 1000, -- Ensure it loads after dependencies
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
        enable = true,
        enable_hybrid_mode = true, -- Enable hybrid mode
        icon_provider = "devicons", -- Use devicons for file icons
        filetypes = { "markdown", "md" },
        
        -- IMPORTANT: Remove "nofile" from ignore_buftypes to enable rendering in telescope previews
        ignore_buftypes = {}, -- Empty = render in all buffer types including telescope previews
        
        -- Enable rendering in all relevant modes
        modes = { "n", "no", "c", "v", "i" }, -- Render in normal, operator-pending, command, visual, insert
        hybrid_modes = { "i" }, -- Show raw markdown when in insert mode (hybrid editing)
        
        -- Ensure it renders even in preview windows
        max_buf_lines = 10000, -- Increase limit for larger docs
      },
    })
  end,
}
