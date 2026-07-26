local M = {}
local mux = require("utils.mux")

-- Configuration (matching cpp.lua pattern)
local config = {
  pane_size = 30, -- Keep 70% of the layout for the editor.
  python_fallback = "python3",
  venv_dirs = { ".venv", "venv", "virtualenv", "env" },
  title_format = "python: %s",
}

-- Helper: Find file in parent directories (similar to find_pom_xml pattern)
local function find_file_upwards(filename, start_dir)
  local dir = start_dir
  local home = vim.fn.expand("~")

  while dir ~= "/" and dir ~= home do
    local file_path = dir .. "/" .. filename
    if vim.fn.filereadable(file_path) == 1 then
      return dir, file_path
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end

  return nil, nil
end

-- Helper: Detect project type and framework
local function detect_project_type(start_dir)
  local dir = start_dir

  -- Check for Poetry
  local pyproject_dir, pyproject_path = find_file_upwards("pyproject.toml", dir)
  if pyproject_dir and pyproject_path then
    local file = io.open(pyproject_path, "r")
    if file then
      local content = file:read("*all")
      file:close()
      if content:match("%[tool%.poetry%]") then
        return "poetry", pyproject_dir, "regular"
      end
    end
  end

  -- Check for Pipenv
  local pipfile_dir, pipfile_path = find_file_upwards("Pipfile", dir)
  if pipfile_dir and pipfile_path then
    return "pipenv", pipfile_dir, "regular"
  end

  -- Check for Django (look for manage.py)
  local managepy_dir, managepy_path = find_file_upwards("manage.py", dir)
  if managepy_dir and managepy_path then
    return "django", managepy_dir, "django"
  end

  -- Check for Flask (look for app.py or Flask patterns in current file)
  local current_file = vim.fn.expand("%:p")
  local file = io.open(current_file, "r")
  if file then
    local content = file:read("*all")
    file:close()
    if content:match("from flask import") or content:match("import flask") or content:match("Flask%(__name__%)") then
      return "flask", dir, "flask"
    end
  end

  -- Check for virtual environment directories
  for _, venv_dir in ipairs(config.venv_dirs) do
    local venv_path = dir .. "/" .. venv_dir
    if vim.fn.isdirectory(venv_path) == 1 then
      return "venv", dir, "regular"
    end
  end

  -- Check for requirements.txt
  local req_dir, req_path = find_file_upwards("requirements.txt", dir)
  if req_dir and req_path then
    return "requirements", req_dir, "regular"
  end

  -- Single file mode
  return "single", dir, "regular"
end

-- Helper: Find Python interpreter
local function find_python_interpreter(project_type, project_root)
  local python_path = nil

  if project_type == "poetry" then
    -- Get poetry environment path
    local result = vim.fn.system("cd '" .. project_root .. "' && poetry env info --path 2>/dev/null | tr -d '\n'")
    if vim.v.shell_error == 0 and result ~= "" then
      local poetry_python = result .. "/bin/python"
      if vim.fn.executable(poetry_python) == 1 then
        python_path = poetry_python
      end
    end
  elseif project_type == "pipenv" then
    -- Get pipenv environment path
    local result = vim.fn.system("cd '" .. project_root .. "' && pipenv --venv 2>/dev/null | tr -d '\n'")
    if vim.v.shell_error == 0 and result ~= "" then
      local pipenv_python = result .. "/bin/python"
      if vim.fn.executable(pipenv_python) == 1 then
        python_path = pipenv_python
      end
    end
  elseif project_type == "venv" then
    -- Check for venv directories
    for _, venv_dir in ipairs(config.venv_dirs) do
      local venv_python = project_root .. "/" .. venv_dir .. "/bin/python"
      if vim.fn.executable(venv_python) == 1 then
        python_path = venv_python
        break
      end
    end
  end

  -- Fallback to system Python
  if not python_path then
    if vim.fn.executable("python3") == 1 then
      python_path = "python3"
    elseif vim.fn.executable("python") == 1 then
      python_path = "python"
    else
      return nil
    end
  end

  return python_path
end

-- Helper: Check if file is in a Python package
local function is_in_package(file_path)
  local dir = vim.fn.fnamemodify(file_path, ":h")
  
  -- Walk up directory tree looking for __init__.py
  while dir ~= "/" and dir ~= vim.fn.expand("~") do
    if vim.fn.filereadable(dir .. "/__init__.py") == 1 then
      return true
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  
  return false
end

-- Helper: Detect run mode (module vs script)
local function detect_run_mode(file_path, project_type, project_root, framework)
  local filename = vim.fn.expand("%:t")
  local basename = vim.fn.expand("%:t:r")
  
  -- Django always uses manage.py
  if framework == "django" then
    return "script", "manage.py runserver"
  end
  
  -- Flask uses flask run if properly structured
  if framework == "flask" then
    -- Check if we're in a package structure
    if is_in_package(file_path) then
      return "flask", "flask run"
    else
      return "script", filename
    end
  end
  
  -- Check if file is in a package (has __init__.py in parent dirs)
  if is_in_package(file_path) then
    -- Convert file path to module name
    local rel_path = file_path:gsub(vim.pesc(project_root .. "/"), "")
    local module_name = rel_path:gsub("/", "."):gsub("%.py$", "")
    return "module", module_name
  end
  
  -- Default to script mode
  return "script", filename
end

-- Helper: Build execution command
local function build_execution_command(project_type, framework, run_mode, python_path, target, project_root)
  local cmd = ""
  
  if project_type == "poetry" then
    if run_mode == "module" then
      cmd = string.format("cd '%s' && poetry run python -m %s", project_root, target)
    else
      cmd = string.format("cd '%s' && poetry run python %s", project_root, target)
    end
  elseif project_type == "pipenv" then
    if run_mode == "module" then
      cmd = string.format("cd '%s' && pipenv run python -m %s", project_root, target)
    else
      cmd = string.format("cd '%s' && pipenv run python %s", project_root, target)
    end
  elseif project_type == "django" then
    cmd = string.format("cd '%s' && %s %s", project_root, python_path, target)
  elseif project_type == "flask" and run_mode == "flask" then
    cmd = string.format("cd '%s' && %s -m flask run", project_root, python_path)
  else
    -- venv, requirements, or single file
    if run_mode == "module" then
      cmd = string.format("cd '%s' && %s -m %s", project_root, python_path, target)
    else
      cmd = string.format("cd '%s' && %s %s", project_root, python_path, target)
    end
  end
  
  return cmd
end

-- Helper: Run in the active multiplexer.
local function run_in_split(command, title)
  return mux.run_in_split({
    command = command,
    title = title,
    cwd = vim.fn.getcwd(),
    percent = config.pane_size,
    direction = "right",
  })
end

-- Main compile and run function
function M.compile_and_run()
  local file = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t")
  local dir = vim.fn.expand("%:p:h")
  
  -- Validation
  if not filename:match("%.py$") then
    vim.notify("Not a Python file!", vim.log.levels.ERROR)
    return
  end
  
  -- Save file
  vim.cmd("w")
  
  -- Check for a supported multiplexer.
  if not mux.ensure() then
    return
  end
  
  -- Detect project context
  local project_type, project_root, framework = detect_project_type(dir)
  
  vim.notify(string.format("Detected: %s project (%s)", framework, project_type), vim.log.levels.INFO)
  
  -- Find Python interpreter
  local python_path = find_python_interpreter(project_type, project_root)
  if not python_path then
    vim.notify("No Python interpreter found!", vim.log.levels.ERROR)
    return
  end
  
  -- Detect run mode
  local run_mode, target = detect_run_mode(file, project_type, project_root, framework)
  
  -- Build execution command
  local command = build_execution_command(project_type, framework, run_mode, python_path, target, project_root)
  
  -- Run in the active multiplexer.
  local title = string.format(config.title_format, filename)
  run_in_split(command, title)
  
  vim.notify(string.format("Running Python %s: %s", framework, filename), vim.log.levels.INFO)
end

return M