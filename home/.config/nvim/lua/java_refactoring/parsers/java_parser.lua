local M = {}

-- Parse the current Java file and extract class information
function M.parse_class()
  local bufnr = vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(bufnr, "java")
  if not parser then
    vim.notify("Treesitter Java parser not available", vim.log.levels.ERROR)
    return nil
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  local result = {
    package = nil,
    imports = {},
    class_name = nil,
    class_modifiers = {},
    implements = {},
    extends = nil,
    methods = {},
    fields = {},
    class_node = nil,
  }

  -- Query for package declaration
  local package_query = vim.treesitter.query.parse(
    "java",
    [[
    (package_declaration
      (scoped_identifier) @package)
    ]]
  )

  for _, node in package_query:iter_captures(root, bufnr) do
    result.package = vim.treesitter.get_node_text(node, bufnr)
  end

  -- Query for imports
  local import_query = vim.treesitter.query.parse(
    "java",
    [[
    (import_declaration
      (scoped_identifier) @import)
    ]]
  )

  for _, node in import_query:iter_captures(root, bufnr) do
    table.insert(result.imports, vim.treesitter.get_node_text(node, bufnr))
  end

  -- Query for class declaration
  local class_query = vim.treesitter.query.parse(
    "java",
    [[
    (class_declaration
      name: (identifier) @class_name
      interfaces: (super_interfaces (type_list (type_identifier) @interface))?
      superclass: (superclass (type_identifier) @superclass)?
      body: (class_body) @class_body) @class
    ]]
  )

  for id, node in class_query:iter_captures(root, bufnr) do
    local capture = class_query.captures[id]
    if capture == "class_name" then
      result.class_name = vim.treesitter.get_node_text(node, bufnr)
    elseif capture == "interface" then
      table.insert(result.implements, vim.treesitter.get_node_text(node, bufnr))
    elseif capture == "superclass" then
      result.extends = vim.treesitter.get_node_text(node, bufnr)
    elseif capture == "class" then
      result.class_node = node
      -- Get modifiers
      local parent = node:parent()
      if parent and parent:type() == "modifiers" then
        result.class_modifiers = vim.split(vim.treesitter.get_node_text(parent, bufnr), "%s+")
      end
    end
  end

  if not result.class_name then
    vim.notify("No class found in current file", vim.log.levels.ERROR)
    return nil
  end

  -- Parse methods and fields
  result.methods = M.parse_methods(bufnr, root)
  result.fields = M.parse_fields(bufnr, root)

  return result
end

-- Parse all methods from the class
function M.parse_methods(bufnr, root)
  local methods = {}

  local method_query = vim.treesitter.query.parse(
    "java",
    [[
    (method_declaration
      (modifiers)? @modifiers
      type: (_) @return_type
      name: (identifier) @method_name
      parameters: (formal_parameters) @params
      (throws)? @throws
      body: (block)? @body) @method
    ]]
  )

  for id, node in method_query:iter_captures(root, bufnr) do
    local capture = method_query.captures[id]
    if capture == "method" then
      local method_info = {
        node = node,
        modifiers = {},
        return_type = nil,
        name = nil,
        parameters = nil,
        throws = nil,
        javadoc = nil,
        is_public = false,
        is_static = false,
        text = vim.treesitter.get_node_text(node, bufnr),
      }

      -- Get previous sibling for javadoc
      local prev = node:prev_sibling()
      if prev and prev:type() == "block_comment" then
        local comment_text = vim.treesitter.get_node_text(prev, bufnr)
        if comment_text:match("^/%*%*") then
          method_info.javadoc = comment_text
        end
      end

      -- Parse method details
      for child_id, child_node in method_query:iter_captures(node, bufnr) do
        local child_capture = method_query.captures[child_id]
        if child_capture == "modifiers" then
          local mod_text = vim.treesitter.get_node_text(child_node, bufnr)
          method_info.modifiers = vim.split(mod_text, "%s+", { trimempty = true })
          method_info.is_public = vim.tbl_contains(method_info.modifiers, "public")
          method_info.is_static = vim.tbl_contains(method_info.modifiers, "static")
        elseif child_capture == "return_type" then
          method_info.return_type = vim.treesitter.get_node_text(child_node, bufnr)
        elseif child_capture == "method_name" then
          method_info.name = vim.treesitter.get_node_text(child_node, bufnr)
        elseif child_capture == "params" then
          method_info.parameters = vim.treesitter.get_node_text(child_node, bufnr)
        elseif child_capture == "throws" then
          method_info.throws = vim.treesitter.get_node_text(child_node, bufnr)
        end
      end

      table.insert(methods, method_info)
    end
  end

  return methods
end

-- Parse all fields from the class
function M.parse_fields(bufnr, root)
  local fields = {}

  local field_query = vim.treesitter.query.parse(
    "java",
    [[
    (field_declaration
      (modifiers)? @modifiers
      type: (_) @field_type
      declarator: (variable_declarator
        name: (identifier) @field_name
        value: (_)? @field_value)) @field
    ]]
  )

  for id, node in field_query:iter_captures(root, bufnr) do
    local capture = field_query.captures[id]
    if capture == "field" then
      local field_info = {
        node = node,
        modifiers = {},
        type = nil,
        name = nil,
        value = nil,
        is_public = false,
        is_static = false,
        is_final = false,
        javadoc = nil,
        text = vim.treesitter.get_node_text(node, bufnr),
      }

      -- Get previous sibling for javadoc
      local prev = node:prev_sibling()
      if prev and prev:type() == "block_comment" then
        local comment_text = vim.treesitter.get_node_text(prev, bufnr)
        if comment_text:match("^/%*%*") then
          field_info.javadoc = comment_text
        end
      end

      -- Parse field details
      for child_id, child_node in field_query:iter_captures(node, bufnr) do
        local child_capture = field_query.captures[child_id]
        if child_capture == "modifiers" then
          local mod_text = vim.treesitter.get_node_text(child_node, bufnr)
          field_info.modifiers = vim.split(mod_text, "%s+", { trimempty = true })
          field_info.is_public = vim.tbl_contains(field_info.modifiers, "public")
          field_info.is_static = vim.tbl_contains(field_info.modifiers, "static")
          field_info.is_final = vim.tbl_contains(field_info.modifiers, "final")
        elseif child_capture == "field_type" then
          field_info.type = vim.treesitter.get_node_text(child_node, bufnr)
        elseif child_capture == "field_name" then
          field_info.name = vim.treesitter.get_node_text(child_node, bufnr)
        elseif child_capture == "field_value" then
          field_info.value = vim.treesitter.get_node_text(child_node, bufnr)
        end
      end

      table.insert(fields, field_info)
    end
  end

  return fields
end

-- Get eligible members for interface extraction (public methods + static final fields)
function M.get_eligible_members(class_info)
  local members = {}

  -- Add public static final fields (constants)
  for _, field in ipairs(class_info.fields) do
    if field.is_public and field.is_static and field.is_final then
      table.insert(members, {
        type = "field",
        name = field.name,
        signature = field.type .. " " .. field.name .. (field.value and (" = " .. field.value) or ""),
        javadoc = field.javadoc,
        data = field,
      })
    end
  end

  -- Add public methods (excluding static methods for now)
  for _, method in ipairs(class_info.methods) do
    if method.is_public then
      local sig = method.return_type .. " " .. method.name .. method.parameters
      if method.throws then
        sig = sig .. " " .. method.throws
      end
      table.insert(members, {
        type = "method",
        name = method.name,
        signature = sig,
        javadoc = method.javadoc,
        data = method,
      })
    end
  end

  return members
end

return M
