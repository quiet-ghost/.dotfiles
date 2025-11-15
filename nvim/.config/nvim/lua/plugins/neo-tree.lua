return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    -- Enable document_symbols source (experimental)
    sources = {
      "filesystem",
      "buffers",
      "git_status",
      "document_symbols",
    },
    -- Enable source selector to switch between filesystem, buffers, git, and document_symbols
    source_selector = {
      winbar = true, -- Show tabs in winbar
      statusline = false,
      sources = {
        { source = "filesystem" },
        { source = "buffers" },
        { source = "git_status" },
        { source = "document_symbols" },
      },
    },
    filesystem = {
      -- Follow current working directory
      follow_current_file = {
        enabled = true,
      },
      -- Use current working directory as root
      hijack_netrw_behavior = "open_current",
      -- Update tree when CWD changes
      use_libuv_file_watcher = true,
    },
    buffers = {
      follow_current_file = {
        enabled = true,
      },
    },
    window = {
      -- Position and size
      position = "left",
      width = 35,
      -- Custom mappings
      mappings = {
        ["<leader>e"] = "close_window",
      },
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
