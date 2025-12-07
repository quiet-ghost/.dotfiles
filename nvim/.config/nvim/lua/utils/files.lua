local M = {}

-- ============================================================================
-- PROJECT TYPE DETECTION
-- ============================================================================

-- Helper function to find project root with specific markers
local function find_root(start_dir, markers)
  local dir = start_dir or vim.fn.getcwd()
  local home = vim.fn.expand("~")

  while dir ~= "/" and dir ~= home do
    for _, marker in ipairs(markers) do
      local marker_path = dir .. "/" .. marker
      if vim.fn.filereadable(marker_path) == 1 or vim.fn.isdirectory(marker_path) == 1 then
        return dir, marker
      end
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end

  return nil, nil
end

-- Detect project type based on root markers
function M.detect_project_type()
  local current_dir = vim.fn.expand("%:p:h")
  if current_dir == "" then
    current_dir = vim.fn.getcwd()
  end

  -- Check for various project types
  local project_types = {
    { type = "maven", markers = { "pom.xml", "mvnw" } },
    { type = "gradle", markers = { "build.gradle", "gradlew", "build.gradle.kts" } },
    { type = "cargo", markers = { "Cargo.toml" } },
    { type = "flutter", markers = { "pubspec.yaml" } },
    { type = "cmake", markers = { "CMakeLists.txt" } },
  }

  for _, proj in ipairs(project_types) do
    local root, marker = find_root(current_dir, proj.markers)
    if root then
      return proj.type, root, marker
    end
  end

  return "generic", vim.fn.getcwd(), nil
end

-- ============================================================================
-- BASE PACKAGE DETECTION FOR JAVA PROJECTS
-- ============================================================================

-- Helper: Detect package from existing source tree structure
local function detect_package_from_source_tree(java_src_dir)
  if vim.fn.isdirectory(java_src_dir) == 0 then
    return nil
  end

  -- Find all Java files in the project
  local java_files = vim.fn.glob(java_src_dir .. "/**/*.java", false, true)

  if #java_files == 0 then
    return nil
  end

  -- Extract the common base path from all files
  local base_parts = nil

  for _, file_path in ipairs(java_files) do
    local relative = file_path:gsub(vim.pesc(java_src_dir .. "/"), "")
    local dir = vim.fn.fnamemodify(relative, ":h")

    if dir ~= "." and dir ~= "" then
      local parts = vim.split(dir, "/", { plain = true })

      if not base_parts then
        base_parts = parts
      else
        -- Find common prefix
        local common = {}
        for i = 1, math.min(#base_parts, #parts) do
          if base_parts[i] == parts[i] then
            table.insert(common, base_parts[i])
          else
            break
          end
        end
        base_parts = common
      end
    end
  end

  if base_parts and #base_parts > 0 then
    return table.concat(base_parts, ".")
  end

  return nil
end

-- Helper: Parse groupId from Maven pom.xml
local function parse_group_id_from_pom(pom_path)
  if vim.fn.filereadable(pom_path) == 0 then
    return nil
  end

  local file = io.open(pom_path, "r")
  if not file then
    vim.notify("Failed to read pom.xml: " .. pom_path, vim.log.levels.WARN)
    return nil
  end

  local content = file:read("*all")
  file:close()

  -- Match <groupId>com.example</groupId>
  -- This will get the first groupId (project's, not parent's)
  local group_id = content:match("<groupId>([^<]+)</groupId>")

  if not group_id or group_id == "" then
    vim.notify("No <groupId> found in pom.xml", vim.log.levels.WARN)
    return nil
  end

  return group_id
end

-- Helper: Parse group from Gradle build file
local function parse_group_from_gradle(gradle_path)
  if vim.fn.filereadable(gradle_path) == 0 then
    return nil
  end

  local file = io.open(gradle_path, "r")
  if not file then
    vim.notify("Failed to read build.gradle: " .. gradle_path, vim.log.levels.WARN)
    return nil
  end

  local content = file:read("*all")
  file:close()

  -- Match patterns like:
  -- group = 'com.example'
  -- group = "com.example"
  -- group 'com.example'
  -- group "com.example"
  local group = content:match('group%s*=%s*["\']([^"\']+)["\']')
    or content:match('group%s+["\']([^"\']+)["\']')
    or content:match('group%s*=%s*"([^"]+)"')

  if not group or group == "" then
    vim.notify("No 'group' found in build.gradle", vim.log.levels.WARN)
    return nil
  end

  return group
end

-- Cache for base packages (indexed by project_root)
local base_package_cache = {}

-- Detect base package for Java projects (with caching)
function M.detect_base_package(project_root, project_type)
  if project_type ~= "maven" and project_type ~= "gradle" then
    return nil
  end

  -- Check cache first
  if base_package_cache[project_root] then
    return base_package_cache[project_root]
  end

  local java_src_dir = project_root .. "/src/main/java"
  local detected_package = nil

  -- Strategy 1: Auto-detect from existing source structure
  detected_package = detect_package_from_source_tree(java_src_dir)
  if detected_package then
    base_package_cache[project_root] = detected_package
    return detected_package
  end

  -- Strategy 2: Parse from build file
  if project_type == "maven" then
    local pom_path = project_root .. "/pom.xml"
    detected_package = parse_group_id_from_pom(pom_path)
    if detected_package then
      base_package_cache[project_root] = detected_package
      return detected_package
    end
  elseif project_type == "gradle" then
    -- Try Groovy DSL first
    local gradle_path = project_root .. "/build.gradle"
    detected_package = parse_group_from_gradle(gradle_path)
    if detected_package then
      base_package_cache[project_root] = detected_package
      return detected_package
    end

    -- Try Kotlin DSL
    gradle_path = project_root .. "/build.gradle.kts"
    detected_package = parse_group_from_gradle(gradle_path)
    if detected_package then
      base_package_cache[project_root] = detected_package
      return detected_package
    end
  end

  -- Strategy 3: No base package found, cache nil to avoid repeated checks
  base_package_cache[project_root] = false -- false means "checked, but not found"
  return nil
end

-- ============================================================================
-- INPUT PARSING
-- ============================================================================

-- Parse user input into structured data
function M.parse_input(input, project_type)
  if not input or input == "" then
    return nil
  end

  local result = {
    original_input = input,
    type = "file",
    package_name = nil,
    class_name = nil,
    file_extension = nil,
    subdirs = {},
    is_directory = false,
    full_path = nil,
  }

  -- Check if creating a directory (trailing /)
  local is_dir = input:match("/$")
  if is_dir then
    result.is_directory = true
    input = input:gsub("/$", "")
    result.type = "directory"
  end

  -- Extract explicit file extension (only if not a directory)
  if not result.is_directory then
    local name_without_ext, ext = input:match("^(.+)(%.%w+)$")
    if ext then
      result.file_extension = ext
      input = name_without_ext
    end
  end

  -- Determine if it's package notation (contains dots but no slashes)
  -- This is primarily for Java: com.example.User
  if input:match("%.") and not input:match("/") and not result.is_directory then
    result.type = "package"
    local parts = vim.split(input, "%.", { plain = true })
    result.class_name = parts[#parts]
    table.remove(parts, #parts)
    result.package_name = table.concat(parts, ".")
    result.subdirs = parts
  -- Path notation (contains slashes)
  elseif input:match("/") then
    if not result.is_directory then
      result.type = "path"
    end
    local parts = vim.split(input, "/", { plain = true })
    -- Filter out empty parts
    local filtered_parts = {}
    for _, part in ipairs(parts) do
      if part ~= "" then
        table.insert(filtered_parts, part)
      end
    end
    parts = filtered_parts

    if result.is_directory then
      -- For directories, all parts together form the directory path
      -- Don't separate into subdirs and class_name
      result.subdirs = {}
      for i = 1, #parts - 1 do
        table.insert(result.subdirs, parts[i])
      end
      result.class_name = parts[#parts] or ""
      -- Generate package name from all parts for directories
      if #parts > 0 then
        result.package_name = table.concat(parts, ".")
      end
    else
      -- For files, last part is the class name
      result.class_name = parts[#parts]
      table.remove(parts, #parts)
      result.subdirs = parts
      -- Generate package name from path for Java
      if #result.subdirs > 0 then
        result.package_name = table.concat(result.subdirs, ".")
      end
    end
  -- Simple name
  else
    if not result.is_directory then
      result.type = "simple"
    end
    result.class_name = input
  end

  return result
end

-- ============================================================================
-- FILE PATH RESOLUTION
-- ============================================================================

-- Get the base directory for file creation based on project type
function M.get_base_directory(project_type, project_root, filetype, parsed_input, original_dir)
  -- For simple file names (no package notation, no path), use captured original directory
  if parsed_input.type == "simple" then
    return original_dir
  end

  -- For package notation or paths, use project-specific base directories
  if project_type == "maven" or project_type == "gradle" then
    if filetype == "java" then
      local base_package = M.detect_base_package(project_root, project_type)
      local java_src = project_root .. "/src/main/java"

      if base_package then
        -- Convert package to path: com.example -> com/example
        local base_path = base_package:gsub("%.", "/")
        return java_src .. "/" .. base_path
      else
        -- No base package, use src/main/java directly
        return java_src
      end
    end
  elseif project_type == "cargo" then
    return project_root .. "/src"
  elseif project_type == "flutter" then
    return project_root .. "/lib"
  elseif project_type == "cmake" then
    return project_root .. "/src"
  end

  -- Default to current working directory for generic projects
  return vim.fn.getcwd()
end

-- Infer file extension based on project type and current file
function M.infer_file_extension(project_type, parsed_input)
  -- If extension was explicitly provided, use it
  if parsed_input.file_extension then
    return parsed_input.file_extension
  end

  -- Try to infer from current buffer
  local current_ext = vim.fn.expand("%:e")
  if current_ext ~= "" then
    return "." .. current_ext
  end

  -- Infer from project type
  if project_type == "maven" or project_type == "gradle" then
    return ".java"
  elseif project_type == "cargo" then
    return ".rs"
  elseif project_type == "flutter" then
    return ".dart"
  elseif project_type == "cmake" then
    -- Check if there are any C++ files in the project
    local has_cpp = vim.fn.glob(vim.fn.getcwd() .. "/**/*.cpp", false, true)
    if #has_cpp > 0 then
      return ".cpp"
    end
    return ".c"
  end

  -- Default to .txt or prompt user
  return ".java" -- Default to Java as a fallback
end

-- Determine the full file path
function M.get_target_path(parsed_input, project_type, project_root, original_dir)
  local ext = M.infer_file_extension(project_type, parsed_input)
  local filetype = ext:gsub("%.", "")

  local base_dir = M.get_base_directory(project_type, project_root, filetype, parsed_input, original_dir)
  local path_parts = {}

  -- Add subdirectories
  if #parsed_input.subdirs > 0 then
    for _, subdir in ipairs(parsed_input.subdirs) do
      table.insert(path_parts, subdir)
    end
  end

  -- Build full path
  local full_path = base_dir
  if #path_parts > 0 then
    full_path = full_path .. "/" .. table.concat(path_parts, "/")
  end

  if parsed_input.is_directory then
    -- For directories, add the final directory name
    if parsed_input.class_name and parsed_input.class_name ~= "" then
      if #path_parts > 0 then
        -- Path like "models/user/" -> base_dir/models/user
        return full_path .. "/" .. parsed_input.class_name, ext, filetype
      else
        -- Simple directory like "utils/" -> base_dir/utils
        return full_path .. "/" .. parsed_input.class_name, ext, filetype
      end
    end
    return full_path, ext, filetype
  else
    return full_path .. "/" .. parsed_input.class_name .. ext, ext, filetype
  end
end

-- ============================================================================
-- PACKAGE/NAMESPACE EXTRACTION
-- ============================================================================

-- Extract package name from file path (for Java)
function M.extract_package_from_path(file_path, project_type, project_root)
  if project_type ~= "maven" and project_type ~= "gradle" then
    -- For non-Maven/Gradle, extract package from subdirectories relative to cwd
    local cwd = vim.fn.getcwd()
    local relative_path = file_path:gsub(cwd .. "/", "")
    local dir = vim.fn.fnamemodify(relative_path, ":h")

    if dir == "." or dir == "" then
      return nil
    end

    return dir:gsub("/", ".")
  end

  -- For Maven/Gradle projects
  local base_package = M.detect_base_package(project_root, project_type)
  local java_src = project_root .. "/src/main/java"

  -- Build java_root with or without base package
  local java_root = java_src
  if base_package then
    local base_path = base_package:gsub("%.", "/")
    java_root = java_src .. "/" .. base_path
  end

  -- Remove java_root from file path
  local relative_path = file_path:gsub(vim.pesc(java_root), "")
  -- Remove leading slash
  relative_path = relative_path:gsub("^/", "")
  local dir = vim.fn.fnamemodify(relative_path, ":h")

  if dir == "." or dir == "" then
    -- File is directly in the base package directory
    return base_package
  end

  -- Combine base package with subdirectory structure
  local subpackage = dir:gsub("/", ".")
  if base_package then
    return base_package .. "." .. subpackage
  else
    return subpackage
  end
end

-- Extract namespace from file path (for C++)
function M.extract_namespace_from_path(file_path)
  local cwd = vim.fn.getcwd()
  local relative_path = file_path:gsub(cwd .. "/", "")
  local dir = vim.fn.fnamemodify(relative_path, ":h")

  if dir == "." or dir == "" or dir == "src" then
    return nil
  end

  -- Remove 'src/' prefix if present
  dir = dir:gsub("^src/", "")

  -- Convert path to namespace (e.g., utils/math -> utils::math)
  return dir:gsub("/", "::")
end

-- ============================================================================
-- CONTENT GENERATORS
-- ============================================================================

-- Generate Java file content
function M.generate_java_content(parsed_input, file_path, project_type, project_root)
  local lines = {}
  local class_name = parsed_input.class_name

  -- Add package declaration
  local package_name = M.extract_package_from_path(file_path, project_type, project_root)
  if package_name then
    table.insert(lines, "package " .. package_name .. ";")
    table.insert(lines, "")
  end

  -- Add class declaration
  table.insert(lines, "public class " .. class_name .. " {")
  table.insert(lines, "    ")
  table.insert(lines, "}")

  return lines, 3, 4 -- Return lines and cursor position (line, col)
end

-- Generate C++ header content
function M.generate_cpp_header_content(parsed_input, file_path)
  local lines = {}
  local class_name = parsed_input.class_name

  -- Generate include guard
  local guard_name = class_name:upper() .. "_H"
  local namespace = M.extract_namespace_from_path(file_path)

  if namespace then
    guard_name = namespace:gsub("::", "_"):upper() .. "_" .. guard_name
  end

  table.insert(lines, "#ifndef " .. guard_name)
  table.insert(lines, "#define " .. guard_name)
  table.insert(lines, "")

  -- Add namespace if present
  if namespace then
    table.insert(lines, "namespace " .. namespace .. " {")
    table.insert(lines, "")
  end

  -- Add class declaration
  table.insert(lines, "class " .. class_name .. " {")
  table.insert(lines, "public:")
  table.insert(lines, "    " .. class_name .. "();")
  table.insert(lines, "    ~" .. class_name .. "();")
  table.insert(lines, "")
  table.insert(lines, "private:")
  table.insert(lines, "    ")
  table.insert(lines, "};")

  -- Close namespace
  if namespace then
    table.insert(lines, "")
    table.insert(lines, "} // namespace " .. namespace)
  end

  table.insert(lines, "")
  table.insert(lines, "#endif // " .. guard_name)

  return lines, 11, 4
end

-- Generate C++ implementation content
function M.generate_cpp_impl_content(parsed_input, file_path)
  local lines = {}
  local class_name = parsed_input.class_name
  local namespace = M.extract_namespace_from_path(file_path)

  -- Include header
  table.insert(lines, '#include "' .. class_name .. '.h"')
  table.insert(lines, "")

  -- Add namespace if present
  if namespace then
    table.insert(lines, "namespace " .. namespace .. " {")
    table.insert(lines, "")
  end

  -- Add constructor
  table.insert(lines, class_name .. "::" .. class_name .. "() {")
  table.insert(lines, "    ")
  table.insert(lines, "}")
  table.insert(lines, "")

  -- Add destructor
  table.insert(lines, class_name .. "::~" .. class_name .. "() {")
  table.insert(lines, "    ")
  table.insert(lines, "}")

  -- Close namespace
  if namespace then
    table.insert(lines, "")
    table.insert(lines, "} // namespace " .. namespace)
  end

  return lines, 6, 4
end

-- Generate C header content
function M.generate_c_header_content(parsed_input, file_path)
  local lines = {}
  local class_name = parsed_input.class_name

  -- Generate include guard
  local guard_name = class_name:upper() .. "_H"

  table.insert(lines, "#ifndef " .. guard_name)
  table.insert(lines, "#define " .. guard_name)
  table.insert(lines, "")
  table.insert(lines, "")
  table.insert(lines, "")
  table.insert(lines, "#endif // " .. guard_name)

  return lines, 4, 0
end

-- Generate C implementation content
function M.generate_c_impl_content(parsed_input, file_path)
  local lines = {}
  local class_name = parsed_input.class_name

  table.insert(lines, '#include "' .. class_name .. '.h"')
  table.insert(lines, "")
  table.insert(lines, "")

  return lines, 3, 0
end

-- Generate Dart content
function M.generate_dart_content(parsed_input, file_path)
  local lines = {}
  local class_name = parsed_input.class_name

  -- Capitalize first letter for class name
  class_name = class_name:sub(1, 1):upper() .. class_name:sub(2)

  table.insert(lines, "class " .. class_name .. " {")
  table.insert(lines, "  ")
  table.insert(lines, "}")

  return lines, 2, 2
end

-- Generate Rust content
function M.generate_rust_content(parsed_input, file_path)
  local lines = {}

  if parsed_input.is_directory then
    -- Create a module file
    table.insert(lines, "// Module: " .. parsed_input.class_name)
    table.insert(lines, "")
  else
    -- Create a regular file with a public function
    table.insert(lines, "pub fn example() {")
    table.insert(lines, "    ")
    table.insert(lines, "}")
  end

  return lines, 2, 4
end

-- Main content generator dispatcher
function M.generate_file_content(parsed_input, file_path, filetype, project_type, project_root)
  if filetype == "java" then
    return M.generate_java_content(parsed_input, file_path, project_type, project_root)
  elseif filetype == "cpp" then
    return M.generate_cpp_impl_content(parsed_input, file_path)
  elseif filetype == "h" or filetype == "hpp" then
    return M.generate_cpp_header_content(parsed_input, file_path)
  elseif filetype == "c" then
    return M.generate_c_impl_content(parsed_input, file_path)
  elseif filetype == "dart" then
    return M.generate_dart_content(parsed_input, file_path)
  elseif filetype == "rs" then
    return M.generate_rust_content(parsed_input, file_path)
  else
    -- Generic empty file
    return { "" }, 1, 0
  end
end

-- ============================================================================
-- FILE CREATION
-- ============================================================================

-- Create file with content
function M.create_file_with_content(file_path, content_lines, cursor_line, cursor_col)
  -- Create directory structure
  local dir = vim.fn.fnamemodify(file_path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end

  -- Check if file already exists
  if vim.fn.filereadable(file_path) == 1 then
    local choice = vim.fn.confirm("File already exists. Overwrite?", "&Yes\n&No", 2)
    if choice ~= 1 then
      vim.notify("File creation cancelled", vim.log.levels.INFO)
      return false
    end
  end

  -- Create and open the file
  vim.cmd("edit " .. vim.fn.fnameescape(file_path))

  -- Set content
  vim.api.nvim_buf_set_lines(0, 0, -1, false, content_lines)

  -- Position cursor
  if cursor_line and cursor_col then
    vim.api.nvim_win_set_cursor(0, { cursor_line, cursor_col })
  end

  -- Start insert mode at cursor position
  vim.cmd("startinsert")

  return true
end

-- ============================================================================
-- TELESCOPE INTEGRATION
-- ============================================================================

-- Create file using centered popup
function M.create_new_file()
  -- CAPTURE ORIGINAL DIRECTORY BEFORE CREATING POPUP
  local original_dir = vim.fn.expand("%:p:h")
  if original_dir == "" or original_dir == "." then
    original_dir = vim.fn.getcwd()
  end

  -- Detect project context
  local project_type, project_root, marker = M.detect_project_type()

  -- Create a centered floating window for input
  local width = 60
  local height = 1
  local buf = vim.api.nvim_create_buf(false, true)

  local ui = vim.api.nvim_list_uis()[1]
  local win_width = ui.width
  local win_height = ui.height

  local col = math.floor((win_width - width) / 2)
  local row = math.floor((win_height - height) / 2)

  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " Create New File ",
    title_pos = "center",
  }

  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Set prompt text
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
  vim.api.nvim_buf_set_option(buf, "modifiable", true)

  -- Start insert mode
  vim.cmd("startinsert")

  -- Set up keymaps for the floating window
  vim.api.nvim_buf_set_keymap(buf, "i", "<CR>", "", {
    callback = function()
      local input = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1]
      vim.api.nvim_win_close(win, true)

      if input and input ~= "" then
        -- Parse input
        local parsed = M.parse_input(input, project_type)
        if not parsed then
          vim.notify("Invalid input format", vim.log.levels.ERROR)
          return
        end

        -- Get target path with captured original directory
        local file_path, ext, filetype = M.get_target_path(parsed, project_type, project_root, original_dir)

        if parsed.is_directory then
          -- Create directory only
          local success = vim.fn.mkdir(file_path, "p")
          if success == 0 or success == 1 then
            vim.notify("Created directory: " .. file_path, vim.log.levels.INFO)
          else
            vim.notify("Failed to create directory: " .. file_path, vim.log.levels.ERROR)
          end
          return
        end

        -- Generate content
        local content_lines, cursor_line, cursor_col =
          M.generate_file_content(parsed, file_path, filetype, project_type, project_root)

        -- Create the file
        local success = M.create_file_with_content(file_path, content_lines, cursor_line, cursor_col)

        if success then
          vim.notify("Created: " .. file_path, vim.log.levels.INFO)

          -- For C++, also create header file if creating .cpp
          if filetype == "cpp" then
            local header_path = file_path:gsub("%.cpp$", ".h")
            local header_lines, h_line, h_col = M.generate_cpp_header_content(parsed, header_path)
            local dir = vim.fn.fnamemodify(header_path, ":h")
            vim.fn.mkdir(dir, "p")

            -- Write header file
            local header_file = io.open(header_path, "w")
            if header_file then
              header_file:write(table.concat(header_lines, "\n"))
              header_file:close()
              vim.notify("Also created: " .. header_path, vim.log.levels.INFO)
            end
          elseif filetype == "c" then
            local header_path = file_path:gsub("%.c$", ".h")
            local header_lines, h_line, h_col = M.generate_c_header_content(parsed, header_path)
            local dir = vim.fn.fnamemodify(header_path, ":h")
            vim.fn.mkdir(dir, "p")

            -- Write header file
            local header_file = io.open(header_path, "w")
            if header_file then
              header_file:write(table.concat(header_lines, "\n"))
              header_file:close()
              vim.notify("Also created: " .. header_path, vim.log.levels.INFO)
            end
          end
        end
      end
    end,
    noremap = true,
    silent = true,
  })

  vim.api.nvim_buf_set_keymap(buf, "i", "<Esc>", "", {
    callback = function()
      vim.api.nvim_win_close(win, true)
    end,
    noremap = true,
    silent = true,
  })

  -- Add a placeholder/hint text
  vim.fn.prompt_setprompt(buf, "File name (e.g., Animal.java): ")
end

-- Fallback simple file creator (old method)
function M.create_new_file_simple()
  local width = 60
  local height = 1
  local buf = vim.api.nvim_create_buf(false, true)

  local ui = vim.api.nvim_list_uis()[1]
  local win_width = ui.width
  local win_height = ui.height

  local col = math.floor((win_width - width) / 2)
  local row = math.floor((win_height - height) / 2)

  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " Create New File ",
    title_pos = "center",
  }

  local win = vim.api.nvim_open_win(buf, true, opts)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
  vim.api.nvim_buf_set_option(buf, "modifiable", true)

  vim.cmd("startinsert")

  vim.api.nvim_buf_set_keymap(buf, "i", "<CR>", "", {
    callback = function()
      local input = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1]
      vim.api.nvim_win_close(win, true)

      if input and input ~= "" then
        local dir = vim.fn.fnamemodify(input, ":h")
        if dir ~= "." then
          vim.fn.mkdir(dir, "p")
        end
        vim.cmd("edit " .. input)
      end
    end,
    noremap = true,
    silent = true,
  })

  vim.api.nvim_buf_set_keymap(buf, "i", "<Esc>", "", {
    callback = function()
      vim.api.nvim_win_close(win, true)
    end,
    noremap = true,
    silent = true,
  })
end

return M
