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

local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local content = file:read("*all")
  file:close()
  return content
end

local function is_javafx_maven_project(content)
  if not content then
    return false
  end

  return content:match("javafx") ~= nil
end

local function is_jakarta_war_project(content)
  if not content or not content:match("<packaging>%s*war%s*</packaging>") then
    return false
  end

  return content:find("jakarta.servlet", 1, true) ~= nil
    or content:find("jakarta.ws.rs", 1, true) ~= nil
    or content:find("jakarta.platform", 1, true) ~= nil
    or content:find("javax.servlet", 1, true) ~= nil
    or content:find("javax.ws.rs", 1, true) ~= nil
end

local function is_tomcat_home(path)
  if not path or path == "" then
    return false
  end

  local stat = vim.uv or vim.loop
  return stat.fs_stat(path .. "/bin/catalina.sh") ~= nil
    and stat.fs_stat(path .. "/conf/server.xml") ~= nil
    and stat.fs_stat(path .. "/lib") ~= nil
end

local function resolve_tomcat_home()
  local home = os.getenv("HOME") or vim.fn.expand("~")
  local candidates = {}
  local env_catalina_home = os.getenv("CATALINA_HOME")
  local env_tomcat_home = os.getenv("TOMCAT_HOME")

  if env_catalina_home and env_catalina_home ~= "" then
    table.insert(candidates, env_catalina_home)
  end

  if env_tomcat_home and env_tomcat_home ~= "" then
    table.insert(candidates, env_tomcat_home)
  end

  table.insert(candidates, "/home/ghost/app/tomcat")
  table.insert(candidates, home .. "/app/tomcat")
  table.insert(candidates, home .. "/apps/tomcat")

  for _, candidate in ipairs(candidates) do
    local expanded = vim.fn.expand(candidate)
    if is_tomcat_home(expanded) then
      return expanded
    end
  end

  return nil, candidates
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
  local main_class = fallback_class
  local application_class
  local public_class

  for _, line in ipairs(lines) do
    if not package_name then
      package_name = line:match("^%s*package%s+([%w_.]+)%s*;")
    end

    local top_level_class = line:match("^%s*public%s+class%s+([%w_]+)")
    if top_level_class then
      if not public_class then
        public_class = top_level_class
      end

      if line:match("extends%s+Application") then
        application_class = top_level_class
      end
    end

    if line:match("public%s+static%s+void%s+main%s*%(") or line:match("static%s+public%s+void%s+main%s*%(") then
      if public_class and public_class ~= "" then
        main_class = public_class
      end
      break
    end
  end

  if application_class and application_class ~= "" then
    main_class = application_class
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

local function run_jakarta_tomcat_in_tmux(maven_dir, tomcat_home)
  local base_dir = maven_dir .. "/target/nvim-tomcat"
  local ready_file = base_dir .. "/.ready"
  local failed_file = base_dir .. "/.failed"
  local context_file = base_dir .. "/.context"
  local project_name = vim.fn.fnamemodify(maven_dir, ":t")
  local window_name = "jakarta-" .. project_name
  local maven_command = vim.fn.executable(maven_dir .. "/mvnw") == 1 and "./mvnw" or "mvn"

  local compile_steps = table.concat({
    "rm -f " .. vim.fn.shellescape(ready_file) .. " " .. vim.fn.shellescape(failed_file) .. " " .. vim.fn.shellescape(context_file),
    "rm -rf " .. vim.fn.shellescape(base_dir),
    "mkdir -p "
      .. vim.fn.shellescape(base_dir .. "/conf")
      .. " "
      .. vim.fn.shellescape(base_dir .. "/logs")
      .. " "
      .. vim.fn.shellescape(base_dir .. "/temp")
      .. " "
      .. vim.fn.shellescape(base_dir .. "/webapps")
      .. " "
      .. vim.fn.shellescape(base_dir .. "/work"),
    "cp -R " .. vim.fn.shellescape(tomcat_home .. "/conf/.") .. " " .. vim.fn.shellescape(base_dir .. "/conf"),
    maven_command .. " -q -DskipTests package",
    "war=$(ls -1 target/*.war 2>/dev/null | head -n 1 || true)",
    "if [ -z \"$war\" ]; then echo 'No WAR file found in target/'; exit 1; fi",
    "cp \"$war\" " .. vim.fn.shellescape(base_dir .. "/webapps"),
    "context=$(basename \"$war\" .war)",
    "printf '%s' \"$context\" > " .. vim.fn.shellescape(context_file),
    "touch " .. vim.fn.shellescape(ready_file),
    "echo 'Built WAR:' \"$war\"",
    "echo 'Open: http://localhost:8080/'\"$context\"'/'",
  }, " && ")

  local compile_cmd = "("
    .. compile_steps
    .. "); status=$?; if [ $status -ne 0 ]; then touch "
    .. vim.fn.shellescape(failed_file)
    .. "; echo 'Build failed; Tomcat was not started.'; fi; echo ''; echo 'Build pane remains open.'; exec \"$SHELL\""

  local server_cmd = table.concat({
    "while [ ! -f "
      .. vim.fn.shellescape(ready_file)
      .. " ] && [ ! -f "
      .. vim.fn.shellescape(failed_file)
      .. " ]; do sleep 0.5; done",
    "if [ -f "
      .. vim.fn.shellescape(failed_file)
      .. " ]; then echo 'Build failed; Tomcat not started.'; echo ''; echo 'Press Enter to close server pane...'; read; exit 1; fi",
    "context=$(cat " .. vim.fn.shellescape(context_file) .. ")",
    "echo 'Starting Tomcat for context:' \"$context\"",
    "echo 'URL: http://localhost:8080/'\"$context\"'/'",
    "CATALINA_HOME="
      .. vim.fn.shellescape(tomcat_home)
      .. " CATALINA_BASE="
      .. vim.fn.shellescape(base_dir)
      .. " "
      .. vim.fn.shellescape(tomcat_home .. "/bin/catalina.sh")
      .. " run",
    "echo ''",
    "echo 'Press Enter to close server pane...'",
    "read",
  }, "; ")

  local current_pane = vim.fn.system({ "tmux", "display-message", "-p", "#{pane_id}" }):gsub("%s+", "")
  local compile_pane = vim.fn.system({
    "tmux",
    "split-window",
    "-h",
    "-p",
    "30",
    "-P",
    "-F",
    "#{pane_id}",
    "-c",
    maven_dir,
    compile_cmd,
  })
  compile_pane = compile_pane:gsub("%s+", "")
  if compile_pane == "" then
    vim.notify("Failed to create tmux pane for Jakarta runner", vim.log.levels.ERROR)
    return
  end

  vim.fn.system({ "tmux", "split-window", "-v", "-p", "50", "-t", compile_pane, "-c", maven_dir, server_cmd })
  if current_pane ~= "" then
    vim.fn.system({ "tmux", "select-pane", "-t", current_pane })
  end
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
    local pom_content = read_file(pom_path)

    if is_javafx_maven_project(pom_content) then
      vim.notify("Maven JavaFX project detected - running with mvn", vim.log.levels.INFO)
      local maven_cmd = string.format(
        "cd %s && echo 'Running Maven JavaFX project (%s)...' && mvn clean javafx:run -Djavafx.mainClass=%s",
        vim.fn.shellescape(maven_dir),
        entry.fqcn,
        vim.fn.shellescape(entry.fqcn)
      )
      run_in_tmux(maven_cmd, 20)
      vim.notify("Maven JavaFX running (" .. entry.fqcn .. ")", vim.log.levels.INFO)
      return
    end

    if is_jakarta_war_project(pom_content) then
      local tomcat_home, tomcat_candidates = resolve_tomcat_home()
      if not tomcat_home then
        local checked = {}
        for _, candidate in ipairs(tomcat_candidates or {}) do
          if candidate and candidate ~= "" then
            table.insert(checked, vim.fn.expand(candidate))
          end
        end
        vim.notify("Tomcat home not found. Checked: " .. table.concat(checked, ", "), vim.log.levels.ERROR)
        return
      end

      vim.notify("Jakarta EE WAR project detected - building and running Tomcat", vim.log.levels.INFO)
      run_jakarta_tomcat_in_tmux(maven_dir, tomcat_home)
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
    local pom_content = read_file(pom_path)
    if not is_test_source and is_jakarta_war_project(pom_content) then
      phase = "package"
    end

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
