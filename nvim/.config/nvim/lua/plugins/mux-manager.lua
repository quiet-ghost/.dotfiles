return {
  "quiet-ghost/mux-manager",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("mux-manager").setup({
      directories = { "~/", "~/dev", "~/personal", "~/projects" }, -- Your project directories
      max_depth = 3, -- How deep to search in directories
      min_depth = 1, -- Minimum depth to search
      clone_directory = "~/dev/repos", -- Where to clone GitHub repos
    })
    require("telescope").load_extension("mux_manager")
  end,
}
