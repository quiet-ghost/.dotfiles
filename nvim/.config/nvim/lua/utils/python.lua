local M = {}
local mux = require("utils.mux")

local config = {
  pane_size = 30,
  title_format = "python: %s",
  venv_dirs = { ".venv", "venv", "virtualenv", "env" },
  root_markers = {
    "uv.lock",
    "poetry.lock",
    "pdm.lock",
    "Pipfile.lock",
    "Pipfile",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "manage.py",
    "environment.yml",
    ".python-version",
  },
}

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function read_file(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or type(lines) ~= "table" then
    return nil
  end
  return table.concat(lines, "\n")
end

local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

local function dir_exists(path)
  return vim.fn.isdirectory(path) == 1
end

local function find_project_root(start_dir)
  local dir = start_dir
  local home = vim.fn.expand("~")

  while dir and dir ~= "" and dir ~= "/" and dir ~= home do
    for _, marker in ipairs(config.root_markers) do
      local marker_path = dir .. "/" .. marker
      if file_exists(marker_path) or dir_exists(marker_path) then
        return dir
      end
    end

    for _, venv_dir in ipairs(config.venv_dirs) do
      if dir_exists(dir .. "/" .. venv_dir) then
        return dir
      end
    end

    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end

  return start_dir
end

local function find_venv_python(root)
  for _, venv_dir in ipairs(config.venv_dirs) do
    local python = root .. "/" .. venv_dir .. "/bin/python"
    if vim.fn.executable(python) == 1 then
      return python, venv_dir
    end
  end
  return nil, nil
end

local function pyproject_has(content, section)
  return content:find("%[tool%." .. section .. "%]", 1, false) ~= nil
    or content:find("%[tool%." .. section .. "%.", 1, false) ~= nil
end

local function detect_project(start_dir)
  local root = find_project_root(start_dir)
  local pyproject_path = root .. "/pyproject.toml"
  local pyproject = file_exists(pyproject_path) and read_file(pyproject_path) or nil

  if file_exists(root .. "/manage.py") then
    return {
      root = root,
      kind = "django",
      manager = "django",
      framework = "django",
    }
  end

  if file_exists(root .. "/uv.lock") or (pyproject and pyproject_has(pyproject, "uv")) then
    return {
      root = root,
      kind = "uv",
      manager = "uv",
      framework = "regular",
    }
  end

  if pyproject and pyproject_has(pyproject, "poetry") or file_exists(root .. "/poetry.lock") then
    return {
      root = root,
      kind = "poetry",
      manager = "poetry",
      framework = "regular",
    }
  end

  if pyproject and pyproject_has(pyproject, "pdm") or file_exists(root .. "/pdm.lock") then
    return {
      root = root,
      kind = "pdm",
      manager = "pdm",
      framework = "regular",
    }
  end

  if pyproject and pyproject_has(pyproject, "hatch") then
    return {
      root = root,
      kind = "hatch",
      manager = "hatch",
      framework = "regular",
    }
  end

  if file_exists(root .. "/Pipfile") or file_exists(root .. "/Pipfile.lock") then
    return {
      root = root,
      kind = "pipenv",
      manager = "pipenv",
      framework = "regular",
    }
  end

  if file_exists(root .. "/environment.yml") or file_exists(root .. "/environment.yaml") then
    return {
      root = root,
      kind = "conda",
      manager = "conda",
      framework = "regular",
    }
  end

  local current_file = vim.fn.expand("%:p")
  if current_file ~= "" then
    local content = read_file(current_file)
    if content and (content:find("from flask import", 1, true) or content:find("import flask", 1, true) or content:find("Flask(__name__)", 1, true)) then
      return {
        root = root,
        kind = "flask",
        manager = find_venv_python(root) and "venv" or "system",
        framework = "flask",
      }
    end
  end

  if find_venv_python(root) then
    -- Bare pyproject + local venv is usually uv/pip-tools style; prefer uv when available.
    if pyproject and vim.fn.executable("uv") == 1 then
      return {
        root = root,
        kind = "uv",
        manager = "uv",
        framework = "regular",
      }
    end

    return {
      root = root,
      kind = "venv",
      manager = "venv",
      framework = "regular",
    }
  end

  if file_exists(root .. "/requirements.txt") then
    return {
      root = root,
      kind = "requirements",
      manager = "system",
      framework = "regular",
    }
  end

  if pyproject and vim.fn.executable("uv") == 1 then
    return {
      root = root,
      kind = "uv",
      manager = "uv",
      framework = "regular",
    }
  end

  return {
    root = root,
    kind = "single",
    manager = "system",
    framework = "regular",
  }
end

local function system_python()
  if vim.fn.executable("python3") == 1 then
    return vim.fn.exepath("python3")
  end
  if vim.fn.executable("python") == 1 then
    return vim.fn.exepath("python")
  end
  return nil
end

local function resolve_manager_python(project)
  local root = project.root

  if project.manager == "uv" and vim.fn.executable("uv") == 1 then
    local venv_python = find_venv_python(root)
    if venv_python then
      return venv_python
    end

    local result = vim.fn.system({ "uv", "python", "find" })
    if vim.v.shell_error == 0 then
      local path = vim.trim(result)
      if path ~= "" and vim.fn.executable(path) == 1 then
        return path
      end
    end
  end

  if project.manager == "poetry" and vim.fn.executable("poetry") == 1 then
    local result = vim.fn.system({ "poetry", "env", "info", "--path" })
    if vim.v.shell_error == 0 then
      local path = vim.trim(result) .. "/bin/python"
      if vim.fn.executable(path) == 1 then
        return path
      end
    end
  end

  if project.manager == "pipenv" and vim.fn.executable("pipenv") == 1 then
    local result = vim.fn.system({ "pipenv", "--venv" })
    if vim.v.shell_error == 0 then
      local path = vim.trim(result) .. "/bin/python"
      if vim.fn.executable(path) == 1 then
        return path
      end
    end
  end

  if project.manager == "pdm" and vim.fn.executable("pdm") == 1 then
    local result = vim.fn.system({ "pdm", "info", "--python" })
    if vim.v.shell_error == 0 then
      local path = vim.trim(result)
      if path ~= "" and vim.fn.executable(path) == 1 then
        return path
      end
    end
  end

  if project.manager == "hatch" and vim.fn.executable("hatch") == 1 then
    local result = vim.fn.system({ "hatch", "env", "find" })
    if vim.v.shell_error == 0 then
      local env_path = vim.trim(result)
      local path = env_path .. "/bin/python"
      if vim.fn.executable(path) == 1 then
        return path
      end
    end
  end

  if project.manager == "conda" and vim.fn.executable("conda") == 1 then
    local result = vim.fn.system({ "conda", "run", "-n", "base", "which", "python" })
    if vim.v.shell_error == 0 then
      local path = vim.trim(result)
      if path ~= "" and vim.fn.executable(path) == 1 then
        return path
      end
    end
  end

  local venv_python = find_venv_python(root)
  if venv_python then
    return venv_python
  end

  return system_python()
end

function M.resolve_interpreter(start_dir)
  local dir = start_dir or vim.fn.expand("%:p:h")
  if dir == "" then
    dir = vim.fn.getcwd()
  end
  local project = detect_project(dir)
  return resolve_manager_python(project), project
end

function M.detect(start_dir)
  local dir = start_dir or vim.fn.expand("%:p:h")
  if dir == "" then
    dir = vim.fn.getcwd()
  end
  return detect_project(dir)
end

local function is_in_package(file_path, project_root)
  local dir = vim.fn.fnamemodify(file_path, ":h")
  local root = project_root or "/"

  while dir and dir ~= "" and dir ~= "/" and dir ~= root and #dir >= #root do
    if file_exists(dir .. "/__init__.py") then
      return true
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end

  return false
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

local function detect_run_mode(file_path, project)
  local filename = vim.fn.fnamemodify(file_path, ":t")

  if project.framework == "django" then
    return "django", "manage.py runserver"
  end

  if project.framework == "flask" then
    return "flask", "flask"
  end

  if is_in_package(file_path, project.root) then
    local rel = relative_path(file_path, project.root)
    local module_name = rel:gsub("/", "."):gsub("%.py$", "")
    return "module", module_name
  end

  return "script", relative_path(file_path, project.root)
end

local function build_execution_command(project, run_mode, target, python_path)
  local root = shell_quote(project.root)
  local py = shell_quote(python_path)
  local tgt = shell_quote(target)

  if project.manager == "uv" and vim.fn.executable("uv") == 1 then
    if run_mode == "module" then
      return string.format("cd %s && uv run python -m %s", root, target)
    end
    if run_mode == "django" then
      return string.format("cd %s && uv run python %s", root, target)
    end
    if run_mode == "flask" then
      return string.format("cd %s && uv run python -m flask run", root)
    end
    -- Scripts with `if __name__ == "__main__"` entrypoints: `uv run main.py`
    return string.format("cd %s && uv run %s", root, tgt)
  end

  if project.manager == "poetry" and vim.fn.executable("poetry") == 1 then
    if run_mode == "module" then
      return string.format("cd %s && poetry run python -m %s", root, target)
    end
    if run_mode == "flask" then
      return string.format("cd %s && poetry run python -m flask run", root)
    end
    return string.format("cd %s && poetry run python %s", root, tgt)
  end

  if project.manager == "pipenv" and vim.fn.executable("pipenv") == 1 then
    if run_mode == "module" then
      return string.format("cd %s && pipenv run python -m %s", root, target)
    end
    if run_mode == "flask" then
      return string.format("cd %s && pipenv run python -m flask run", root)
    end
    return string.format("cd %s && pipenv run python %s", root, tgt)
  end

  if project.manager == "pdm" and vim.fn.executable("pdm") == 1 then
    if run_mode == "module" then
      return string.format("cd %s && pdm run python -m %s", root, target)
    end
    if run_mode == "flask" then
      return string.format("cd %s && pdm run python -m flask run", root)
    end
    return string.format("cd %s && pdm run python %s", root, tgt)
  end

  if project.manager == "hatch" and vim.fn.executable("hatch") == 1 then
    if run_mode == "module" then
      return string.format("cd %s && hatch run python -m %s", root, target)
    end
    if run_mode == "flask" then
      return string.format("cd %s && hatch run python -m flask run", root)
    end
    return string.format("cd %s && hatch run python %s", root, tgt)
  end

  if run_mode == "module" then
    return string.format("cd %s && %s -m %s", root, py, target)
  end
  if run_mode == "django" then
    return string.format("cd %s && %s %s", root, py, target)
  end
  if run_mode == "flask" then
    return string.format("cd %s && %s -m flask run", root, py)
  end

  return string.format("cd %s && %s %s", root, py, tgt)
end

local function run_in_split(command, title, cwd)
  return mux.run_in_split({
    command = command,
    title = title,
    cwd = cwd,
    percent = config.pane_size,
    direction = "right",
  })
end

function M.compile_and_run()
  local file = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t")
  local dir = vim.fn.expand("%:p:h")

  if not filename:match("%.py$") then
    vim.notify("Not a Python file!", vim.log.levels.ERROR)
    return
  end

  vim.cmd("write")

  if not mux.ensure() then
    return
  end

  local project = detect_project(dir)
  local python_path = resolve_manager_python(project)
  if not python_path then
    vim.notify("No Python interpreter found!", vim.log.levels.ERROR)
    return
  end

  local run_mode, target = detect_run_mode(file, project)
  local command = build_execution_command(project, run_mode, target, python_path)
  local title = string.format(config.title_format, filename)

  run_in_split(command, title, project.root)

  vim.notify(
    string.format("Running via %s (%s): %s", project.manager, project.kind, filename),
    vim.log.levels.INFO
  )
end

return M
