local map = vim.keymap.set

map("n", "<leader>pv", function()
  require("neo-tree.command").execute({
    toggle = true,
    dir = vim.fn.getcwd(),
  })
end, { desc = "Explorer (cwd)" })

map("n", "<leader>tc", ":CloakToggle<CR>", { desc = "CloakToggle" })
map("n", "<leader>lr", "<cmd>LspRestart<cr>", { desc = "Restart LSP" })
map("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>", { desc = "tmux sessionizer" })
map("n", "<C-n>", "<cmd>UndotreeToggle<CR>", { desc = "Toggle Undotree" })

