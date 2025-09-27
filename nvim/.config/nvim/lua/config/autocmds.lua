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
      "    ",
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

-- -- Auto-start JDTLS for Java files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    vim.defer_fn(function()
      if #vim.lsp.get_active_clients({ name = "jdtls" }) == 0 then
        vim.cmd("LspStart jdtls")
      end
    end, 100)
  end,
})
