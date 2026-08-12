local M = {}
local mux = require("utils.mux")

local config = {
  pane_size = 30,
  title_format = "typescript: %s",
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json", "bun.lock", "bun.lockb" },
}

local function find_project_root(start_dir)
  local dir = start_dir
  local home = vim.fn.expand("~")

  while dir and dir ~= "" and dir ~= "/" and dir ~= home do
    for _, marker in ipairs(config.root_markers) do
      if vim.fn.filereadable(dir .. "/" .. marker) == 1 then
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

local function relative_path(path, root)
  local normalized_path = path:gsub("\\", "/")
  local normalized_root = root:gsub("\\", "/")
  local prefix = normalized_root:sub(-1) == "/" and normalized_root or (normalized_root .. "/")

  if normalized_path:sub(1, #prefix) == prefix then
    return normalized_path:sub(#prefix + 1)
  end

  return vim.fn.fnamemodify(path, ":t")
end

local function has_ts_config(root)
  return vim.fn.filereadable(root .. "/tsconfig.json") == 1 or vim.fn.filereadable(root .. "/jsconfig.json") == 1
end

local function resolve_executable(root, name)
  local local_binary = root .. "/node_modules/.bin/" .. name
  if vim.fn.executable(local_binary) == 1 then
    return local_binary
  end

  local global_binary = vim.fn.exepath(name)
  if global_binary ~= "" then
    return global_binary
  end

  return nil
end

local function build_typecheck_command(root, file)
  local tsc = resolve_executable(root, "tsc")
  if not tsc then
    return nil
  end

  if has_ts_config(root) then
    return vim.fn.shellescape(tsc) .. " --noEmit"
  end

  return vim.fn.shellescape(tsc) .. " --noEmit " .. vim.fn.shellescape(file)
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

  local is_typescript_file = filename:match("%.ts$") or filename:match("%.tsx$")
  local is_declaration_file = filename:match("%.d%.ts$") ~= nil
  if not is_typescript_file or is_declaration_file then
    vim.notify("Not a runnable TypeScript file!", vim.log.levels.ERROR)
    return
  end

  vim.cmd("write")

  if not mux.ensure() then
    return
  end

  local bun = vim.fn.exepath("bun")
  if bun == "" then
    vim.notify("bun not found. Install Bun before running TypeScript files with <leader>jf.", vim.log.levels.ERROR)
    return
  end

  local root = find_project_root(dir)
  local target = relative_path(file, root)
  local typecheck_cmd = build_typecheck_command(root, file)
  local run_cmd = vim.fn.shellescape(bun) .. " run " .. vim.fn.shellescape(target)
  local command = typecheck_cmd and (typecheck_cmd .. " && " .. run_cmd) or run_cmd
  local title = string.format(config.title_format, filename)

  run_in_split(command, title, root)

  if typecheck_cmd then
    vim.notify("Type-checking and running TypeScript file: " .. filename, vim.log.levels.INFO)
  else
    vim.notify("Running TypeScript file with Bun (tsc not found): " .. filename, vim.log.levels.INFO)
  end
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

return M
