-- return {
--   "nvim-neo-tree/neo-tree.nvim",
--   opts = {
--     filesystem = {
--       -- Follow current working directory
--       follow_current_file = true,
--       -- Use current working directory as root
--       hijack_netrw_behavior = "open_current",
--       -- Update tree when CWD changes
--       use_libuv_file_watcher = true,
--     },
--     window = {
--       -- Position and size
--       position = "left",
--       width = 30,
--     },
--     -- Custom mappings
--     mappings = {
--       ["<leader>e"] = "close_window",
--     },
--   },
--   keys = {
--     {
--       "<leader>e",
--       function()
--         require("neo-tree.command").execute({
--           toggle = true,
--           dir = vim.fn.getcwd(),
--         })
--       end,
--       desc = "Explorer NeoTree (cwd)",
--     },
--   },
-- }
return {
  "kyazdani42/nvim-tree.lua",
  dependencies = {
    "kyazdani42/nvim-web-devicons",
  },
  lazy = false,
  keys = {
    { "<leader>ff", "<cmd>NvimTreeFindFile<cr>", desc = "Find file in filetree" },
    { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Find file in filetree" },
  },
  opts = {
    filters = {
      custom = { ".git", "node_modules", ".vscode" },
      dotfiles = true,
    },
    git = {},
    view = {
      adaptive_size = true,
      float = {
        enable = true,
      },
    },
  },
}
