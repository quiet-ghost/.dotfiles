return {
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    cmd = "Neogit",
    opts = {
      integrations = {
        diffview = true,
        telescope = true,
      },
      -- Use a floating window for the commit editor
      commit_editor = {
        kind = "floating",
      },
      -- Disable signs that conflict with gitsigns
      signs = {
        hunk = { "", "" },
        item = { ">", "v" },
        section = { ">", "v" },
      },
    },
  },
}
