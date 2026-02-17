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
  else
    vim.notify("No run configuration for filetype: " .. vim.bo.filetype, vim.log.levels.WARN)
  end
end, { desc = "Run current file (Java/C++/Python)" })

map("n", "<leader>jc", function()
  require("utils.javafx").compile_only()
end, { desc = "Compile Java/JavaFX (check errors)" })

map("n", "<leader>fx", function()
  require("utils.javafx").insert_template()
end, { desc = "Insert JavaFX template" })

map("n", "<leader>tf", ":TSC<cr>", { desc = "Run TypeScript compile" })
