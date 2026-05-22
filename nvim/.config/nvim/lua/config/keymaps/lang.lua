local map = vim.keymap.set

map("n", "<leader>jj", function()
  require("utils.java").pick_jdk()
end, { desc = "Switch Java Runtime" })

map("n", "<leader>jei", function()
  require("java_refactoring").show_refactor_menu()
end, { desc = "Java: Extract Interface" })

map("n", "<leader>ji", function()
  require("utils.java").print_jdks()
end, { desc = "List Java Runtimes" })

map("n", "<leader>in", "O/**<CR><CR>/<Esc>kA ")
map("v", "<leader>in", "c/**<CR><CR>/<Esc>kA ")

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

map("n", "<leader>jf", function()
  if vim.bo.filetype == "java" then
    require("utils.javafx").compile_and_run()
  elseif vim.bo.filetype == "cpp" or vim.bo.filetype == "c" then
    require("utils.cpp").compile_and_run()
  elseif vim.bo.filetype == "python" then
    require("utils.python").compile_and_run()
  elseif vim.bo.filetype == "rust" then
    require("utils.rust").compile_and_run()
  else
    vim.notify("No run configuration for filetype: " .. vim.bo.filetype, vim.log.levels.WARN)
  end
end, { desc = "Run current file (Java/C++/Python/Rust)" })

map("n", "<leader>rh", function()
  require("utils.cpp_header").prototype_to_header()
end, { desc = "C++ Prototype To Header" })

map("n", "<leader>fp", function()
  require("utils.cpp_project").new_pair_prompt()
end, { desc = "C++ New Header/Source Pair" })

map("n", "<leader>fP", function()
  require("utils.cpp_project").new_private_pair_prompt()
end, { desc = "C++ New Private Header/Source Pair" })

map("n", "<leader>jC", function()
  require("utils.javafx").compile_only()
end, { desc = "Compile Java/JavaFX (check errors)" })

map("n", "<leader>fx", function()
  require("utils.javafx").insert_template()
end, { desc = "Insert JavaFX template" })

map("n", "<leader>tf", ":TSC<cr>", { desc = "Run TypeScript compile" })

local function is_ts_js_filetype()
  local ft = vim.bo.filetype
  return ft == "typescript" or ft == "typescriptreact" or ft == "javascript" or ft == "javascriptreact"
end

local function run_ts_tools_command(command, label)
  return function()
    if not is_ts_js_filetype() then
      vim.notify(label .. " is available only in TS/JS buffers", vim.log.levels.WARN)
      return
    end

    local ok = pcall(vim.cmd, command)
    if not ok then
      vim.notify("Failed to run " .. label, vim.log.levels.ERROR)
    end
  end
end

map(
  "n",
  "<leader>co",
  run_ts_tools_command("TSToolsOrganizeImports", "TSToolsOrganizeImports"),
  { desc = "TS Organize Imports" }
)
map(
  "n",
  "<leader>cM",
  run_ts_tools_command("TSToolsAddMissingImports", "TSToolsAddMissingImports"),
  { desc = "TS Add Missing Imports" }
)
map(
  "n",
  "<leader>cu",
  run_ts_tools_command("TSToolsRemoveUnused", "TSToolsRemoveUnused"),
  { desc = "TS Remove Unused" }
)
map("n", "<leader>cD", run_ts_tools_command("TSToolsFixAll", "TSToolsFixAll"), { desc = "TS Fix All" })
map("n", "<leader>tR", run_ts_tools_command("TSToolsRenameFile", "TSToolsRenameFile"), { desc = "TS Rename File" })
map(
  "n",
  "<leader>tI",
  run_ts_tools_command("TSToolsFileReferences", "TSToolsFileReferences"),
  { desc = "TS File References" }
)
