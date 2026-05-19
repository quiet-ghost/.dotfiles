return {
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    opts = {
      preset = "classic",
      options = {
        show_source = {
          enabled = true,
        },
        show_code = false,
        add_messages = {
          display_count = false,
          messages = true,
        },
        multilines = {
          enabled = true,
          always_show = true,
        },
      },
    },
    config = function(_, opts)
      require("tiny-inline-diagnostic").setup(opts)
      vim.diagnostic.config({ virtual_text = false })
    end,
  },
  {
    "mrcjkb/rustaceanvim",
    optional = true,
    dependencies = {
      "rachartier/tiny-inline-diagnostic.nvim",
    },
  },
}
