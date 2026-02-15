return {
  "ahmeds0s/manim_runner.nvim",
  enabled = false,
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "akinsho/toggleterm.nvim",
  },
  keys = {
    {
      "<leader>mr",
      function()
        require("manim.render").render_scene()
      end,
      desc = "Render manim scene under cursor",
    },
  },
}
