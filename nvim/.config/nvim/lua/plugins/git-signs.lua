return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" }, -- Load on buffer read/new file
  opts = {
    signs = {
      add = { text = "+" }, -- Sign for added lines
      change = { text = "~" }, -- Sign for changed lines
      delete = { text = "-" }, -- Sign for deleted lines
      topdelete = { text = "‾" }, -- Sign for deleted lines at the top
      changedelete = { text = "~" }, -- Sign for changed and deleted lines
      untracked = { text = "┆" }, -- Sign for untracked files
    },
    signcolumn = true, -- Show signs in the sign column
    numhl = false, -- Don’t highlight line numbers
    linehl = false, -- Don’t highlight the entire line
    word_diff = false, -- Don’t enable word diff by default
    watch_gitdir = {
      interval = 1000, -- Check for Git dir changes every 1000ms
      follow_files = true, -- Follow files moved in Git
    },
    attach_to_untracked = true, -- Attach to untracked files
    current_line_blame = true, -- Don’t enable blame by default (toggle with keybinding)
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol", -- Show blame at end of line
      delay = 200, -- Delay before showing blame
      ignore_whitespace = false,
    },
    sign_priority = 6, -- Lower priority than todo-comments (8) and LSP diagnostics (10)
    update_debounce = 100, -- Debounce updates to 100ms
    status_formatter = nil, -- Use default status line format
    max_file_length = 40000, -- Disable for files longer than 40,000 lines
    preview_config = {
      border = "single",
      style = "minimal",
      relative = "cursor",
      row = 0,
      col = 1,
    },
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map("n", "]h", function()
        if vim.wo.diff then
          return "]h"
        end
        vim.schedule(function()
          gs.next_hunk()
        end)
        return "<Ignore>"
      end, { expr = true, desc = "Next Hunk" })

      map("n", "[h", function()
        if vim.wo.diff then
          return "[h"
        end
        vim.schedule(function()
          gs.prev_hunk()
        end)
        return "<Ignore>"
      end, { expr = true, desc = "Previous Hunk" })

      -- Actions
      map("n", "<leader>gs", gs.stage_hunk, { desc = "Stage Hunk" })
      map("n", "<leader>gr", gs.reset_hunk, { desc = "Reset Hunk" })
      map("v", "<leader>gs", function()
        gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, { desc = "Stage Hunk" })
      map("v", "<leader>gr", function()
        gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, { desc = "Reset Hunk" })
      map("n", "<leader>gS", gs.stage_buffer, { desc = "Stage Buffer" })
      map("n", "<leader>gu", gs.undo_stage_hunk, { desc = "Undo Stage Hunk" })
      map("n", "<leader>gR", gs.reset_buffer, { desc = "Reset Buffer" })
      map("n", "<leader>gp", gs.preview_hunk, { desc = "Preview Hunk" })
      map("n", "<leader>gb", function()
        gs.blame_line({ full = true })
      end, { desc = "Blame Line" })
      map("n", "<leader>gt", gs.toggle_current_line_blame, { desc = "Toggle Blame" })
      map("n", "<leader>gd", gs.diffthis, { desc = "Diff This" })
      map("n", "<leader>gD", function()
        gs.diffthis("~")
      end, { desc = "Diff This (Against Last Commit)" })
      map("n", "<leader>gw", gs.toggle_word_diff, { desc = "Toggle Word Diff" })
    end,
  },
}
