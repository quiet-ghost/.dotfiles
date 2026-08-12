local map = vim.keymap.set

map("n", "<M-e>", "<cmd>cnext<CR>zz", { desc = "Next quickfix item" })
map("n", "<M-q>", "<cmd>cprev<CR>zz", { desc = "Previous quickfix item" })

map("n", "<leader>q", function()
  require("quicker").toggle()
end, { desc = "Toggle quickfix" })

map("n", "<leader>qc", function()
  vim.fn.setqflist({}, "r")
  vim.cmd("cclose")
end, { desc = "Clear and close quickfix" })

map("n", "<leader>l", function()
  require("quicker").toggle({ loclist = true })
end, { desc = "Toggle loclist" })
