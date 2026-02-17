return {
  {
    "ray-x/go.nvim",
    dependencies = {
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    ft = { "go", "gomod", "gowork", "gotmpl" },
    build = ':lua require("go.install").update_all_sync()',
    opts = {
      -- Use gopls from LazyVim's existing lang.go or system path
      lsp_cfg = false, -- LazyVim already configures gopls via nvim-lspconfig
      lsp_gofumpt = true,
      lsp_on_attach = false, -- don't override LazyVim's on_attach
      dap_debug = true,
      dap_debug_keymap = false, -- we manage DAP keymaps manually
      -- Diagnostics
      diagnostic = false, -- LazyVim handles diagnostics display
      -- Test output
      test_runner = "go",
      run_in_floaterm = false,
      -- Format on save via gofumpt
      lsp_document_formatting = false, -- let conform handle it
      -- Icons
      icons = { breakpoint = "🔴", currentpos = "👉" },
    },
    keys = {
      { "<leader>gor", "<cmd>GoRun<cr>", ft = "go", desc = "Go Run" },
      { "<leader>got", "<cmd>GoTest<cr>", ft = "go", desc = "Go Test" },
      { "<leader>gof", "<cmd>GoTestFunc<cr>", ft = "go", desc = "Go Test Function" },
      { "<leader>goc", "<cmd>GoCoverage<cr>", ft = "go", desc = "Go Coverage" },
      { "<leader>goi", "<cmd>GoImports<cr>", ft = "go", desc = "Go Imports" },
      { "<leader>goI", "<cmd>GoImpl<cr>", ft = "go", desc = "Go Implement Interface" },
      { "<leader>gos", "<cmd>GoFillStruct<cr>", ft = "go", desc = "Go Fill Struct" },
      { "<leader>goS", "<cmd>GoFillSwitch<cr>", ft = "go", desc = "Go Fill Switch" },
      { "<leader>goe", "<cmd>GoIfErr<cr>", ft = "go", desc = "Go If Err" },
      { "<leader>goT", "<cmd>GoAddTag<cr>", ft = "go", desc = "Go Add Struct Tags" },
      { "<leader>god", "<cmd>GoDoc<cr>", ft = "go", desc = "Go Doc" },
    },
    config = function(_, opts)
      require("go").setup(opts)

      -- Add gofumpt/goimports to conform for format-on-save
      local ok, conform = pcall(require, "conform")
      if ok then
        conform.formatters_by_ft = conform.formatters_by_ft or {}
        conform.formatters_by_ft.go = { "goimports", "gofumpt" }
      end
    end,
  },
}
