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
      local function apply_overrides()
        local set_hl = vim.api.nvim_set_hl

        set_hl(0, "Cursor", { fg = "#232136", bg = "#569fbc" })
        set_hl(0, "LspInlayHint", { fg = "#908caa", bg = "NONE", italic = true })
        set_hl(0, "LspReferenceText", { bg = "#2f2c3c" })
        set_hl(0, "LspReferenceRead", { bg = "#2f2c3c" })
        set_hl(0, "LspReferenceWrite", { bg = "#2f2c3c" })
        set_hl(0, "YankHighlight", { bg = "#56d4dd" })

        set_hl(0, "TelescopeSelection", { bg = "#2a273f", bold = true })
        set_hl(0, "TelescopeSelectionCaret", { fg = "#9ccfd8", bg = "#2a273f", bold = true })
        set_hl(0, "TelescopeMatching", { fg = "#f6c177", bold = true, underline = true })
      end

      require("rose-pine").setup(opts)

      local group = vim.api.nvim_create_augroup("RosePineHighlightOverrides", { clear = true })
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        pattern = "rose-pine*",
        callback = apply_overrides,
      })

      vim.cmd.colorscheme("rose-pine-moon")
      apply_overrides()
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine-moon",
    },
  },
}
