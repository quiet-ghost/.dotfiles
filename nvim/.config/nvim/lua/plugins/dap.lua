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
      enabled = true, -- Enable the plugin
      enabled_commands = true, -- Create commands like :DapVirtualTextEnable
      highlight_changed_variables = true, -- Highlight changed variables
      highlight_new_as_changed = true, -- Highlight new variables as changed
      show_stop_reason = true, -- Show why DAP stopped (e.g., breakpoint)
      commented = false, -- Show virtual text as comments (e.g., // value)
      virt_text_pos = "eol", -- Position of virtual text ("eol" or "inline")
      all_frames = false, -- Show virtual text for all stack frames
      virt_lines = false, -- Use virtual lines instead of virtual text
      virt_text_win_col = nil, -- Set to a number to fix column position
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
    dap.listeners.after.event_stopped.dap_virtual_text = function()
      require("nvim-dap-virtual-text").refresh()
    end
    dap.configurations.java = {
      {
        type = "java",
        request = "launch",
        name = "Launch Current File",
      },
    }
  end,
}
