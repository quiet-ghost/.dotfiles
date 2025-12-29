local M = {}

-- Generate interface file content
function M.generate(config)
  local lines = {}

  -- Package declaration
  if config.package then
    table.insert(lines, "package " .. config.package .. ";")
    table.insert(lines, "")
  end

  -- Interface declaration
  local interface_decl = "public interface " .. config.name
  
  -- Handle extends
  if config.extends then
    interface_decl = interface_decl .. " extends " .. config.extends
  end
  
  table.insert(lines, interface_decl .. " {")

  -- Add constants (static final fields)
  if config.fields and #config.fields > 0 then
    for _, field in ipairs(config.fields) do
      if field.javadoc and config.javadoc_action ~= "as_is" then
        -- Add javadoc if copying or moving
        table.insert(lines, "  " .. field.javadoc)
      end
      -- Interface fields are implicitly public static final
      local field_decl = "  " .. field.type .. " " .. field.name
      if field.value then
        field_decl = field_decl .. " = " .. field.value
      end
      field_decl = field_decl .. ";"
      table.insert(lines, field_decl)
    end
    if #config.methods > 0 then
      table.insert(lines, "")
    end
  end

  -- Add method signatures
  if config.methods and #config.methods > 0 then
    for i, method in ipairs(config.methods) do
      if method.javadoc and config.javadoc_action ~= "as_is" then
        -- Add javadoc if copying or moving
        table.insert(lines, "  " .. method.javadoc)
      end
      local method_decl = "  " .. method.return_type .. " " .. method.name .. method.parameters
      if method.throws then
        method_decl = method_decl .. " " .. method.throws
      end
      method_decl = method_decl .. ";"
      table.insert(lines, method_decl)
      
      -- Add blank line between methods (except after last one)
      if i < #config.methods then
        table.insert(lines, "")
      end
    end
  end

  table.insert(lines, "}")

  return table.concat(lines, "\n")
end

return M
