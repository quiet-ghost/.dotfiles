return {
  {
    "supermaven-inc/supermaven-nvim",
    enabled = true,
    opts = {
      keymaps = {
        accept_suggestion = "<C-f>",
      },
    },
    config = function(_, opts)
      require("supermaven-nvim").setup(opts)
    end,
  },
}
