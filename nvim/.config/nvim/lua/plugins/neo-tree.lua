-- return {
--   "nvim-neo-tree/neo-tree.nvim",
--   opts = {
--     -- Enable document_symbols source (experimental)
--     sources = {
--       "filesystem",
--       "buffers",
--       "git_status",
--       "document_symbols",
--     },
--     -- Enable source selector to switch between filesystem, buffers, git, and document_symbols
--     source_selector = {
--       winbar = true, -- Show tabs in winbar
--       statusline = false,
--       sources = {
--         { source = "filesystem" },
--         { source = "buffers" },
--         { source = "git_status" },
--         { source = "document_symbols" },
--       },
--     },
--     filesystem = {
--       -- Follow current working directory
--       follow_current_file = {
--         enabled = true,
--       },
--       -- Use current working directory as root
--       hijack_netrw_behavior = "open_current",
--       -- Update tree when CWD changes
--       use_libuv_file_watcher = true,
--     },
--     buffers = {
--       follow_current_file = {
--         enabled = true,
--       },
--     },
--     window = {
--       -- Position and size
--       position = "left",
--       width = 35,
--       -- Custom mappings
--       mappings = {
--         ["<leader>e"] = "close_window",
--       },
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
return ---@type LazySpec
{
  "mikavilpas/yazi.nvim",
  version = "*", -- use the latest stable version
  event = "VeryLazy",
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
  },
  keys = {
    -- 👇 in this section, choose your own keymappings!
    {
      "<leader>-",
      mode = { "n", "v" },
      "<cmd>Yazi<cr>",
      desc = "Open yazi at the current file",
    },
    {
      -- Open in the current working directory
      "<leader>cw",
      "<cmd>Yazi cwd<cr>",
      desc = "Open the file manager in nvim's working directory",
    },
    {
      "<c-up>",
      "<cmd>Yazi toggle<cr>",
      desc = "Resume the last yazi session",
    },
  },
  ---@type YaziConfig | {}
  opts = {
    -- if you want to open yazi instead of netrw, see below for more info
    open_for_directories = false,
    keymaps = {
      show_help = "<f1>",
    },
  },
  -- 👇 if you use `open_for_directories=true`, this is recommended
  init = function()
    -- mark netrw as loaded so it's not loaded at all.
    --
    -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
    vim.g.loaded_netrwPlugin = 1
  end,
}
