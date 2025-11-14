return {
  "nvim-telescope/telescope.nvim",
  config = function()
    -- Set custom colors
    vim.api.nvim_set_hl(0, "TelescopePromptTitle", { fg = "#08f4d0", bold = true })
    vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { fg = "#08f4d0", bold = true })
    vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { fg = "#08f4d0", bold = true })
    vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = "#08f4d0" })

    -- Setup telescope
    require("telescope").setup({
      defaults = {
        borderchars = { " ", " ", " ", " ", " ", " ", " ", " " },
        prompt_prefix = "  ",
        selection_caret = " ",
        entry_prefix = "  ",
        layout_strategy = "horizontal",
        file_ignore_patterns = {
          "node_modules/*",
        },
        layout_config = {
          horizontal = {
            prompt_position = "bottom",
            width = { padding = 0 },
            height = { padding = 0 },
            preview_width = 0.55,
          },
          width = 0.87,
          height = 0.80,
        },
        sorting_strategy = "descending",
        winblend = 0,
      },
      pickers = {
        find_files = {
          prompt_title = "Search Files",
          results_title = "Files",
          preview_title = "Preview",
          hidden = true,
        },
        git_files = {
          hidden = true,
        },
        live_grep = {
          prompt_title = "Search Text",
          results_title = "Matches",
        },
        buffers = {
          prompt_title = "Buffers",
        },
      },
      extensions = {
        mux_manager = {
          prompt_title = "Tmux Sessions",
          results_title = "Available Sessions",
          preview_title = "Session Info",
        },
      },
    })
  end,
}
