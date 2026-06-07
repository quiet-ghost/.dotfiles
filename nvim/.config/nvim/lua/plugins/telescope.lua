return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = {
    "nvim-telescope/telescope-smart-history.nvim",
    "nvim-telescope/telescope-ui-select.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function()
        return vim.fn.executable("make") == 1
      end,
    },
    "kkharji/sqlite.lua",
  },
  config = function()
    -- Setup telescope - rose-pine theme handles telescope colors automatically
    local telescope = require("telescope")

    telescope.setup({
      defaults = {
        -- borderchars = { " ", " ", " ", " ", " ", " ", " ", " " },
        borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        prompt_prefix = "  ",
        selection_caret = " ",
        -- entry_prefix = "  ",
        layout_strategy = "horizontal",
        file_ignore_patterns = {
          "node_modules/*",
        },
        layout_config = {
          horizontal = {
            prompt_position = "bottom",
            -- width = { padding = 0 },
            -- height = { padding = 0 },
            preview_width = 0.55,
          },
          -- width = 0.87,
          -- height = 0.80,
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
        colorscheme = {
          prompt_title = "Colorschemes",
          results_title = "Available Themes",
          preview_title = "Preview",
          enable_preview = true,
        },
      },
      -- Enable wrapping in preview for better markdown rendering
      preview = {
        treesitter = true,
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
        mux_manager = {
          prompt_title = "Tmux Sessions",
          results_title = "Available Sessions",
          preview_title = "Session Info",
        },
        ["ui-select"] = {
          require("telescope.themes").get_dropdown({
            -- Centered dropdown theme for vim.ui.select
            borderchars = { " ", " ", " ", " ", " ", " ", " ", " " },
          }),
        },
        smart_history = {
          cycle_wrap = true,
        },
      },
    })

    -- Load extensions
    pcall(telescope.load_extension, "fzf")
    telescope.load_extension("ui-select")
    pcall(telescope.load_extension, "smart_history")
  end,
}
