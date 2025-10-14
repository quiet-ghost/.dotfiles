return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "theHamsta/nvim-dap-virtual-text",
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    dapui.setup()

    require("nvim-dap-virtual-text").setup({
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = false,
      show_stop_reason = true,
      commented = false,
      only_first_definition = true,
      all_references = false,
      display_callback = function(variable, buf, stackframe, node, options)
        if options.virt_text_pos == "inline" then
          return " = " .. variable.value:gsub("%s+", " ")
        else
          return variable.name .. " = " .. variable.value:gsub("%s+", " ")
        end
      end,
      virt_text_pos = "eol",
      all_frames = false,
      virt_lines = false,
      virt_text_win_col = nil,
    })

    vim.api.nvim_set_hl(0, "NvimDapVirtualText", { fg = "#c53737", italic = true })
    vim.api.nvim_set_hl(0, "NvimDapVirtualTextChanged", { fg = "#c53737", italic = true, bold = true })

    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end

    dap.listeners.before.event_terminated.dapui_config = function()
      -- Intentionally empty - prevents auto-close
    end
    dap.listeners.before.event_exited.dapui_config = function()
      -- Intentionally empty - prevents auto-close
    end
    dap.listeners.after.event_terminated.dapui_config = function()
      -- Intentionally empty - prevents auto-close
    end
    dap.listeners.after.event_exited.dapui_config = function()
      -- Intentionally empty - prevents auto-close
    end

    -- Refresh virtual text when debugger stops at breakpoint
    -- dap.listeners.after.event_stopped.dap_virtual_text = function()
    --   require("nvim-dap-virtual-text").refresh()
    -- end
  end,
}
