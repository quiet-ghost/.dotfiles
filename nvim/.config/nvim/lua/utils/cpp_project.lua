local M = {}

local function sanitize_name(input)
  if not input then
    return nil
  end

  local name = input:gsub("^%s+", ""):gsub("%s+$", "")
  if name == "" then
    return nil
  end

  name = name:gsub("%.cpp$", ""):gsub("%.hpp$", ""):gsub("%.h$", "")
  return name
end

local function write_if_missing(path, lines)
  if vim.fn.filereadable(path) == 1 then
    return false
  end

  vim.fn.writefile(lines, path)
  return true
end

local function create_header_from_autocmd(path)
  if vim.fn.filereadable(path) == 1 then
    return false
  end

  local current_win = vim.api.nvim_get_current_win()
  vim.cmd("keepalt edit " .. vim.fn.fnameescape(path))
  vim.cmd("write")
  vim.api.nvim_set_current_win(current_win)
  return true
end

local function use_split_layout(cwd)
  local has_cmake = vim.fn.filereadable(cwd .. "/CMakeLists.txt") == 1
  local has_src = vim.fn.isdirectory(cwd .. "/src") == 1
  local has_include = vim.fn.isdirectory(cwd .. "/include") == 1
  return has_cmake or has_src or has_include
end

local function pick_header_ext(header_dir, name)
  local h_path = string.format("%s/%s.h", header_dir, name)
  if vim.fn.filereadable(h_path) == 1 then
    return ".h"
  end

  local hpp_path = string.format("%s/%s.hpp", header_dir, name)
  if vim.fn.filereadable(hpp_path) == 1 then
    return ".hpp"
  end

  return ".h"
end

function M.new_pair(name_input)
  local name = sanitize_name(name_input)
  if not name then
    vim.notify("Provide a C++ file name", vim.log.levels.WARN)
    return
  end

  local cwd = vim.fn.getcwd()
  local split_layout = use_split_layout(cwd)

  local source_dir = split_layout and (cwd .. "/src") or cwd
  local header_dir = split_layout and (cwd .. "/include") or cwd

  if split_layout then
    vim.fn.mkdir(source_dir, "p")
    vim.fn.mkdir(header_dir, "p")
  end

  local header_ext = pick_header_ext(header_dir, name)
  local header_name = name .. header_ext
  local source_name = name .. ".cpp"

  local header_path = header_dir .. "/" .. header_name
  local source_path = source_dir .. "/" .. source_name

  local created_header = create_header_from_autocmd(header_path)
  local created_source = write_if_missing(source_path, {
    "#include \"" .. header_name .. "\"",
    "",
  })

  vim.cmd("keepalt edit " .. vim.fn.fnameescape(source_path))

  local pieces = {}
  if created_header then
    table.insert(pieces, vim.fn.fnamemodify(header_path, ":."))
  end
  if created_source then
    table.insert(pieces, vim.fn.fnamemodify(source_path, ":."))
  end

  if #pieces == 0 then
    vim.notify("C++ pair already exists", vim.log.levels.INFO)
  else
    vim.notify("Created: " .. table.concat(pieces, ", "), vim.log.levels.INFO)
  end
end

function M.new_pair_prompt()
  vim.ui.input({ prompt = "New C++ pair name: " }, function(input)
    if input == nil then
      return
    end
    M.new_pair(input)
  end)
end

return M
