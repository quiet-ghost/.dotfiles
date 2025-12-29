local M = {}

-- Helper function to find pom.xml in current or parent directories
local function find_pom_xml(start_dir)
  local dir = start_dir
  local home = vim.fn.expand("~")

  while dir ~= "/" and dir ~= home do
    local pom_path = dir .. "/pom.xml"
    if vim.fn.filereadable(pom_path) == 1 then
      return dir, pom_path
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end

  return nil, nil
end

-- Helper function to check if pom.xml contains JavaFX dependencies
local function is_javafx_maven_project(pom_path)
  local file = io.open(pom_path, "r")
  if not file then
    return false
  end

  local content = file:read("*all")
  file:close()

  -- Check for JavaFX dependencies or plugins
  return content:match("javafx") ~= nil
end

function M.compile_and_run()
  local file = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t")
  local classname = vim.fn.expand("%:t:r")
  local dir = vim.fn.expand("%:p:h")

  if not filename:match("%.java$") then
    vim.notify("Not a Java file!", vim.log.levels.ERROR)
    return
  end

  vim.cmd("w")

  -- Check if we're in tmux
  local in_tmux = os.getenv("TMUX") ~= nil

  if not in_tmux then
    vim.notify("Not in tmux! Run from terminal instead.", vim.log.levels.ERROR)
    return
  end

  -- Check for Maven project
  local maven_dir, pom_path = find_pom_xml(dir)

  if maven_dir and pom_path and is_javafx_maven_project(pom_path) then
    -- Maven JavaFX project - use mvn javafx:run
    vim.notify("Maven JavaFX project detected - running with mvn", vim.log.levels.INFO)

    local tmux_cmd = string.format(
      [[tmux split-window -h -l 20%% "cd '%s' && echo 'Running Maven JavaFX project...' && mvn clean javafx:run; echo && echo 'Press Enter to close...'; read"]],
      maven_dir
    )
    vim.fn.system(tmux_cmd)
    vim.notify("Maven JavaFX running from " .. maven_dir, vim.log.levels.INFO)
  else
    -- Single file JavaFX or regular Java - use existing logic
    local file_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    local is_javafx = file_content:match("import javafx") or file_content:match("extends Application")

    -- Find the class that contains the main method
    local main_class = classname -- Default to filename without extension
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- Look for the class containing public static void main
    local main_pattern = "public%s+static%s+void%s+main"

    -- Find which class contains the main method
    local in_class = nil
    for i = 1, #lines do
      local line = lines[i]

      -- Match any class declaration (public or not)
      local class_match = line:match("^%s*public%s+class%s+([%w_]+)") or line:match("^%s*class%s+(Main)%s")
      if class_match then
        in_class = class_match
      end

      -- If we find main method, use the current class
      if line:match(main_pattern) and in_class then
        main_class = in_class
        break
      end
    end

    local java_home = os.getenv("JAVA_HOME") or "/home/ghost/.local/share/mise/installs/java/liberica-javafx-17.0.16+12"
    local javac_path = java_home .. "/bin/javac"
    local java_path = java_home .. "/bin/java"

    if is_javafx then
      -- Single file JavaFX program - run in background pane
      local tmux_cmd = string.format(
        [[tmux split-window -h -l 20%% "cd '%s' && %s %s && %s %s; echo 'Press Enter to close...'; read"]],
        dir,
        javac_path,
        filename,
        java_path,
        main_class
      )
      vim.fn.system(tmux_cmd)
      vim.notify("JavaFX running (single file, class: " .. main_class .. ")", vim.log.levels.INFO)
    else
      -- Regular Java program - run in interactive pane
      local tmux_cmd = string.format(
        [[tmux split-window -h -l 30%% "cd '%s' && %s %s && echo '--- Running %s ---' && %s %s; echo && echo 'Press Enter to close...'; read"]],
        dir,
        javac_path,
        filename,
        main_class,
        java_path,
        main_class
      )
      vim.fn.system(tmux_cmd)
      vim.notify("Java running (class: " .. main_class .. ")", vim.log.levels.INFO)
    end
  end
end

function M.compile_only()
  local file = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t")
  local dir = vim.fn.expand("%:p:h")

  if not filename:match("%.java$") then
    vim.notify("Not a Java file!", vim.log.levels.ERROR)
    return
  end

  vim.cmd("w")

  -- Check for Maven project
  local maven_dir, pom_path = find_pom_xml(dir)

  if maven_dir and pom_path then
    -- Maven project - use mvn compile
    vim.notify("Maven project detected - compiling with mvn", vim.log.levels.INFO)

    local compile_cmd = string.format("cd %s && mvn compile", vim.fn.shellescape(maven_dir))

    vim.cmd("split | terminal " .. compile_cmd)
    vim.cmd("resize 10")
  else
    -- Single file - use javac directly
    local java_home = os.getenv("JAVA_HOME") or "/home/ghost/.local/share/mise/installs/java/liberica-javafx-17.0.16+12"
    local compile_cmd =
      string.format("cd %s && %s/bin/javac %s", vim.fn.shellescape(dir), java_home, vim.fn.shellescape(filename))

    vim.cmd("split | terminal " .. compile_cmd)
    vim.cmd("resize 10")
  end
end

function M.insert_template()
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
    "     Scene scene = new Scene();",
    "     primaryStage.setTitle();",
    "     primaryStage.setScene(scene);",
    "     primaryStage.show();",
    "    }",
    "    ",
    "    public static void main(String[] args) {",
    "        launch(args);",
    "    }",
    "}",
  }
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  -- Position cursor inside start method
  vim.api.nvim_win_set_cursor(0, { 10, 8 })
end

return M
