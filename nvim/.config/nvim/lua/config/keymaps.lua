local map = vim.keymap.set

-- General keymaps
map("n", "<leader>sz", ":source $HOME/.config/nvim/init.lua <CR>")
map("n", "<leader>pv", function()
  require("neo-tree.command").execute({
    toggle = true,
    dir = vim.fn.getcwd(),
  })
end, { desc = "Explorer (cwd)" })
map("n", "<leader>tc", ":CloakToggle<CR>", { desc = "CloakToggle" })

-- Quickfix navigation
map("n", "<M-e>", "<cmd>cnext<CR>zz", { desc = "Next quickfix item" })
map("n", "<M-q>", "<cmd>cprev<CR>zz", { desc = "Previous quickfix item" })

-- telescope overwriting search
map("n", "<leader>ff", function()
  require("telescope.builtin").find_files({ cwd = vim.fn.getcwd() })
end, { desc = "Find Files (cwd)" })
map("n", "<leader>fF", function()
  require("telescope.builtin").find_files({ cwd = require("lazyvim.util").root() })
end, { desc = "Find Files (Root Dir)" })

map("n", "<leader>b", "<cmd>silent ToggleBlameLine<CR>", { desc = "Toggle Git Blame" })
--- Special keymaps
map("i", "jj", "<esc>", { desc = "Escape" }) -- Escape
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" }) -- Move selected lines down
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" }) -- Move selected lines up

map("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" }) -- Join lines and keep cursor position
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" }) -- Scroll down and center
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" }) -- Scroll up and center
map("n", "n", "nzzzv", { desc = "Next search result and center" }) -- Next search result and center
map("n", "N", "Nzzzv", { desc = "Previous search result and center" }) -- Previous search result and center

map("x", "<leader>p", [["_dP]], { desc = "Paste without overwriting register" }) -- Paste without overwriting register

map("n", "<leader>y", [["+y]], { desc = "Yank to system clipboard" }) -- Yank to system clipboard
map("v", "<leader>y", [["+y]], { desc = "Yank to system clipboard" }) -- Yank to system clipboard
map("n", "<leader>Y", [["+Y]], { desc = "Yank to system clipboard (line)" }) -- Yank to system clipboard (line)

map("n", "<leader>d", [["_d]], { desc = "Delete without overwriting register" }) -- Delete without overwriting register
map("v", "<leader>d", [["_d]], { desc = "Delete without overwriting register" }) -- Delete without overwriting register

map("i", "<C-c>", "<Esc>", { desc = "Exit insert mode" }) -- Exit insert mode

map("n", "Q", "<nop>", { desc = "Disable Q" }) -- Disable Q

map("n", "<leader>lr", "<cmd>LspRestart<cr>", { desc = "Restart LSP" })

map("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>", { desc = "tmux sessionizer" }) -- tmux sessionizer
map("n", "<leader>f", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format current buffer" }) -- Format current buffer

map("n", "<leader>s", "%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>", { desc = "Replace word under cursor" }) -- Replace word under cursor- Keymaps are automatically loaded on the VeryLazy event

-- Telescope Keymaps
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
  require("telescope.builtin").find_files({ cwd = "~/plugins/" })
end)

-- TODO Keys
map("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find TODOs" })

-- Undotree
map("n", "<C-n>", "<cmd>UndotreeToggle<CR>", { desc = "Toggle Undotree" })

-- Java Runtime Management
map("n", "<leader>jj", function()
  require("utils.java").pick_jdk()
end, { desc = "Switch Java Runtime" })
map("n", "<leader>ji", function()
  require("utils.java").print_jdks()
end, { desc = "List Java Runtimes" })

-- Basic worktree commands
map("n", "<M-m>", "<cmd>Worktrees<cr>", { desc = "Git worktrees" })

-- Java Settings
map("n", "<leader>in", "O/**<CR><CR>/<Esc>kA ")
map("v", "<leader>in", "c/**<CR><CR>/<Esc>kA ")

-- DAP keymaps
map("n", "<C-b>", "<cmd>DapToggleBreakpoint<CR>", { desc = "DAP Toggle Breakpoint" })
map("n", "<F2>", "<cmd>DapContinue<CR>", { desc = "DAP Continue" })
map("n", "<F3>", "<cmd>DapStepOver<CR>", { desc = "DAP Step Over" })
map("n", "<F4>", "<cmd>DapStepInto<CR>", { desc = "DAP Step Into" })
map("n", "<F5>", "<cmd>DapStepOut<CR>", { desc = "DAP Step Out" })
map("n", "<F6>", "<cmd>DapUIToggle<CR>", { desc = "Toggle DAP UI" })
map("n", "<F7>", "<cmd>DapTerminate<CR>", { desc = "DAP Terminate" })
map("n", "<leader>ts", function()
  require("neotest").summary.toggle()
end, { desc = "Toggle Test Summary" })

-- References Notes
map("n", "<leader>jn", function()
  require("utils.notes").search_java_notes()
end, { desc = "Search JavaNote.md" })
map("n", "<leader>pn", function()
  require("utils.notes").search_python_notes()
end, { desc = "Search PythonNote.md" })
map("n", "<leader>cpp", function()
  require("utils.notes").search_cpp_notes()
end, { desc = "Search CppNote.md" })
map("n", "<leader>sql", function()
  require("utils.notes").search_sql_notes()
end, { desc = "Search MySQLNote.md" })

-- Manual tmux session switch (backup)
vim.api.nvim_create_user_command("TmuxSwitch", function(opts)
  vim.fn.system("tmux switch-client -t " .. opts.args)
end, { nargs = 1, desc = "Switch to tmux session" })

-- Unified Java/C++/Python run keymap
map("n", "<leader>jf", function()
  if vim.bo.filetype == "java" then
    require("utils.javafx").compile_and_run()
  elseif vim.bo.filetype == "cpp" or vim.bo.filetype == "c" then
    require("utils.cpp").compile_and_run()
  elseif vim.bo.filetype == "python" then
    require("utils.python").compile_and_run()
  else
    vim.notify("No run configuration for filetype: " .. vim.bo.filetype, vim.log.levels.WARN)
  end
end, { desc = "Run current file (Java/C++/Python)" })

map("n", "<leader>jc", function()
  require("utils.javafx").compile_only()
end, { desc = "Compile Java/JavaFX (check errors)" })

-- Create new file with name prompt (centered)
map("n", "<leader>fn", function()
  require("utils.files").create_new_file()
end, { desc = "Create new file" })

-- JavaFX Template Command (uses utils/javafx.lua)
vim.api.nvim_create_user_command("JavaFX", function()
  require("utils.javafx").insert_template()
end, { desc = "Insert JavaFX template" })

-- Keybinding for JavaFX template (leader + fx)
vim.keymap.set("n", "<leader>fx", function()
  require("utils.javafx").insert_template()
end, { desc = "Insert JavaFX template" })
