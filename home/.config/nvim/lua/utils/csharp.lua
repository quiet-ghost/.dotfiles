local M = {}
local mux = require("utils.mux")

local function find_project_root(start_dir)
  local dir = start_dir
  local home = vim.fn.expand("~")

  while dir and dir ~= "" and dir ~= "/" and dir ~= home do
    if vim.fn.glob(dir .. "/*.sln") ~= "" or vim.fn.glob(dir .. "/*.csproj") ~= "" then
      return dir
    end

    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end

  return nil
end

function M.compile_and_run()
  local file = vim.fn.expand("%:p")
  if not file:match("%.cs$") then
    vim.notify("Not a C# file!", vim.log.levels.ERROR)
    return
  end

  vim.cmd("write")

  if not mux.ensure() then
    return
  end

  local root = find_project_root(vim.fn.expand("%:p:h"))
  if not root then
    vim.notify("No .sln or .csproj found above this file", vim.log.levels.WARN)
    return
  end

  mux.run_in_split({
    command = "dotnet run",
    title = "dotnet: " .. vim.fn.fnamemodify(root, ":t"),
    cwd = root,
    percent = 30,
    direction = "right",
  })
end

return M
