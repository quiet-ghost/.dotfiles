return {
  "neovim/nvim-lspconfig",
  -- init = function()
  --   local keys = require("lazyvim.plugins.lsp.keymaps").get()
  --   -- Disable default keymaps that we want to override
  --   keys[#keys + 1] = { "gd", false }
  --   keys[#keys + 1] = { "gr", false }
  --   keys[#keys + 1] = { "gI", false }
  --   keys[#keys + 1] = { "gy", false }
  -- end,
  opts = {
    servers = {
      ["*"] = {
        keys = {
          { "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", has = "definition" },
        },
      },
    },
  },
  keys = {
    -- Override with Telescope versions
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
  },
}
