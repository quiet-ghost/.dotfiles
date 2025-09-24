return {
  "quiet-ghost/git-worktree.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim", -- optional
  },
  config = function()
    require("worktree").setup({
      worktree_dir = ".worktrees", -- Directory name for worktrees
      auto_switch = true, -- Auto-switch to new worktrees
      telescope_integration = true, -- Enable telescope integration
    })
  end,
}
