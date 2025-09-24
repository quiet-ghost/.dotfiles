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

-- CodeCompanion chat buffer keymaps
vim.api.nvim_create_autocmd("FileType", {
  pattern = "codecompanion",
  callback = function()
    map("n", "<C-s>", "<cmd>CodeCompanionSave<CR>", { buffer = true, desc = "Save chat buffer" })
    map("n", "q", "<cmd>CodeCompanionClose<CR>", { buffer = true, desc = "Close chat buffer" })
  end,
})

-- CodeCompanion Code Actions
map("v", "<leader>cx", "<cmd>CodeCompanion fix<CR>", { desc = "Fix selected code" })
map("v", "<leader>ct", "<cmd>CodeCompanion tests<CR>", { desc = "Generate tests for selected code" })

-- Java Running
map("n", "<leader>jr", "<cmd>JavaRunnerRunMain<CR>", { desc = "Run Java Main" })
map("n", "<leader>jrs", "<cmd>JavaRunnerStopMain<CR>", { desc = "Stop Java Main" })
map("n", "<leader>jrl", "<cmd>JavaRunnerToggleLogs<CR>", { desc = "Toggle Java Runner Logs" })

-- Java Testing
map("n", "<leader>jtc", "<cmd>JavaTestRunCurrentClass<CR>", { desc = "Run Current Test Class" })
map("n", "<leader>jtm", "<cmd>JavaTestRunCurrentMethod<CR>", { desc = "Run Current Test Method" })
map("n", "<leader>jtdc", "<cmd>JavaTestDebugCurrentClass<CR>", { desc = "Debug Current Test Class" })
map("n", "<leader>jtdm", "<cmd>JavaTestDebugCurrentMethod<CR>", { desc = "Debug Current Test Method" })
map("n", "<leader>jtr", "<cmd>JavaTestViewLastReport<CR>", { desc = "View Last Test Report" })

-- Java DAP
map("n", "<leader>jd", "<cmd>JavaDapConfig<CR>", { desc = "Configure Java DAP" })

-- Java project debugging (using different key)
map("n", "<leader>jdb", function()
  local root = vim.fn.getcwd()
  local java_file = vim.fn.expand("%:p")
  local initial_cwd = vim.g.initial_cwd or "not set"

  print("Current working directory: " .. root)
  print("Initial directory: " .. initial_cwd)
  print("Current Java file: " .. java_file)

  -- Try to find project root
  local project_markers = { "pom.xml", "build.gradle", "settings.gradle", "src" }
  local current_dir = vim.fn.expand("%:p:h")

  while current_dir ~= "/" do
    for _, marker in ipairs(project_markers) do
      if
        vim.fn.filereadable(current_dir .. "/" .. marker) == 1
        or vim.fn.isdirectory(current_dir .. "/" .. marker) == 1
      then
        print("Detected project root: " .. current_dir)
        return
      end
    end
    current_dir = vim.fn.fnamemodify(current_dir, ":h")
  end

  print("No project root detected")
end, { desc = "Debug Java project detection" })

-- Fix terminal directory - restore to file's directory (using different key)
map("n", "<leader>jcd", function()
  local file_dir = vim.fn.expand("%:p:h")
  vim.g.initial_cwd = file_dir
  vim.cmd("cd " .. vim.fn.fnameescape(file_dir))
  print("Fixed directory to: " .. file_dir)
end, { desc = "Fix terminal directory to current file's directory" })

-- ============================================
-- Refactoring Keymaps (Two complementary systems)
-- ============================================

-- [1] Java-specific refactoring (nvim-java-refactor via JDTLS)
-- These use <leader>jr prefix for Java-specific operations

-- [2] General refactoring (refactoring.nvim - works with Java and other languages)
-- These keymaps are defined in plugins/refactoring.lua to avoid syntax issues
-- Using <leader>r prefix for multi-language refactoring operations

-- Java Refactoring
map("n", "<leader>jrv", "<cmd>JavaRefactorExtractVariable<CR>", { desc = "Extract Variable" })
map("n", "<leader>jrc", "<cmd>JavaRefactorExtractConstant<CR>", { desc = "Extract Constant" })
map("n", "<leader>jrm", "<cmd>JavaRefactorExtractMethod<CR>", { desc = "Extract Method" })
map("n", "<leader>jrf", "<cmd>JavaRefactorExtractField<CR>", { desc = "Extract Field" })

-- Java Build
map("n", "<leader>jbb", "<cmd>JavaBuildBuildWorkspace<CR>", { desc = "Build Workspace" })
map("n", "<leader>jbc", "<cmd>JavaBuildCleanWorkspace<CR>", { desc = "Clean Workspace" })

-- Java Settings
map("n", "<leader>jsr", "<cmd>JavaSettingsChangeRuntime<CR>", { desc = "Change Java Runtime" })
map("n", "<leader>in", "O/**<CR><CR>/<Esc>kA ")
map("v", "<leader>in", "c/**<CR><CR>/<Esc>kA ")

-- Java Profiles (restored original)
map("n", "<leader>jp", "<cmd>JavaProfile<CR>", { desc = "Java Profiles" })

-- DAP keymaps
map("n", "<F2>", "<cmd>DapContinue<CR>", { desc = "DAP Continue" })
map("n", "<C-b>", "<cmd>DapToggleBreakpoint<CR>", { desc = "DAP Toggle Breakpoint" })
map("n", "<F3>", "<cmd>DapStepOver<CR>", { desc = "DAP Step Over" })
map("n", "<F4>", "<cmd>DapStepInto<CR>", { desc = "DAP Step Into" })
map("n", "<leader>do", "<cmd>DapStepOut<CR>", { desc = "DAP Step Out" })
map("n", "<F1>", "<cmd>lua require('dapui').toggle()<CR>", { desc = "Toggle DAP UI" })
map("n", "<F5", "<cmd>DapTerminate<CR>", { desc = "DAP Terminate" })
map("n", "<leader>ts", function()
  require("neotest").summary.toggle()
end, { desc = "Toggle Test Summary" })

-- References Notes
map("n", "<leader>jn", function()
  require("telescope.builtin").live_grep({
    search_dirs = { "~/personal/Notes/References/Java/JavaNote.md" },
    prompt_title = "Search JavaNote.md",
  })
end, { desc = "Search JavaNote.md" })
map("n", "<leader>pn", function()
  require("telescope.builtin").live_grep({
    search_dirs = { "~/personal/Notes/References/Python/PythonNote.md" },
    prompt_title = "Search PythonNote.md",
  })
end, { desc = "Search PythonNote.md" })
map("n", "<leader>cpp", function()
  require("telescope.builtin").live_grep({
    search_dirs = { "~/personal/Notes/References/C++/CppNote.md" },
    prompt_title = "Search CppNote.md",
  })
end, { desc = "Search CppNote.md" })
map("n", "<leader>sql", function()
  require("telescope.builtin").live_grep({
    search_dirs = { "~/personal/Notes/References/MySQL/MySQLNote.md" },
    prompt_title = "Search MySQLNote.md",
  })
end, { desc = "Search MySQLNote.md" })

--DevDocs
map("n", "<M-i>", "<cmd>DevdocsOpen<CR>", { desc = "Open DevDocs" })

-- telescope-tmux-manager plugin (custom popup)
map("n", "<A-w>", function()
  require("telescope").extensions.mux_manager.sessions()
end, { desc = "Tmux Manager" })

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
map("n", "<leader>fn", function()
  -- Create a centered floating window for input
  local width = 60
  local height = 1
  local buf = vim.api.nvim_create_buf(false, true)

  local ui = vim.api.nvim_list_uis()[1]
  local win_width = ui.width
  local win_height = ui.height

  local col = math.floor((win_width - width) / 2)
  local row = math.floor((win_height - height) / 2)

  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " Create New File ",
    title_pos = "center",
  }

  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Set prompt text
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
  vim.api.nvim_buf_set_option(buf, "modifiable", true)

  -- Start insert mode
  vim.cmd("startinsert")

  -- Set up keymaps for the floating window
  vim.api.nvim_buf_set_keymap(buf, "i", "<CR>", "", {
    callback = function()
      local input = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1]
      vim.api.nvim_win_close(win, true)

      if input and input ~= "" then
        -- Handle paths if user includes them (e.g., src/Animal.java)
        local dir = vim.fn.fnamemodify(input, ":h")
        if dir ~= "." then
          vim.fn.mkdir(dir, "p")
        end
        vim.cmd("edit " .. input)
      end
    end,
    noremap = true,
    silent = true,
  })

  vim.api.nvim_buf_set_keymap(buf, "i", "<Esc>", "", {
    callback = function()
      vim.api.nvim_win_close(win, true)
    end,
    noremap = true,
    silent = true,
  })

  -- Add a placeholder/hint text
  vim.fn.prompt_setprompt(buf, "File name (e.g., Animal.java): ")
end, { desc = "Create new file" })

-- JavaFX Template Command

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
