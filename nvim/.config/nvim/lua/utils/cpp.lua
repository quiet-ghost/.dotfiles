local M = {}

-- Compiler configuration
local config = {
  cpp_standard = "c++20",
  optimization = "-O2",
  warnings = "-Wall -Wextra",
  default_compiler = "g++",
  build_dir = "build",
  pane_sizes = {
    cmake = 40, -- CMake projects
    make = 35, -- Make projects
    single_file = 45, -- Single file compilation
  },
  title_formats = {
    cmake = "cmake: %s",
    make = "make: %s",
    single_file = "cpp: %s",
  },
}

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
local function detect_build_dir()
  local cwd = vim.fn.getcwd()
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

-- Detect project type and build system
local function detect_project_type()
  local cwd = vim.fn.getcwd()

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

  -- Check for Qt project
  local pro_files = vim.fn.glob(cwd .. "/*.pro", false, true)
  if #pro_files > 0 then
    return "qt"
  end

  return "single_file"
end

-- Find executable in CMake build
local function find_cmake_executable()
  local cwd = vim.fn.getcwd()
  local build_dir = cwd .. "/" .. config.build_dir
  local project_name = vim.fn.fnamemodify(cwd, ":t")
  
  -- Priority 1: Try project name directly in build root
  local main_exe = build_dir .. "/" .. project_name
  if vim.fn.executable(main_exe) == 1 then
    return main_exe
  end
  
  -- Priority 2: Find in root of build dir ONLY (exclude subdirs like CMakeFiles/, tests/)
  local handle = io.popen("find " .. build_dir .. " -maxdepth 1 -type f -executable 2>/dev/null")
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
  handle = io.popen("find " .. build_dir .. " -type f -executable 2>/dev/null")
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
local function run_in_tmux(command, pane_size, title)
  local cwd = vim.fn.getcwd()
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
local function run_cmake()
  local build_dir = detect_build_dir()

  -- Create build directory if it doesn't exist
  vim.fn.system("mkdir -p " .. build_dir)

  -- Configure if not already configured
  if vim.fn.filereadable(build_dir .. "/Makefile") == 0 then
    local configure_cmd = "cmake -S . -B " .. build_dir
    print("Configuring CMake project...")
    local result = vim.fn.system(configure_cmd)
    if vim.v.shell_error ~= 0 then
      error("CMake configuration failed: " .. result)
    end
  end

  -- Build
  local build_cmd = "cmake --build " .. build_dir
  print("Building CMake project...")
  local result = vim.fn.system(build_cmd)
  if vim.v.shell_error ~= 0 then
    error("CMake build failed: " .. result)
  end

  -- Find and run executable
  local executable = find_cmake_executable()
  if executable then
    local run_cmd = string.format("'%s'", executable:gsub("'", "'\\''"))
    local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    local title = string.format(config.title_formats.cmake, project_name)
    vim.notify(string.format("Running CMake project: %s", project_name), vim.log.levels.INFO)
    run_in_tmux(run_cmd, config.pane_sizes.cmake, title)
  else
    error("No executable found in build directory")
  end
end

-- Make project runner
local function run_make()
  -- Build
  local build_cmd = "make"
  print("Building with Make...")
  local result = vim.fn.system(build_cmd)
  if vim.v.shell_error ~= 0 then
    error("Make build failed: " .. result)
  end

  -- Try to find executable (common naming patterns)
  local executables = { "main", "program", "app", vim.fn.expand("%:t:r") }
  local executable = nil

  for _, exe in ipairs(executables) do
    if vim.fn.executable("./" .. exe) == 1 then
      executable = "./" .. exe
      break
    end
  end

  if executable then
    local quoted_exe = string.format("'%s'", executable:gsub("'", "'\\''"))
    local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    local title = string.format(config.title_formats.make, project_name)
    vim.notify(string.format("Running Make project: %s", project_name), vim.log.levels.INFO)
    run_in_tmux(quoted_exe, config.pane_sizes.make, title)
  else
    error("No executable found after make")
  end
end

-- Single file runner
local function run_single_file()
  local file_info = get_current_file_info()
  local compiler = detect_compiler()
  
  -- Check if build directory exists in cwd
  local cwd = vim.fn.getcwd()
  local build_dir = detect_build_dir()
  local build_path = cwd .. "/" .. build_dir
  
  -- Create build directory if it doesn't exist
  if vim.fn.isdirectory(build_path) == 0 then
    vim.fn.mkdir(build_path, "p")
    vim.notify("Created build directory: " .. build_dir, vim.log.levels.INFO)
  end
  
  local output = build_path .. "/" .. file_info.basename

  -- Build compilation command
  local compile_cmd = string.format(
    "%s -std=%s %s %s '%s' -o '%s'",
    compiler,
    config.cpp_standard,
    config.optimization,
    config.warnings,
    file_info.filename,
    output:gsub("'", "'\\''")
  )

  print("Compiling single file...")
  local result = vim.fn.system(compile_cmd)
  if vim.v.shell_error ~= 0 then
    error("Compilation failed: " .. result)
  end

  -- Run the compiled executable
  local run_cmd = string.format("'%s'", output:gsub("'", "'\\''"))
  local title = string.format(config.title_formats.single_file, file_info.filename)
  vim.notify(string.format("Compiling and running C++ file: %s", file_info.filename), vim.log.levels.INFO)
  run_in_tmux(run_cmd, config.pane_sizes.single_file, title)
end

-- Main compile and run function
function M.compile_and_run()
  local project_type = detect_project_type()

  print("Detected project type: " .. project_type)

  if project_type == "cmake" then
    run_cmake()
  elseif project_type == "make" then
    run_make()
  elseif project_type == "qt" then
    error("Qt projects not yet implemented")
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
