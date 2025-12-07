return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim", "nvim-mini/mini.icons" },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    -- DISABLED: Using markview.nvim instead for better preview support
    -- render-markdown doesn't work in telescope previews by design
    enabled = false,
    
    -- Keep config in case we want to re-enable later
    file_types = { "markdown" },
    anti_conceal = {
      enabled = true,
    },
    render_modes = { "n", "c", "t" },
  },
}
