local map = vim.keymap.set

-- General keymaps
map("n", "<leader>pv", ":Ex<CR>", { desc = "Open netrw" })

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

-- MCPHub
map("n", "<leader>mc", "<cmd>MCPHub<CR>", { desc = "Start MCPHub" })

-- Java Settings
map("n", "<leader>in", "O/**<CR><CR>/<Esc>kA ")
map("v", "<leader>in", "c/**<CR><CR>/<Esc>kA ")

-- Java JDTLS keymaps (buffer-local setup via autocmd)
map("n", "<leader>jo", require("utils.jdtls").organize_imports, { desc = "Organize Java imports" })
map("n", "<leader>jv", require("utils.jdtls").extract_variable, { desc = "Extract variable" })
map("v", "<leader>jv", require("utils.jdtls").extract_variable_visual, { desc = "Extract variable (visual)" })
map("n", "<leader>jk", require("utils.jdtls").extract_constant, { desc = "Extract constant" })
map("v", "<leader>jk", require("utils.jdtls").extract_constant_visual, { desc = "Extract constant (visual)" })
map("v", "<leader>jm", require("utils.jdtls").extract_method_visual, { desc = "Extract method (visual)" })
map("n", "<leader>jtf", require("utils.jdtls").test_class, { desc = "Test Java class" })
map("n", "<leader>jtn", require("utils.jdtls").test_nearest_method, { desc = "Test nearest Java method" })
map("n", "<leader>jg", require("utils.jdtls").generate_getters_setters, { desc = "Generate getters/setters" })

-- DAP keymaps
map("n", "<C-b>", "<cmd>DapToggleBreakpoint<CR>", { desc = "DAP Toggle Breakpoint" })
map("n", "<C-M-c>", "<cmd>DapContinue<CR>", { desc = "DAP Continue" })
map("n", "<C-M-j>", "<cmd>DapStepOver<CR>", { desc = "DAP Step Over" })
map("n", "<C-M-k>", "<cmd>DapStepInto<CR>", { desc = "DAP Step Into" })
map("n", "<C-M-l>", "<cmd>DapStepOut<CR>", { desc = "DAP Step Out" })
map("n", "<C-M-u>", "<cmd>lua require('dapui').toggle()<CR>", { desc = "Toggle DAP UI" })
map("n", "<C-M-t>", "<cmd>DapTerminate<CR>", { desc = "DAP Terminate" })
map("n", "<leader>ts", function()
  require("neotest").summary.toggle()
end, { desc = "Toggle Test Summary" })

-- References Notes
map("n", "<leader>jn", require("utils.notes").search_java_notes, { desc = "Search JavaNote.md" })
map("n", "<leader>pn", require("utils.notes").search_python_notes, { desc = "Search PythonNote.md" })
map("n", "<leader>cpp", require("utils.notes").search_cpp_notes, { desc = "Search CppNote.md" })
map("n", "<leader>sql", require("utils.notes").search_sql_notes, { desc = "Search MySQLNote.md" })

--DevDocs
map("n", "<M-i>", "<cmd>DevdocsOpen<CR>", { desc = "Open DevDocs" })

-- telescope-tmux-manager plugin (custom popup)
map("n", "<A-w>", require("utils.tmux").session_manager, { desc = "Tmux Manager" })

-- Manual tmux session switch (backup)
vim.api.nvim_create_user_command("TmuxSwitch", function(opts)
  vim.fn.system("tmux switch-client -t " .. opts.args)
end, { nargs = 1, desc = "Switch to tmux session" })

-- JavaFX keymaps
map("n", "<leader>jf", function()
  require("utils.javafx").compile_and_run()
end, { desc = "Run JavaFX in right tmux pane" })

map("n", "<leader>jc", function()
  require("utils.javafx").compile_only()
end, { desc = "Compile Java/JavaFX (check errors)" })

-- Create new file with name prompt (centered)
map("n", "<leader>fn", require("utils.files").create_new_file, { desc = "Create new file" })

-- Keybinding for JavaFX template (leader + fx)
vim.keymap.set("n", "<leader>fx", ":JavaFX<CR>", { desc = "Insert JavaFX template" })

-- JavaFX Template Command (uses utils/javafx.lua)
vim.api.nvim_create_user_command("JavaFX", function()
  require("utils.javafx").insert_template()
end, { desc = "Insert JavaFX template" })

-- Keybinding for JavaFX template (leader + fx)
vim.keymap.set("n", "<leader>fx", function()
  require("utils.javafx").insert_template()
end, { desc = "Insert JavaFX template" })
