local M = {}

local DEFAULT_VISIBILITY = "public"

local function sanitize_name(input)
  if not input then
    return nil
  end

  local name = input:gsub("^%s+", ""):gsub("%s+$", "")
  if name == "" then
    return nil
  end

  name = name:gsub("\\", "/")
  name = name:gsub("^%./", "")
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

  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local current_win = vim.api.nvim_get_current_win()
  vim.cmd("keepalt edit " .. vim.fn.fnameescape(path))
  vim.cmd("write")
  vim.api.nvim_set_current_win(current_win)
  return true
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

local function normalize_visibility(opts)
  if opts and opts.visibility == "private" then
    return "private"
  end

  return DEFAULT_VISIBILITY
end

local function source_include_for_header(source_path, header_path, split_layout)
  if not split_layout then
    return vim.fn.fnamemodify(header_path, ":t")
  end

  local source_dir = vim.fn.fnamemodify(source_path, ":p:h")
  local header_absolute = vim.fn.fnamemodify(header_path, ":p")
  local source_parts = vim.split(source_dir, "/", { trimempty = true })
  local header_parts = vim.split(header_absolute, "/", { trimempty = true })
  local common = 0

  while source_parts[common + 1] and header_parts[common + 1] and source_parts[common + 1] == header_parts[common + 1] do
    common = common + 1
  end

  local relative_parts = {}
  for _ = common + 1, #source_parts do
    table.insert(relative_parts, "..")
  end

  for i = common + 1, #header_parts do
    table.insert(relative_parts, header_parts[i])
  end

  return table.concat(relative_parts, "/")
end

function M.new_pair(name_input, opts)
  local visibility = normalize_visibility(opts)
  local name = sanitize_name(name_input)
  if not name then
    vim.notify("Provide a C++ file name", vim.log.levels.WARN)
    return
  end

  local cwd = vim.fn.getcwd()
  local source_dir = cwd
  local header_dir = visibility == "public" and (cwd .. "/include") or cwd
  local header_stem = visibility == "public" and name:gsub("^src/", "") or name

  vim.fn.mkdir(header_dir, "p")

  local header_ext = pick_header_ext(header_dir, header_stem)
  local header_name = header_stem .. header_ext
  local source_name = name .. ".cpp"

  local header_path = header_dir .. "/" .. header_name
  local source_path = source_dir .. "/" .. source_name

  vim.fn.mkdir(vim.fn.fnamemodify(source_path, ":h"), "p")

  local created_header = create_header_from_autocmd(header_path)
  local created_source = write_if_missing(source_path, {
    "#include \"" .. source_include_for_header(source_path, header_path, visibility == "public") .. "\"",
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

function M.new_pair_prompt(opts)
  local visibility = normalize_visibility(opts)
  vim.ui.input({ prompt = string.format("New C++ %s pair name: ", visibility) }, function(input)
    if input == nil then
      return
    end
    M.new_pair(input, { visibility = visibility })
  end)
end

function M.new_private_pair(name_input)
  M.new_pair(name_input, { visibility = "private" })
end

function M.new_private_pair_prompt()
  M.new_pair_prompt({ visibility = "private" })
end

return M
