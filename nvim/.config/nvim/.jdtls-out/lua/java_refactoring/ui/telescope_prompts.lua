local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Prompt for interface name with smart default
function M.input_interface_name(default_name, callback)
  vim.ui.input({
    prompt = "Interface name: ",
    default = default_name,
  }, function(input)
    if input and input ~= "" then
      callback(input)
    else
      vim.notify("Refactoring cancelled", vim.log.levels.INFO)
    end
  end)
end

-- Select package for the new interface
function M.select_package(current_package, all_packages, callback)
  local items = vim.tbl_extend("force", { current_package }, all_packages or {})
  -- Remove duplicates
  local seen = {}
  local unique_items = {}
  for _, item in ipairs(items) do
    if not seen[item] then
      seen[item] = true
      table.insert(unique_items, item)
    end
  end

  pickers
    .new({}, {
      prompt_title = "Select Package",
      finder = finders.new_table({
        results = unique_items,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry,
            ordinal = entry,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            callback(selection.value)
          end
        end)
        return true
      end,
    })
    :find()
end

-- Multi-select members to extract
function M.select_members(members, callback)
  local selected = {}
  for i, member in ipairs(members) do
    selected[i] = member.selectable ~= false -- Pre-select all selectable members
  end

  pickers
    .new({}, {
      prompt_title = "Select Members to Extract (Tab to toggle, Enter to confirm)",
      finder = finders.new_table({
        results = members,
        entry_maker = function(entry)
          local idx = nil
          for i, m in ipairs(members) do
            if m == entry then
              idx = i
              break
            end
          end
          local prefix = selected[idx] and "[x] " or "[ ] "
          if entry.selectable == false then
            prefix = "[-] "
          end
          return {
            value = entry,
            display = prefix .. entry.type .. ": " .. entry.signature,
            ordinal = entry.signature,
            index = idx,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        -- Toggle selection with Tab
        map("i", "<Tab>", function()
          local entry = action_state.get_selected_entry()
          if entry and entry.value.selectable ~= false then
            selected[entry.index] = not selected[entry.index]
            -- Refresh the picker
            local picker = action_state.get_current_picker(prompt_bufnr)
            picker:refresh(finders.new_table({
              results = members,
              entry_maker = function(e)
                local idx = nil
                for i, m in ipairs(members) do
                  if m == e then
                    idx = i
                    break
                  end
                end
                local prefix = selected[idx] and "[x] " or "[ ] "
                if e.selectable == false then
                  prefix = "[-] "
                end
                return {
                  value = e,
                  display = prefix .. e.type .. ": " .. e.signature,
                  ordinal = e.signature,
                  index = idx,
                }
              end,
            }), { reset_prompt = false })
          end
        end)

        -- Confirm selection with Enter
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          -- Get selected members
          local selected_members = {}
          for i, is_selected in pairs(selected) do
            if is_selected then
              table.insert(selected_members, members[i])
            end
          end
          callback(selected_members)
        end)
        return true
      end,
    })
    :find()
end

-- Select JavaDoc handling option
function M.select_javadoc_action(callback)
  local options = {
    { display = "As is - Leave JavaDoc in original class", value = "as_is" },
    { display = "Copy - Copy JavaDoc to interface, keep in class", value = "copy" },
    { display = "Move - Move JavaDoc to interface, remove from class", value = "move" },
  }

  pickers
    .new({}, {
      prompt_title = "JavaDoc Handling",
      finder = finders.new_table({
        results = options,
        entry_maker = function(entry)
          return {
            value = entry.value,
            display = entry.display,
            ordinal = entry.display,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            callback(selection.value)
          end
        end)
        return true
      end,
    })
    :find()
end

-- Select extraction mode
function M.select_extraction_mode(callback)
  local options = {
    {
      display = "Extract interface - Create new interface, keep class name",
      value = "extract",
    },
    {
      display = "Rename original class - Interface takes original name, class renamed",
      value = "rename",
    },
  }

  pickers
    .new({}, {
      prompt_title = "Extract Interface Mode",
      finder = finders.new_table({
        results = options,
        entry_maker = function(entry)
          return {
            value = entry.value,
            display = entry.display,
            ordinal = entry.display,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            callback(selection.value)
          end
        end)
        return true
      end,
    })
    :find()
end

-- Select how to handle existing interfaces
function M.select_interface_extension(existing_interface, callback)
  local options = {
    {
      display = string.format("Extend existing interface (%s extends %s)", "NewInterface", existing_interface),
      value = "extend",
    },
    {
      display = "Implement both interfaces separately",
      value = "both",
    },
  }

  pickers
    .new({}, {
      prompt_title = "Interface Extension",
      finder = finders.new_table({
        results = options,
        entry_maker = function(entry)
          return {
            value = entry.value,
            display = entry.display,
            ordinal = entry.display,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            callback(selection.value)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
