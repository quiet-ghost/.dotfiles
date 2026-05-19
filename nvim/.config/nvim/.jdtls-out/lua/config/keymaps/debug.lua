local map = vim.keymap.set

map("n", "<C-b>", "<cmd>DapToggleBreakpoint<CR>", { desc = "DAP Toggle Breakpoint" })
map("n", "<C-M-c>", "<cmd>DapContinue<CR>", { desc = "DAP Continue" })
map("n", "<C-M-n>", "<cmd>DapStepOver<CR>", { desc = "DAP Step Over" })
map("n", "<F4>", "<cmd>DapStepInto<CR>", { desc = "DAP Step Into" })
map("n", "<F5>", "<cmd>DapStepOut<CR>", { desc = "DAP Step Out" })
map("n", "<C-M-u>", "<cmd>lua require('dapui').toggle()<CR>", { desc = "Toggle DAP UI" })
map("n", "<F7>", "<cmd>DapTerminate<CR>", { desc = "DAP Terminate" })
