return {
  {
    "pmizio/typescript-tools.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
      "marilari88/twoslash-queries.nvim",
    },
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    config = function()
      local function is_valid_lsp_buffer(bufnr)
        local bufname = vim.api.nvim_buf_get_name(bufnr)

        if bufname == "" then
          return false
        end

        if vim.bo[bufnr].buftype ~= "" then
          return false
        end

        if bufname:match("^[%w.+-]+://") then
          return false
        end

        return true
      end

      require("typescript-tools").setup({
        root_dir = function(bufnr, on_dir)
          if not is_valid_lsp_buffer(bufnr) then
            return
          end

          local bufname = vim.api.nvim_buf_get_name(bufnr)
          local root = vim.fs.root(bufname, { "tsconfig.json", "jsconfig.json", "package.json", ".git" })
            or vim.fn.getcwd()

          on_dir(root)
        end,
        on_attach = function(client, buffer_number)
          require("twoslash-queries").attach(client, buffer_number)
        end,
        settings = {
          -- tsserver_path = "~/.bun/bin/tsgo",
          -- Performance: separate diagnostic server for large projects
          separate_diagnostic_server = true,
          -- When to publish diagnostics
          publish_diagnostic_on = "insert_leave",
          -- JSX auto-closing tags
          jsx_close_tag = {
            enable = true,
            filetypes = { "javascriptreact", "typescriptreact" },
          },
          tsserver_file_preferences = {
            includeInlayParameterNameHints = "all",
            includeInlayParameterNameHintsWhenArgumentMatchesName = true,
            includeInlayVariableTypeHints = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayEnumMemberValueHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            -- Enable auto imports
            includeCompletionsForModuleExports = true,
            includeCompletionsForImportStatements = true,
          },

          tsserver_format_options = {
            insertSpaceAfterOpeningAndBeforeClosingEmptyBraces = true,
            semicolons = "insert",
          },
          complete_function_calls = true,
          include_completions_with_insert_text = true,
          code_lens = "off",
          disable_member_code_lens = true,
          tsserver_max_memory = 4096,
        },
      })
    end,
  },
}
