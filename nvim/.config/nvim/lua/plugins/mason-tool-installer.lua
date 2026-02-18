return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    dependencies = {
      "mason-org/mason.nvim",
    },
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        "java-debug-adapter",
        "java-test",
        "codelldb",
      },
      run_on_start = true,
      start_delay = 3000,
      debounce_hours = 24,
      auto_update = false,
    },
  },
}
