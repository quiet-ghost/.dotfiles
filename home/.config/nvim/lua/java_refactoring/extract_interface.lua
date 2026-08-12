local M = {}

local parser = require("java_refactoring.parsers.java_parser")
local naming = require("java_refactoring.utils.naming")
local prompts = require("java_refactoring.ui.telescope_prompts")
local generator = require("java_refactoring.generators.interface_generator")

-- Main extract interface function
function M.extract()
  -- Parse current class
  local class_info = parser.parse_class()
  if not class_info then
    return
  end

  -- Get eligible members
  local members = parser.get_eligible_members(class_info)
  if #members == 0 then
    vim.notify("No public methods or constants found to extract", vim.log.levels.WARN)
    return
  end

  -- Suggest interface name
  local suggested_name = naming.suggest_interface_name(class_info.class_name)

  -- Start interactive workflow
  prompts.input_interface_name(suggested_name, function(interface_name)
    prompts.select_package(class_info.package, {}, function(package_name)
      prompts.select_members(members, function(selected_members)
        if #selected_members == 0 then
          vim.notify("No members selected", vim.log.levels.INFO)
          return
        end

        prompts.select_javadoc_action(function(javadoc_action)
          -- Generate interface
          M.generate_interface({
            class_info = class_info,
            interface_name = interface_name,
            package = package_name,
            members = selected_members,
            javadoc_action = javadoc_action,
          })
        end)
      end)
    end)
  end)
end

-- Generate and write interface file
function M.generate_interface(config)
  local methods = {}
  local fields = {}

  -- Separate methods and fields from selected members
  for _, member in ipairs(config.members) do
    if member.type == "method" then
      table.insert(methods, member.data)
    elseif member.type == "field" then
      table.insert(fields, member.data)
    end
  end

  -- Generate interface content
  local interface_content = generator.generate({
    name = config.interface_name,
    package = config.package,
    methods = methods,
    fields = fields,
    javadoc_action = config.javadoc_action,
  })

  -- Determine file path
  local source_file = vim.api.nvim_buf_get_name(0)
  local source_dir = vim.fn.fnamemodify(source_file, ":h")
  local interface_file = source_dir .. "/" .. config.interface_name .. ".java"

  -- Check if file exists
  if vim.fn.filereadable(interface_file) == 1 then
    vim.ui.select({ "Overwrite", "Cancel" }, {
      prompt = "Interface file already exists. Overwrite?",
    }, function(choice)
      if choice == "Overwrite" then
        M.write_interface_file(interface_file, interface_content, config)
      end
    end)
  else
    M.write_interface_file(interface_file, interface_content, config)
  end
end

-- Write interface file and update class
function M.write_interface_file(file_path, content, config)
  -- Write interface file
  local lines = vim.split(content, "\n")
  vim.fn.writefile(lines, file_path)

  -- Update original class to implement interface
  M.update_class_declaration(config.interface_name, config.members, config.javadoc_action)

  -- Open interface file
  vim.cmd("edit " .. file_path)
  
  vim.notify("✓ Created " .. config.interface_name .. " interface", vim.log.levels.INFO)
end

-- Update class to implement the interface
function M.update_class_declaration(interface_name, selected_members, javadoc_action)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Find class declaration line and add "implements Interface"
  for i, line in ipairs(lines) do
    if line:match("^public%s+class%s+%w+") then
      -- Check if already implements something
      if line:match("implements") then
        -- Add to existing implements list
        lines[i] = line:gsub("implements%s+([%w,]+)", "implements %1, " .. interface_name)
      elseif line:match("{") then
        -- Add implements before {
        lines[i] = line:gsub("{", "implements " .. interface_name .. " {")
      else
        lines[i] = line .. " implements " .. interface_name
      end
      break
    end
  end

  -- Add @Override annotations to methods
  for _, member in ipairs(selected_members) do
    if member.type == "method" then
      for i, line in ipairs(lines) do
        -- Find the method declaration
        if line:match(member.name .. "%s*%(") then
          -- Check if @Override already exists
          if i > 1 and not lines[i - 1]:match("@Override") then
            -- Get indentation
            local indent = line:match("^(%s*)")
            table.insert(lines, i, indent .. "@Override")
          end
          break
        end
      end
    end
  end

  -- Update buffer
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  
  -- Format the file
  vim.lsp.buf.format({ async = false })
end

return M
