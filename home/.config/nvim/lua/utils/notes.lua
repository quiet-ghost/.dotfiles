local M = {}

function M.search_java_notes()
  require("telescope.builtin").live_grep({
    search_dirs = { "~/personal/Notes/References/Java/JavaNote.md" },
    prompt_title = "Search JavaNote.md",
  })
end

function M.search_python_notes()
  require("telescope.builtin").live_grep({
    search_dirs = { "~/personal/Notes/References/Python/PythonNote.md" },
    prompt_title = "Search PythonNote.md",
  })
end

function M.search_cpp_notes()
  require("telescope.builtin").live_grep({
    search_dirs = { "~/personal/Notes/References/C++/CppNote.md" },
    prompt_title = "Search CppNote.md",
  })
end

function M.search_sql_notes()
  require("telescope.builtin").live_grep({
    search_dirs = { "~/personal/Notes/References/MySQL/MySQLNote.md" },
    prompt_title = "Search MySQLNote.md",
  })
end

return M