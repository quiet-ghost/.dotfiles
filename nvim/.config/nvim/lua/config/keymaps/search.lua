local map = vim.keymap.set

map("n", "<leader>ff", function()
  require("telescope.builtin").find_files({ cwd = vim.fn.getcwd() })
end, { desc = "Find Files (cwd)" })

map("n", "<leader>fF", function()
  require("telescope.builtin").find_files({ cwd = require("lazyvim.util").root() })
end, { desc = "Find Files (Root Dir)" })

map("n", "<leader>fh", function()
  require("telescope.builtin").help_tags()
end)

map("n", "<leader>fg", function()
  require("utils.multi-grep")()
end)

map("n", "<leader>fb", function()
  require("telescope.builtin").buffers()
end)

map("n", "<leader>fl", function()
  require("telescope.builtin").colorscheme()
end, { desc = "Select Colorscheme" })

map("n", "<leader>fj", function()
  require("telescope.builtin").current_buffer_fuzzy_find()
end, { desc = "Search in current buffer" })

map("n", "<leader>gw", function()
  require("telescope.builtin").grep_string()
end)

map("n", "<leader>fa", function()
  ---@diagnostic disable-next-line: param-type-mismatch
  require("telescope.builtin").find_files({ cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy") })
end)

map("n", "<leader>en", function()
  require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
end)

map("n", "<leader>eo", function()
  require("telescope.builtin").find_files({ cwd = "~/.config/nvim-backup/" })
end)

map("n", "<leader>fp", function()
  require("telescope.builtin").find_files({ cwd = "~/.config/nvim/lua/plugins/" })
end)

-- Telescope prompt history cycling (requires smart_history extension)
map("i", "<M-k>", function()
  require("telescope.actions").cycle_history_prev(vim.api.nvim_get_current_buf())
end, { desc = "Telescope: previous history" })

map("i", "<M-j>", function()
  require("telescope.actions").cycle_history_next(vim.api.nvim_get_current_buf())
end, { desc = "Telescope: next history" })

map("n", "<leader>xx", "<cmd>Telescope diagnostics<CR>", { desc = "Diagnostics (workspace)" })
map("n", "<leader>xd", "<cmd>Telescope diagnostics bufnr=0<CR>", { desc = "Diagnostics (buffer)" })
map("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find TODOs" })
