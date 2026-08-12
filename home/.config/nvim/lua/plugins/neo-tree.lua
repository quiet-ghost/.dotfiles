return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      -- Follow current working directory
      follow_current_file = true,
      -- Use current working directory as root
      hijack_netrw_behavior = "open_current",
      -- Update tree when CWD changes
      use_libuv_file_watcher = true,
    },
    window = {
      -- Position and size
      position = "left",
      width = 30,
    },
    -- Custom mappings
    mappings = {
      ["<leader>e"] = "close_window",
    },
  },
  keys = {
    {
      "<leader>e",
      function()
        require("neo-tree.command").execute({
          toggle = true,
          dir = vim.fn.getcwd(),
        })
      end,
      desc = "Explorer NeoTree (cwd)",
    },
  },
}
