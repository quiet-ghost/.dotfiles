local M = {}

local uv = vim.uv or vim.loop

-- Compiler configuration
local config = {
  cpp_standard = "c++20",
  optimization = "-O0",
  debug_symbols = "-g3",
  warnings = "-Wall -Wextra -Wno-unused-parameter",
  default_compiler = "g++",
  build_dir = "build",
  pane_sizes = {
    cmake = 40, -- CMake terminal projects
    gui = 20, -- GUI apps open their own windows
    make = 35, -- Make projects
    single_file = 45, -- Single file compilation
  },
  title_formats = {
    cmake = "cmake: %s",
    gui = "gui: %s",
    make = "make: %s",
    single_file = "cpp: %s",
  },
}

local function ensure_compile_commands_link(root, build_dir)
  local build_compile_commands = root .. "/" .. build_dir .. "/compile_commands.json"
  local root_compile_commands = root .. "/compile_commands.json"

  if vim.fn.filereadable(build_compile_commands) ~= 1 then
    return
  end

  local stat = uv.fs_lstat(root_compile_commands)
  if stat then
    return
  end

  local ok, err = pcall(uv.fs_symlink, build_compile_commands, root_compile_commands)
  if not ok and err then
    vim.notify("Could not create compile_commands.json symlink: " .. tostring(err), vim.log.levels.WARN)
  end
end

local function linker_hint(output)
  if not output:match("undefined reference to") then
    return nil
  end

  local symbol = output:match("undefined reference to `([^']+)'")
  local symbol_text = symbol and ("Missing symbol: " .. symbol) or "Undefined reference linker error."

  return table.concat({
    symbol_text,
    "This is usually a declaration/definition mismatch or a missing source file in the link step.",
    "Check that function calls match signatures and that related .cpp files are included in compilation.",
  }, "\n")
end

local function shell_quote(path)
  return string.format("'%s'", path:gsub("'", "'\\''"))
end

local function file_has_main(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return false
  end

  for _, line in ipairs(lines) do
    if line:match("%f[%w]int%s+main%s*%(") then
      return true
    end
  end

  return false
end

local function find_main_sources(dir)
  local files = {}
  for _, pattern in ipairs({ "*.cpp", "*.cc", "*.cxx" }) do
    local matched = vim.fn.globpath(dir, pattern, false, true)
    for _, file in ipairs(matched) do
      if file_has_main(file) then
        table.insert(files, vim.fn.fnamemodify(file, ":p"))
      end
    end
  end
  return files
end

local function collect_linked_sources(entry_file)
  local dir = vim.fn.fnamemodify(entry_file, ":h")
  local project_root = vim.fn.getcwd()
  local source_set = {}
  local ordered_sources = {}

  local function add_source(path)
    local absolute = vim.fn.fnamemodify(path, ":p")
    if source_set[absolute] then
      return
    end
    source_set[absolute] = true
    table.insert(ordered_sources, absolute)
  end

  local function add_companion_source_from_header(header_name)
    local normalized_header = header_name:gsub("\\", "/")
    local header_stem = normalized_header:gsub("%.[^.]+$", "")
    local relative_include_stem = header_stem:match("^%.%./include/(.+)$")
      or header_stem:match("^include/(.+)$")
      or header_stem:match("^.*/include/(.+)$")

    local stems = {}
    local seen_stems = {}
    local function add_stem(stem)
      if not stem or stem == "" or seen_stems[stem] then
        return
      end
      seen_stems[stem] = true
      table.insert(stems, stem)
    end

    add_stem(relative_include_stem)
    add_stem(header_stem:gsub("^%./", ""))
    add_stem(vim.fn.fnamemodify(normalized_header, ":t:r"))

    local search_dirs = {
      project_root .. "/src",
      dir,
      project_root,
    }

    for _, stem in ipairs(stems) do
      for _, search_dir in ipairs(search_dirs) do
        for _, ext in ipairs({ ".cpp", ".cc", ".cxx" }) do
          local candidate = vim.fn.fnamemodify(search_dir .. "/" .. stem .. ext, ":p")
          if vim.fn.filereadable(candidate) == 1 then
            add_source(candidate)
            return
          end
        end
      end
    end
  end

  add_source(entry_file)

  local ok, lines = pcall(vim.fn.readfile, entry_file)
  if ok then
    for _, line in ipairs(lines) do
      local header = line:match('^%s*#%s*include%s*"([^"]+)"')
      if header then
        add_companion_source_from_header(header)
      end
    end
  end

  return ordered_sources
end

-- Detect available compiler
local function detect_compiler()
  if vim.fn.executable("clang++") == 1 then
    return "clang++"
  elseif vim.fn.executable("g++") == 1 then
    return "g++"
  else
    error("No C++ compiler found (g++ or clang++)")
  end
end

-- Detect build directory in current working directory
local function detect_build_dir(root)
  local cwd = root or vim.fn.getcwd()
  local candidates = {
    "build",
    "cmake-build-debug",
    "cmake-build-release",
    "cmake-build-relwithdebinfo",
  }
  
  for _, dir in ipairs(candidates) do
    local build_path = cwd .. "/" .. dir
    if vim.fn.isdirectory(build_path) == 1 then
      return dir
    end
  end
  
  -- Default to "build" for new projects
  return "build"
end

local function find_project_root()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then
    dir = vim.fn.getcwd()
  end

  while dir and dir ~= "" and dir ~= "/" do
    for _, marker in ipairs({ "CMakeLists.txt", "Makefile", "makefile", "meson.build" }) do
      if vim.fn.filereadable(dir .. "/" .. marker) == 1 then
        return dir
      end
    end

    local pro_files = vim.fn.glob(dir .. "/*.pro", false, true)
    if #pro_files > 0 then
      return dir
    end

    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end

  return vim.fn.getcwd()
end

local function is_gui_cmake_project(root)
  local cmake_path = root .. "/CMakeLists.txt"
  local ok, lines = pcall(vim.fn.readfile, cmake_path)
  if not ok then
    return false
  end

  local content = table.concat(lines, "\n")
  return content:match("Qt6::") ~= nil
    or content:match("qt_add_") ~= nil
    or content:match("find_package%(%s*Qt6") ~= nil
    or content:match("SFML::") ~= nil
    or content:match("gtkmm") ~= nil
    or content:match("wxWidgets") ~= nil
end

-- Detect project type and build system
local function detect_project_type(root)
  local cwd = root or find_project_root()

  -- Check for CMake
  if vim.fn.filereadable(cwd .. "/CMakeLists.txt") == 1 then
    return "cmake"
  end

  -- Check for Makefile
  if vim.fn.filereadable(cwd .. "/Makefile") == 1 or vim.fn.filereadable(cwd .. "/makefile") == 1 then
    return "make"
  end

  -- Check for Meson
  if vim.fn.filereadable(cwd .. "/meson.build") == 1 then
    return "meson"
  end

  -- Check for legacy qmake Qt project
  local pro_files = vim.fn.glob(cwd .. "/*.pro", false, true)
  if #pro_files > 0 then
    return "qmake"
  end

  return "single_file"
end

-- Find executable in CMake build
local function find_cmake_executable(root, build_dir_name)
  local build_dir = root .. "/" .. build_dir_name
  local project_name = vim.fn.fnamemodify(root, ":t")
  
  -- Priority 1: Try project name directly in build root
  local main_exe = build_dir .. "/" .. project_name
  if vim.fn.executable(main_exe) == 1 then
    return main_exe
  end
  
  -- Priority 2: Find in root of build dir ONLY (exclude subdirs like CMakeFiles/, tests/)
  local handle = io.popen("find " .. shell_quote(build_dir) .. " -maxdepth 1 -type f -executable 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    
    if result and result ~= "" then
      for line in result:gmatch("[^\r\n]+") do
        -- Exclude CMake internal files
        if not line:match("CMake") then
          return line
        end
      end
    end
  end
  
  -- Priority 3: Search all executables but filter intelligently
  handle = io.popen("find " .. shell_quote(build_dir) .. " -type f -executable 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    
    if result and result ~= "" then
      local executables = {}
      for line in result:gmatch("[^\r\n]+") do
        -- Filter out CMake internal executables and tests
        if not line:match("CMakeFiles/") and 
           not line:match("CMakeDetermineCompiler") and
           not line:match("/tests/tests") then
          table.insert(executables, line)
        end
      end
      
      if #executables > 0 then
        return executables[1]
      end
    end
  end

  return nil
end

-- Get current file info
local function get_current_file_info()
  local file = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t")
  local basename = vim.fn.expand("%:t:r")
  local dirname = vim.fn.expand("%:p:h")

  return {
    file = file,
    filename = filename,
    basename = basename,
    dirname = dirname,
  }
end

-- Create tmux pane and run command
local function run_in_tmux(command, pane_size, title, cwd)
  cwd = cwd or vim.fn.getcwd()
  local escaped_cwd = cwd:gsub("'", "'\\''")
  
  local tmux_cmd = string.format(
    [[tmux split-window -h -l %d "cd '%s' && echo '--- %s ---' && echo '' && %s; echo ''; echo 'Press Enter to close...'; read"]],
    pane_size,
    escaped_cwd,
    title,
    command
  )

  vim.fn.system(tmux_cmd)
end

-- CMake project runner
local function run_cmake(root)
  local build_dir = detect_build_dir(root)
  local build_path = root .. "/" .. build_dir

  -- Create build directory if it doesn't exist
  vim.fn.mkdir(build_path, "p")

  -- Keep CMake builds in Debug mode for reliable breakpoints.
  local configure_cmd = "cmake -S " .. shell_quote(root) .. " -B " .. shell_quote(build_path) .. " -DCMAKE_BUILD_TYPE=Debug"
  print("Configuring CMake project (Debug)...")
  local result = vim.fn.system(configure_cmd)
  if vim.v.shell_error ~= 0 then
    error("CMake configuration failed: " .. result)
  end

  ensure_compile_commands_link(root, build_dir)

  -- Build
  local build_cmd = "cmake --build " .. shell_quote(build_path)
  print("Building CMake project...")
  local result = vim.fn.system(build_cmd)
  if vim.v.shell_error ~= 0 then
    local hint = linker_hint(result)
    if hint then
      error("CMake build failed:\n" .. hint .. "\n\n" .. result)
    end
    error("CMake build failed: " .. result)
  end

  -- Find and run executable
  local executable = find_cmake_executable(root, build_dir)
  if executable then
    vim.g.cpp_last_executable = executable
    local run_cmd = string.format("'%s'", executable:gsub("'", "'\\''"))
    local project_name = vim.fn.fnamemodify(root, ":t")
    local gui_project = is_gui_cmake_project(root)
    local title_format = gui_project and config.title_formats.gui or config.title_formats.cmake
    local pane_size = gui_project and config.pane_sizes.gui or config.pane_sizes.cmake
    local title = string.format(title_format, project_name)
    vim.notify(string.format("Running CMake project: %s", project_name), vim.log.levels.INFO)
    run_in_tmux(run_cmd, pane_size, title, root)
  else
    error("No executable found in build directory")
  end
end

local function run_qmake(root)
  local pro_files = vim.fn.glob(root .. "/*.pro", false, true)
  if #pro_files == 0 then
    error("No .pro file found for qmake project")
  end

  local build_dir = root .. "/build"
  vim.fn.mkdir(build_dir, "p")

  local qmake = vim.fn.exepath("qmake6")
  if qmake == "" then
    qmake = vim.fn.exepath("qmake")
  end
  if qmake == "" then
    error("qmake6/qmake not found. Install Qt tools or convert this project to CMake.")
  end

  local configure_cmd = "cd " .. shell_quote(build_dir) .. " && " .. shell_quote(qmake) .. " " .. shell_quote(pro_files[1])
  local result = vim.fn.system(configure_cmd)
  if vim.v.shell_error ~= 0 then
    error("qmake configuration failed: " .. result)
  end

  local build_cmd = "cmake --build " .. shell_quote(build_dir)
  result = vim.fn.system(build_cmd)
  if vim.v.shell_error ~= 0 then
    result = vim.fn.system("make -C " .. shell_quote(build_dir))
    if vim.v.shell_error ~= 0 then
      error("qmake build failed: " .. result)
    end
  end

  local executable = find_cmake_executable(root, "build")
  if executable then
    vim.g.cpp_last_executable = executable
    local title = string.format(config.title_formats.gui, vim.fn.fnamemodify(root, ":t"))
    run_in_tmux(shell_quote(executable), config.pane_sizes.gui, title, root)
  else
    error("No executable found in qmake build directory")
  end
end

-- Make project runner
local function run_make(root)
  root = root or vim.fn.getcwd()
  -- Build
  local build_cmd = "make -C " .. shell_quote(root)
  print("Building with Make...")
  local result = vim.fn.system(build_cmd)
  if vim.v.shell_error ~= 0 then
    error("Make build failed: " .. result)
  end

  -- Try to find executable (common naming patterns)
  local executables = { "main", "program", "app", vim.fn.expand("%:t:r") }
  local executable = nil

  for _, exe in ipairs(executables) do
    local candidate = root .. "/" .. exe
    if vim.fn.executable(candidate) == 1 then
      executable = candidate
      break
    end
  end

  if executable then
    vim.g.cpp_last_executable = vim.fn.fnamemodify(executable, ":p")
    local quoted_exe = string.format("'%s'", executable:gsub("'", "'\\''"))
    local project_name = vim.fn.fnamemodify(root, ":t")
    local title = string.format(config.title_formats.make, project_name)
    vim.notify(string.format("Running Make project: %s", project_name), vim.log.levels.INFO)
    run_in_tmux(quoted_exe, config.pane_sizes.make, title, root)
  else
    error("No executable found after make")
  end
end

-- Single file runner
local function run_single_file()
  local file_info = get_current_file_info()
  local compiler = detect_compiler()
  local cwd = vim.fn.getcwd()

  local entry_file = file_info.file
  if not file_has_main(entry_file) then
    local mains = find_main_sources(file_info.dirname)

    if #mains == 0 then
      mains = find_main_sources(cwd .. "/src")
    end

    if #mains == 0 then
      mains = find_main_sources(cwd)
    end

    if #mains == 1 then
      entry_file = mains[1]
      file_info = {
        file = entry_file,
        filename = vim.fn.fnamemodify(entry_file, ":t"),
        basename = vim.fn.fnamemodify(entry_file, ":t:r"),
        dirname = vim.fn.fnamemodify(entry_file, ":h"),
      }
      vim.notify(string.format("Using entry file with main(): %s", file_info.filename), vim.log.levels.INFO)
    end
  end

  local source_files = collect_linked_sources(entry_file)
  
  -- Check if build directory exists in cwd
  local build_dir = detect_build_dir()
  local build_path = cwd .. "/" .. build_dir
  
  -- Create build directory if it doesn't exist
  if vim.fn.isdirectory(build_path) == 0 then
    vim.fn.mkdir(build_path, "p")
    vim.notify("Created build directory: " .. build_dir, vim.log.levels.INFO)
  end
  
  local output = build_path .. "/" .. file_info.basename
  vim.g.cpp_last_executable = output

  local source_args = {}
  for _, source in ipairs(source_files) do
    table.insert(source_args, shell_quote(source))
  end

  local include_args = {}
  local include_dir = cwd .. "/include"
  if vim.fn.isdirectory(include_dir) == 1 then
    table.insert(include_args, "-I" .. shell_quote(include_dir))
  end

  local compile_cmd = string.format(
    "%s -std=%s %s %s %s %s %s -o %s",
    compiler,
    config.cpp_standard,
    config.optimization,
    config.debug_symbols,
    config.warnings,
    table.concat(include_args, " "),
    table.concat(source_args, " "),
    shell_quote(output)
  )
  
  local run_cmd = shell_quote(output)
  local full_cmd = compile_cmd .. " && " .. run_cmd
  
  local title = string.format(config.title_formats.single_file, file_info.filename)
  vim.notify(string.format("Compiling and running C++ file: %s", file_info.filename), vim.log.levels.INFO)
  
  run_in_tmux(full_cmd, config.pane_sizes.single_file, title)
end

-- Main compile and run function
function M.compile_and_run()
  vim.cmd("write")

  if not os.getenv("TMUX") then
    vim.notify("Not in tmux! Run from terminal instead.", vim.log.levels.ERROR)
    return
  end

  local root = find_project_root()
  local project_type = detect_project_type(root)

  print("Detected project type: " .. project_type)

  if project_type == "cmake" then
    run_cmake(root)
  elseif project_type == "make" then
    run_make(root)
  elseif project_type == "qmake" then
    run_qmake(root)
  elseif project_type == "meson" then
    error("Meson projects not yet implemented")
  else
    run_single_file()
  end
end

-- Configuration function
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

return M
