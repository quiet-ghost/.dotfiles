local M = {}

-- Cache for detected JDKs
M.jdks = {}
M.current_jdk = nil

-- Helper function to execute command and get output
local function exec_command(cmd)
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    return nil
  end
  local result = handle:read("*a")
  handle:close()
  return result
end

-- Parse Java version from version string
local function parse_java_version(version_output)
  if not version_output then
    return nil
  end

  -- Match patterns like "17.0.12", "21.0.8", "1.8.0_292", "11.0.15"
  local version = version_output:match('"?(%d+%.%d+%.%d+)[_%-]?.*"?')
    or version_output:match('"?(%d+%.%d+%.%d+)"?')
    or version_output:match('"?1%.(%d+)%.%d+[_%-]?.*"?')

  if version and version:match("^1%.") then
    -- Convert old format (1.8.0) to new format (8)
    version = version:match("1%.(%d+)")
  elseif version then
    -- Extract major version
    version = version:match("^(%d+)")
  end

  return version
end

-- Get vendor from version output
local function get_java_vendor(version_output)
  if not version_output then
    return "Unknown"
  end

  if version_output:match("Temurin") or version_output:match("tem") then
    return "Temurin"
  elseif version_output:match("OpenJDK") then
    return "OpenJDK"
  elseif version_output:match("Oracle") then
    return "Oracle"
  elseif version_output:match("GraalVM") then
    return "GraalVM"
  elseif version_output:match("Corretto") then
    return "Corretto"
  elseif version_output:match("Zulu") then
    return "Zulu"
  elseif version_output:match("IBM") or version_output:match("Semeru") then
    return "IBM Semeru"
  else
    return "Unknown"
  end
end

-- Detect JDK from a specific path
local function detect_jdk(path, source)
  local java_bin = path .. "/bin/java"

  -- Check if java binary exists
  if vim.fn.filereadable(java_bin) == 0 then
    return nil
  end

  -- Get version info
  local version_output = exec_command(java_bin .. " -version")
  if not version_output then
    return nil
  end

  local version = parse_java_version(version_output)
  local vendor = get_java_vendor(version_output)

  if not version then
    return nil
  end

  -- Extract path name for SDKMAN JDKs
  local name
  if source == "sdkman" then
    name = vim.fn.fnamemodify(path, ":t")
  else
    name = vim.fn.fnamemodify(path, ":t")
  end

  return {
    name = (tonumber(version) >= 23) and "JavaSE-21" or string.format("JavaSE-%s", version),
    display_name = string.format("%s %s (%s) [%s]", vendor, version, name, source),
    path = path,
    version = version,
    vendor = vendor,
    source = source,
    default = false,
  }
end

-- Detect all SDKMAN JDKs
local function detect_sdkman_jdks()
  local jdks = {}
  local sdkman_dir = os.getenv("SDKMAN_DIR") or os.getenv("HOME") .. "/.sdkman"
  local java_dir = sdkman_dir .. "/candidates/java"

  if vim.fn.isdirectory(java_dir) == 0 then
    return jdks
  end

  -- List all directories in SDKMAN java candidates
  local dirs = vim.fn.glob(java_dir .. "/*", false, true)
  for _, dir in ipairs(dirs) do
    -- Skip 'current' symlink
    if not dir:match("/current$") then
      local jdk = detect_jdk(dir, "sdkman")
      if jdk then
        table.insert(jdks, jdk)
      end
    end
  end

  return jdks
end

-- Detect all system JDKs
local function detect_system_jdks()
  local jdks = {}
  local system_dirs = {
    "/usr/lib/jvm",
    "/usr/local/java",
    "/opt/java",
    "/System/Library/Java/JavaVirtualMachines", -- macOS
    "/Library/Java/JavaVirtualMachines", -- macOS
  }

  for _, base_dir in ipairs(system_dirs) do
    if vim.fn.isdirectory(base_dir) == 1 then
      local dirs = vim.fn.glob(base_dir .. "/*", false, true)
      for _, dir in ipairs(dirs) do
        -- Skip symlinks like 'default' and 'default-runtime'
        if vim.fn.isdirectory(dir) == 1 and not dir:match("/default") then
          local jdk = detect_jdk(dir, "system")
          if jdk then
            table.insert(jdks, jdk)
          end
        end
      end
    end
  end

  return jdks
end

-- Detect JDK from JAVA_HOME
local function detect_java_home_jdk()
  local java_home = os.getenv("JAVA_HOME")
  if java_home and vim.fn.isdirectory(java_home) == 1 then
    local jdk = detect_jdk(java_home, "JAVA_HOME")
    if jdk then
      jdk.default = true -- Mark JAVA_HOME as default
      return jdk
    end
  end
  return nil
end

-- Detect all available JDKs
function M.detect_all_jdks()
  M.jdks = {}

  -- Detect JAVA_HOME first (will be default)
  local java_home_jdk = detect_java_home_jdk()
  if java_home_jdk then
    table.insert(M.jdks, java_home_jdk)
    M.current_jdk = java_home_jdk
  end

  -- Detect SDKMAN JDKs
  local sdkman_jdks = detect_sdkman_jdks()
  for _, jdk in ipairs(sdkman_jdks) do
    -- Avoid duplicates with JAVA_HOME
    local is_duplicate = false
    for _, existing in ipairs(M.jdks) do
      if existing.path == jdk.path then
        is_duplicate = true
        break
      end
    end
    if not is_duplicate then
      table.insert(M.jdks, jdk)
    end
  end

  -- Detect system JDKs
  local system_jdks = detect_system_jdks()
  for _, jdk in ipairs(system_jdks) do
    -- Avoid duplicates and skip Java 23+
    local is_duplicate = false
    for _, existing in ipairs(M.jdks) do
      if existing.path == jdk.path then
        is_duplicate = true
        break
      end
    end
    if not is_duplicate and tonumber(jdk.version or 0) < 23 then
      table.insert(M.jdks, jdk)
    end
  end

  -- Sort by version (descending)
  table.sort(M.jdks, function(a, b)
    return tonumber(a.version or 0) > tonumber(b.version or 0)
  end)

  -- If no JAVA_HOME, set the first JDK as current
  if not M.current_jdk and #M.jdks > 0 then
    M.current_jdk = M.jdks[1]
    M.jdks[1].default = true
  end

  return M.jdks
end

-- Get runtimes configuration for nvim-java
function M.get_runtimes_config()
  if #M.jdks == 0 then
    M.detect_all_jdks()
  end

  local runtimes = {}
  for _, jdk in ipairs(M.jdks) do
    table.insert(runtimes, {
      name = jdk.name,
      path = jdk.path,
      default = jdk.default or false,
    })
  end

  return runtimes
end

-- Switch to a specific JDK
function M.switch_jdk(jdk)
  if not jdk then
    return
  end

  -- Update default flags
  for _, j in ipairs(M.jdks) do
    j.default = false
  end
  jdk.default = true
  M.current_jdk = jdk

  -- Set JAVA_HOME for current Neovim session
  vim.env.JAVA_HOME = jdk.path

  -- Notify user
  vim.notify(string.format("Switched to %s", jdk.display_name), vim.log.levels.INFO)

  -- Restart LSP if it's running
  local clients = vim.lsp.get_active_clients({ name = "jdtls" })
  if #clients > 0 then
    vim.notify("Restarting Java LSP with new runtime...", vim.log.levels.INFO)
    for _, client in ipairs(clients) do
      client.stop()
    end
    vim.defer_fn(function()
      vim.cmd("LspStart jdtls")
    end, 500)
  end
end

-- Telescope picker for JDK selection
function M.pick_jdk()
  local has_telescope, telescope = pcall(require, "telescope")
  if not has_telescope then
    vim.notify("Telescope is required for JDK picker", vim.log.levels.ERROR)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  if #M.jdks == 0 then
    M.detect_all_jdks()
  end

  pickers
    .new({}, {
      prompt_title = "Select Java Runtime",
      finder = finders.new_table({
        results = M.jdks,
        entry_maker = function(jdk)
          local display = jdk.display_name
          if jdk.default then
            display = display .. " [current]"
          end
          return {
            value = jdk,
            display = display,
            ordinal = jdk.display_name,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            M.switch_jdk(selection.value)
          end
        end)
        return true
      end,
    })
    :find()
end

-- Get current JDK info
function M.get_current_jdk()
  if not M.current_jdk and #M.jdks == 0 then
    M.detect_all_jdks()
  end
  return M.current_jdk
end

-- Print detected JDKs (for debugging)
function M.print_jdks()
  if #M.jdks == 0 then
    M.detect_all_jdks()
  end

  if #M.jdks == 0 then
    vim.notify("No JDKs detected", vim.log.levels.WARN)
    return
  end

  print("Detected JDKs:")
  for i, jdk in ipairs(M.jdks) do
    local current = jdk.default and " [current]" or ""
    print(string.format("%d. %s%s", i, jdk.display_name, current))
    print(string.format("   Path: %s", jdk.path))
  end
end

return M
