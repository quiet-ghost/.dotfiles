local map = vim.keymap.set

-- Hunk navigation (buffer-local, set via gitsigns on_attach)
-- These are registered in git-signs.lua on_attach since they need the gs reference.
-- All other git keymaps live here.

-- Diffview
map("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Diff view (working copy)" })
map("n", "<leader>gc", "<cmd>DiffviewClose<cr>", { desc = "Close diff view" })
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "File history (current)" })
map("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "File history (repo)" })

-- Neogit
map("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Neogit" })
map("n", "<leader>gC", "<cmd>Neogit commit<cr>", { desc = "Neogit commit" })
map("n", "<leader>gP", "<cmd>Neogit push<cr>", { desc = "Neogit push" })
map("n", "<leader>gF", "<cmd>Neogit pull<cr>", { desc = "Neogit pull" })

-- Blame toggle (global, not buffer-local)
map("n", "<leader>b", function()
  require("gitsigns").toggle_current_line_blame()
end, { desc = "Toggle Git Blame" })
