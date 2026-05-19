-- Capture initial directory when Neovim starts
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Store the directory where nvim was opened
    vim.g.initial_cwd = vim.fn.getcwd()
  end,
})

local function insert_java_boilerplate()
  local filename = vim.fn.expand("%:t:r")

  -- Only insert if buffer is empty (no content)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local is_empty = #lines == 1 and lines[1] == ""

  if is_empty and filename ~= "" then
    local boilerplate = {
      "public class " .. filename .. " {",
      "    public static void main(String[] args) {",
      "    }",
      "}",
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, boilerplate)
    vim.api.nvim_win_set_cursor(0, { 2, 4 })
  end
end

-- Multiple events to catch both terminal and in-editor file creation
vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
  pattern = "*.java",
  callback = function()
    -- Small delay to ensure buffer is fully initialized
    vim.defer_fn(insert_java_boilerplate, 50)
  end,
})

-- JavaFX template for files ending with FX.java or containing JavaFX
vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = "*FX.java",
  callback = function()
    local filename = vim.fn.expand("%:t:r")
    local lines = {
      "import javafx.application.Application;",
      "import javafx.scene.Scene;",
      "import javafx.stage.Stage;",
      "",
      "public class " .. filename .. " extends Application {",
      "    @Override",
      "    public void start(Stage primaryStage) {",
      "",
      "    }",
      "    ",
      "    public static void main(String[] args) {",
      "        launch(args);",
      "    }",
      "}",
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 11, 8 })
  end,
})

local function make_header_guard()
  local relative_path = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.")
  local extension = vim.fn.expand("%:e"):lower()
  local suffix = extension == "hpp" and "_HPP" or "_H"
  local guard = relative_path:gsub("[^%w]", "_"):upper()

  if not guard:match("_H$") and not guard:match("_HPP$") then
    guard = guard .. suffix
  end

  return guard
end

vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = { "*.h", "*.hpp" },
  callback = function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local is_empty = #lines == 1 and lines[1] == ""
    if not is_empty then
      return
    end

    local user = os.getenv("USER") or "user"
    local created = os.date("%-m/%-d/%y")
    local guard = make_header_guard()

    local template = {
      "//",
      "// Created by " .. user .. " on " .. created .. ".",
      "//",
      "",
      "#ifndef " .. guard,
      "#define " .. guard,
      "",
      "",
      "#endif // " .. guard,
    }

    vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
    vim.api.nvim_win_set_cursor(0, { 8, 0 })
  end,
})

local function make_header_guard()
  local name = vim.fn.expand("%:t") -- filename with extension
  local stem = vim.fn.expand("%:t:r")
  local ext = vim.fn.expand("%:e"):lower()
  local suffix = (ext == "hpp" and "_HPP" or "_H")
  local guard = (stem .. suffix):gsub("[^%w]", "_"):upper()
  return guard
end
vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = { "*.h", "*.hpp" },
  callback = function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local is_empty = #lines == 1 and lines[1] == ""
    if not is_empty then
      return
    end
    local guard = make_header_guard()
    local created = os.date("%-m/%-d/%y")
    local user = os.getenv("USER") or "user"
    local template = {
      "//",
      "// Created by " .. user .. " on " .. created .. ".",
      "//",
      "",
      "#ifndef " .. guard,
      "#define " .. guard,
      "",
      "",
      "#endif // " .. guard,
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
    vim.api.nvim_win_set_cursor(0, { 8, 0 }) -- put cursor in body
  end,
})
