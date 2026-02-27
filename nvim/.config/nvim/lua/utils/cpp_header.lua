local M = {}

local function node_text(node, bufnr)
  if not node then
    return nil
  end

  local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
  if not ok then
    return nil
  end

  return text
end

local function normalize_spaces(text)
  return (text:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function get_function_definition_node()
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then
    return nil
  end

  while node and node:type() ~= "function_definition" do
    node = node:parent()
  end

  return node
end

local function build_prototype(bufnr, fn_node)
  local type_node = fn_node:field("type")[1]
  local declarator_node = fn_node:field("declarator")[1]

  local return_type = normalize_spaces(node_text(type_node, bufnr) or "")
  local declarator = normalize_spaces(node_text(declarator_node, bufnr) or "")

  if return_type == "" or declarator == "" then
    return nil
  end

  return return_type .. " " .. declarator .. ";"
end

local function find_header_path(source_path)
  local dir = vim.fn.fnamemodify(source_path, ":h")
  local base = vim.fn.fnamemodify(source_path, ":t:r")

  local h = dir .. "/" .. base .. ".h"
  local hpp = dir .. "/" .. base .. ".hpp"

  if vim.fn.filereadable(h) == 1 then
    return h
  end

  if vim.fn.filereadable(hpp) == 1 then
    return hpp
  end

  return h
end

local function has_prototype(lines, prototype)
  local target = normalize_spaces(prototype)
  for _, line in ipairs(lines) do
    if normalize_spaces(line) == target then
      return true
    end
  end
  return false
end

local function insert_line_index(lines)
  for i = #lines, 1, -1 do
    if lines[i]:match("^%s*#endif") then
      return i - 1
    end
  end

  return #lines
end

function M.prototype_to_header()
  local bufnr = vim.api.nvim_get_current_buf()
  local source_path = vim.api.nvim_buf_get_name(bufnr)

  if source_path == "" then
    vim.notify("Save this source file first", vim.log.levels.WARN)
    return
  end

  local fn_node = get_function_definition_node()
  if not fn_node then
    vim.notify("Place cursor inside a function definition", vim.log.levels.WARN)
    return
  end

  local prototype = build_prototype(bufnr, fn_node)
  if not prototype then
    vim.notify("Could not build function prototype", vim.log.levels.ERROR)
    return
  end

  local header_path = find_header_path(source_path)
  local source_win = vim.api.nvim_get_current_win()

  vim.cmd("keepalt edit " .. vim.fn.fnameescape(header_path))
  local header_buf = vim.api.nvim_get_current_buf()

  local lines = vim.api.nvim_buf_get_lines(header_buf, 0, -1, false)
  if has_prototype(lines, prototype) then
    vim.notify("Prototype already exists in header", vim.log.levels.INFO)
    vim.api.nvim_set_current_win(source_win)
    return
  end

  local idx = insert_line_index(lines)
  vim.api.nvim_buf_set_lines(header_buf, idx, idx, false, { prototype })
  vim.cmd("write")

  vim.api.nvim_set_current_win(source_win)
  vim.notify("Added prototype to " .. vim.fn.fnamemodify(header_path, ":t"), vim.log.levels.INFO)
end

return M
