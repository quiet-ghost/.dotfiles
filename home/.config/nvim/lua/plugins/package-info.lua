return {
  {
    "vuki656/package-info.nvim",
    event = { "BufReadPost package.json", "BufNewFile package.json" },
    dependencies = { "MunifTanjim/nui.nvim" },
    config = function()
      require("package-info").setup({
        autostart = true,
        package_manager = {
          "npm",
          "yarn",
          "pnpm",
        },
        colors = {
          outdated = "#db4b4b",
        },
        hide_up_to_date = true,
      })
    end,
  },
}
