local M = {}

local FALLBACK_JAVA_HOME = "/home/ghost/.local/share/mise/installs/java/liberica-javafx-17.0.16+12"

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

local function is_javafx_maven_project(pom_path)
  local file = io.open(pom_path, "r")
  if not file then
    return false
  end

  local content = file:read("*all")
  file:close()
  return content:match("javafx") ~= nil
end

local function resolve_java_tools()
  local java_home = os.getenv("JAVA_HOME")
  if java_home and java_home ~= "" then
    local javac = java_home .. "/bin/javac"
    local java = java_home .. "/bin/java"
    if vim.fn.executable(javac) == 1 and vim.fn.executable(java) == 1 then
      return javac, java
    end
  end

  if vim.fn.executable(FALLBACK_JAVA_HOME .. "/bin/javac") == 1 and vim.fn.executable(FALLBACK_JAVA_HOME .. "/bin/java") == 1 then
    return FALLBACK_JAVA_HOME .. "/bin/javac", FALLBACK_JAVA_HOME .. "/bin/java"
  end

  local javac = vim.fn.exepath("javac")
  local java = vim.fn.exepath("java")
  return (javac ~= "" and javac or "javac"), (java ~= "" and java or "java")
end

local function detect_main_info(lines, fallback_class)
  local package_name
  local current_class
  local main_class = fallback_class

  for _, line in ipairs(lines) do
    if not package_name then
      package_name = line:match("^%s*package%s+([%w_.]+)%s*;")
    end

    local class_name = line:match("^%s*[%w%s]*class%s+([%w_]+)")
    if class_name then
      current_class = class_name
    end

    if line:match("public%s+static%s+void%s+main%s*%(") or line:match("static%s+public%s+void%s+main%s*%(") then
      if current_class and current_class ~= "" then
        main_class = current_class
      end
      break
    end
  end

  local fqcn = package_name and (package_name .. "." .. main_class) or main_class
  return {
    package_name = package_name,
    main_class = main_class,
    fqcn = fqcn,
  }
end

local function package_to_source_root(file_dir, package_name)
  if not package_name or package_name == "" then
    return file_dir
  end

  local normalized_dir = file_dir:gsub("\\", "/")
  local package_path = package_name:gsub("%.", "/")
  local suffix = "/" .. package_path

  if #normalized_dir >= #suffix and normalized_dir:sub(-#suffix) == suffix then
    local root = normalized_dir:sub(1, #normalized_dir - #suffix)
    return root ~= "" and root or "/"
  end

  return file_dir
end

local function relative_path(path, root)
  local normalized_path = path:gsub("\\", "/")
  local normalized_root = root:gsub("\\", "/")
  local prefix = normalized_root:sub(-1) == "/" and normalized_root or (normalized_root .. "/")

  if normalized_path:sub(1, #prefix) == prefix then
    return normalized_path:sub(#prefix + 1)
  end

  return vim.fn.fnamemodify(path, ":t")
end

local function run_in_tmux(command, pane_size)
  local tmux_cmd = string.format(
    [[tmux split-window -h -l %d%% "%s; echo ''; echo 'Press Enter to close...'; read"]],
    pane_size,
    command
  )
  vim.fn.system(tmux_cmd)
end

local function build_single_file_commands(file, dir, entry, javac_path, java_path)
  local source_root = package_to_source_root(dir, entry.package_name)
  local relative_source = relative_path(file, source_root)
  local compile_cmd = string.format("%s %s", vim.fn.shellescape(javac_path), vim.fn.shellescape(relative_source))
  local run_cmd = string.format("%s -cp . %s", vim.fn.shellescape(java_path), vim.fn.shellescape(entry.fqcn))

  return source_root, compile_cmd, run_cmd
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

  if not os.getenv("TMUX") then
    vim.notify("Not in tmux! Run from terminal instead.", vim.log.levels.ERROR)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local file_content = table.concat(lines, "\n")
  local is_javafx_file = file_content:match("import%s+javafx") or file_content:match("extends%s+Application")
  local entry = detect_main_info(lines, classname)

  local maven_dir, pom_path = find_pom_xml(dir)
  if maven_dir and pom_path then
    if is_javafx_maven_project(pom_path) then
      vim.notify("Maven JavaFX project detected - running with mvn", vim.log.levels.INFO)
      local maven_cmd = string.format(
        "cd %s && echo 'Running Maven JavaFX project...' && mvn clean javafx:run",
        vim.fn.shellescape(maven_dir)
      )
      run_in_tmux(maven_cmd, 20)
      vim.notify("Maven JavaFX running from " .. maven_dir, vim.log.levels.INFO)
      return
    end

    local is_test_source = file:find("/src/test/java/", 1, true) ~= nil
    local phase = is_test_source and "test-compile" or "compile"
    local classpath_scope = is_test_source and "test" or "runtime"
    local maven_cmd = string.format(
      "cd %s && mvn -q -DskipTests %s exec:java -Dexec.mainClass=%s -Dexec.classpathScope=%s",
      vim.fn.shellescape(maven_dir),
      phase,
      vim.fn.shellescape(entry.fqcn),
      classpath_scope
    )

    run_in_tmux(maven_cmd, 30)
    vim.notify("Maven Java running (" .. entry.fqcn .. ")", vim.log.levels.INFO)
    return
  end

  local javac_path, java_path = resolve_java_tools()
  local source_root, compile_cmd, run_cmd = build_single_file_commands(file, dir, entry, javac_path, java_path)
  local command = string.format(
    "cd %s && %s && echo '--- Running %s ---' && %s",
    vim.fn.shellescape(source_root),
    compile_cmd,
    entry.fqcn,
    run_cmd
  )

  run_in_tmux(command, is_javafx_file and 20 or 30)

  if is_javafx_file then
    vim.notify("JavaFX running (class: " .. entry.fqcn .. ")", vim.log.levels.INFO)
  else
    vim.notify("Java running (class: " .. entry.fqcn .. ")", vim.log.levels.INFO)
  end
end

function M.compile_only()
  local file = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t")
  local classname = vim.fn.expand("%:t:r")
  local dir = vim.fn.expand("%:p:h")

  if not filename:match("%.java$") then
    vim.notify("Not a Java file!", vim.log.levels.ERROR)
    return
  end

  vim.cmd("w")

  local maven_dir, pom_path = find_pom_xml(dir)
  if maven_dir and pom_path then
    local is_test_source = file:find("/src/test/java/", 1, true) ~= nil
    local phase = is_test_source and "test-compile" or "compile"
    vim.notify("Maven project detected - compiling with mvn", vim.log.levels.INFO)

    local compile_cmd = string.format("cd %s && mvn -q -DskipTests %s", vim.fn.shellescape(maven_dir), phase)
    vim.cmd("split | terminal " .. compile_cmd)
    vim.cmd("resize 10")
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local entry = detect_main_info(lines, classname)
  local javac_path = select(1, resolve_java_tools())
  local source_root, compile_cmd = build_single_file_commands(file, dir, entry, javac_path, "java")

  local terminal_cmd = string.format("cd %s && %s", vim.fn.shellescape(source_root), compile_cmd)
  vim.cmd("split | terminal " .. terminal_cmd)
  vim.cmd("resize 10")
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
  vim.api.nvim_win_set_cursor(0, { 10, 8 })
end

return M
