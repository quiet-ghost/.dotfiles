local M = {}

-- Smart suffix and prefix removal for interface naming
M.strip_suffixes = { "Impl", "Implementation", "Service", "Concrete", "Class" }
M.strip_prefixes = { "Default", "Base", "Abstract", "Concrete" }

-- Generate interface name from class name
function M.suggest_interface_name(class_name)
  local name = class_name

  -- Try to strip common suffixes
  for _, suffix in ipairs(M.strip_suffixes) do
    if name:match(suffix .. "$") then
      name = name:gsub(suffix .. "$", "")
      break
    end
  end

  -- Try to strip common prefixes (only if we haven't already stripped a suffix)
  if name == class_name then
    for _, prefix in ipairs(M.strip_prefixes) do
      if name:match("^" .. prefix) then
        name = name:gsub("^" .. prefix, "")
        break
      end
    end
  end

  -- If we couldn't strip anything meaningful, just prepend 'I' (Interface convention)
  if name == class_name or name == "" then
    name = "I" .. class_name
  end

  return name
end

-- Generate new class name when using "rename" mode
function M.suggest_renamed_class_name(class_name, interface_name)
  -- If the interface name is what we expect, add Impl suffix
  if interface_name == M.suggest_interface_name(class_name) then
    return class_name .. "Impl"
  end
  -- Otherwise, use the original class name with Impl
  return class_name .. "Impl"
end

return M
