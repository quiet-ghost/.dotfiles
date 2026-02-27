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

function M.new_pair(name_input)
  local name = sanitize_name(name_input)
  if not name then
    vim.notify("Provide a C++ file name", vim.log.levels.WARN)
    return
  end

  local cwd = vim.fn.getcwd()
  local header_name = name .. ".h"
  local source_name = name .. ".cpp"
  local header_path = cwd .. "/" .. header_name
  local source_path = cwd .. "/" .. source_name

  local created_header = create_header_from_autocmd(header_path)
  local created_source = write_if_missing(source_path, {
    "#include \"" .. header_name .. "\"",
    "",
  })

  vim.cmd("keepalt edit " .. vim.fn.fnameescape(source_path))

  local pieces = {}
  if created_header then
    table.insert(pieces, header_name)
  end
  if created_source then
    table.insert(pieces, source_name)
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
