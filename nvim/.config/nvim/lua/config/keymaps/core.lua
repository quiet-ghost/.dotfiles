local map = vim.keymap.set
local open_link = require("ghost.prelude").open_link

map("n", "<leader>sz", ":source $HOME/.config/nvim/init.lua <CR>")

map("i", "jj", "<esc>", { desc = "Escape" })
map("i", "JJ", "<esc>", { desc = "Escape" })
map("i", "<C-c>", "<Esc>", { desc = "Exit insert mode" })
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })

map("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
map("n", "n", "nzzzv", { desc = "Next search result and center" })
map("n", "N", "Nzzzv", { desc = "Previous search result and center" })

map("x", "<leader>p", [["_dP]], { desc = "Paste without overwriting register" })
map("n", "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
map("v", "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "Yank to system clipboard (line)" })
map("n", "<leader>d", [["_d]], { desc = "Delete without overwriting register" })
map("v", "<leader>d", [["_d]], { desc = "Delete without overwriting register" })

map("n", "Q", "<nop>", { desc = "Disable Q" })
map("n", "<leader>f", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format current buffer" })

map("n", "<leader>fn", function()
  require("utils.files").create_new_file()
end, { desc = "Create new file" })

map("n", "gx", open_link, { silent = true, desc = "Open link under cursor (supports markdown and parens)" })

local modes = { "n", "i", "v", "o", "t", "s", "x" }
local arrows = { "<Up>", "<Down>", "<Left>", "<Right>" }
for _, mode in ipairs(modes) do
  for _, key in ipairs(arrows) do
    vim.keymap.set(mode, key, "<Nop>", { noremap = true, silent = true })
  end
end

local enabled_modes = { "i", "c", "o", "t", "s", "x" }
for _, mode in ipairs(enabled_modes) do
  vim.keymap.set(mode, "<A-h>", "<Left>", { noremap = true, silent = true })
  vim.keymap.set(mode, "<A-j>", "<Down>", { noremap = true, silent = true })
  vim.keymap.set(mode, "<A-k>", "<Up>", { noremap = true, silent = true })
  vim.keymap.set(mode, "<A-l>", "<Right>", { noremap = true, silent = true })
end
