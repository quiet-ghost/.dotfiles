return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  -- Override LazyVim's snacks configuration
  opts = function(_, opts)
    -- Merge with existing opts but override terminal settings
    opts = opts or {}
    opts = vim.tbl_deep_extend("force", opts, {
      bigfile = { enabled = true },
      notifier = {
        enabled = true,
        style = "minimal",
        timeout = 2200,
        margin = { top = 0, right = 1, bottom = 1 },
        width = { min = 24, max = 0.3 },
        height = { min = 1, max = 0.25 },
      },
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      terminal = {
        enabled = true,
        -- Terminal options
        win = {
          style = "terminal",
          position = "bottom",
          height = 0.3,
          width = 0.8,
        },
      },
      scroll = {
        enabled = true, -- Keep your scrolling animation disabled
      },
      dashboard = {
        enabled = true,
        preset = {
          header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
          ]],
        },
      },
    })
    return opts
  end,
  keys = {
    {
      "<leader>n",
      function()
        Snacks.notifier.show_history()
      end,
      desc = "Notification History",
    },
    {
      "<c-/>",
      function()
        -- Use the directory where you opened the file, not where nvim changed to
        local initial_cwd = vim.g.initial_cwd or vim.fn.getcwd()
        Snacks.terminal(nil, { cwd = initial_cwd })
      end,
      desc = "Toggle Terminal",
    },
    {
      "<c-_>",
      function()
        local initial_cwd = vim.g.initial_cwd or vim.fn.getcwd()
        Snacks.terminal(nil, { cwd = initial_cwd })
      end,
      desc = "which_key_ignore",
    },
  },
}
