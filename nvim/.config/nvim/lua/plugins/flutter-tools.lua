return {
  "nvim-flutter/flutter-tools.nvim",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "stevearc/dressing.nvim",
  },
  config = function()
    require("flutter-tools").setup({
      flutter_path = vim.fn.trim(vim.fn.system("mise where flutter")) .. "/bin/flutter",
      lsp = {
        color = { -- Show colors in LSP
          enabled = true,
        },
        settings = {
          showTodos = true,
          completeFunctionCalls = true,
          analysisExcludedFolders = {
            vim.fn.expand("$HOME/.pub-cache"),
          },
        },
      },
    })
  end,
}
