return {
  {
    "folke/persistence.nvim",
    -- already pulled in by LazyVim core; just add keymaps and config here
    keys = {
      {
        "<leader>rs",
        function()
          require("persistence").load()
        end,
        desc = "Restore Session (cwd)",
      },
      {
        "<leader>rl",
        function()
          require("persistence").load({ last = true })
        end,
        desc = "Restore Last Session",
      },
      {
        "<leader>Sd",
        function()
          require("persistence").stop()
        end,
        desc = "Stop Session Save on Exit",
      },
    },
  },
}
