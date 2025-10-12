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
      highlight_new_as_changed = true,
      show_stop_reason = true,
      commented = true,
      virt_text_pos = "eol",
      all_frames = false,
      virt_lines = false,
      virt_text_win_col = nil,
    })

    -- Custom highlighting for virtual text to make it more visible
    vim.api.nvim_set_hl(0, 'NvimDapVirtualText', { fg = '#c53737', italic = true })
    vim.api.nvim_set_hl(0, 'NvimDapVirtualTextChanged', { fg = '#c53737', italic = true, bold = true })

    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end
    
    -- Clear virtual text when debug session ends
    dap.listeners.after.event_terminated.dap_virtual_text = function()
      require('nvim-dap-virtual-text/virtual_text').clear_virtual_text()
    end
    dap.listeners.after.event_exited.dap_virtual_text = function()
      require('nvim-dap-virtual-text/virtual_text').clear_virtual_text()
    end

    -- Fallback Java DAP configuration
    -- This provides a basic "Launch Current File" option while the JDTLS provider
    -- discovers more specific configurations in the background
    dap.configurations.java = {
      {
        type = 'java',
        request = 'launch',
        name = "Launch Current File",
      },
    }
  end,
}
