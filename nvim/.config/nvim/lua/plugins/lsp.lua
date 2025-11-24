return {
  "neovim/nvim-lspconfig",
  keys = {
    {
      "gd",
      function()
        require("telescope.builtin").lsp_definitions({ reuse_win = true })
      end,
      desc = "Goto Definition",
    },
    {
      "gr",
      function()
        require("telescope.builtin").lsp_references()
      end,
      desc = "References",
    },
    {
      "gI",
      function()
        require("telescope.builtin").lsp_implementations({ reuse_win = true })
      end,
      desc = "Goto Implementation",
    },
    {
      "gy",
      function()
        require("telescope.builtin").lsp_type_definitions({ reuse_win = true })
      end,
      desc = "Goto T[y]pe Definition",
    },
    {
      "<leader>rn",
      function()
        local current_name = vim.fn.expand("<cword>")
        vim.ui.input({
          prompt = "Rename to: ",
          default = current_name,
        }, function(new_name)
          if new_name and new_name ~= current_name then
            vim.lsp.buf.rename(new_name)
          end
        end)
      end,
      desc = "Rename with prompt",
    },
  },
}
