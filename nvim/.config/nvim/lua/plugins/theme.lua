return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 1000,
    opts = {
      variant = "moon",
      disable_background = true,
      disable_float_background = true,
    },
    config = function(_, opts)
      require("rose-pine").setup(opts)
      vim.cmd.colorscheme("rose-pine-moon")

      vim.api.nvim_set_hl(0, "Cursor", { fg = "#232136", bg = "#569fbc" })
      vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#908caa", bg = "NONE", italic = true })
      vim.api.nvim_set_hl(0, "LspReferenceText", { bg = "#2f2c3c" })
      vim.api.nvim_set_hl(0, "LspReferenceRead", { bg = "#2f2c3c" })
      vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = "#2f2c3c" })
      vim.api.nvim_set_hl(0, "YankHighlight", { bg = "#56d4dd" })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine-moon",
    },
  },
}
