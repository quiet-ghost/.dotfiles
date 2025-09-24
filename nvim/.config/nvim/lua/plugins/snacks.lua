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
    notifier = { enabled = true },
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
        enabled = false, -- Keep your scrolling animation disabled
      },
    })
    return opts
  end,
  keys = {
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