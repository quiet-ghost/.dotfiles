return {
  "quiet-ghost/cht-sh.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("cht-sh").setup()
  end,
}
