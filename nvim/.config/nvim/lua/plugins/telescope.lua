return {
  "nvim-telescope/telescope.nvim",
  config = function()
    -- Set custom colors
    vim.api.nvim_set_hl(0, "TelescopePromptTitle", { fg = "#08f4d0", bold = true })
    vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { fg = "#08f4d0", bold = true })
    vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { fg = "#08f4d0", bold = true })

    -- Setup telescope
    require("telescope").setup({
      defaults = {
        borderchars = { " ", " ", " ", " ", " ", " ", " ", " " },
        prompt_prefix = "  ",
        selection_caret = " ",
        entry_prefix = "  ",
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            prompt_position = "bottom",
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
        },
        live_grep = {
          prompt_title = "Search Text",
          results_title = "Matches",
        },
        buffers = {
          prompt_title = "Buffers",
        },
        extensions = {
          mux_manager = {
            prompt_title = "Tmux Sessions",
            results_title = "Available Sessions",
            preview_title = "Session Info",
          },
        },
      },
    })
  end,
}
