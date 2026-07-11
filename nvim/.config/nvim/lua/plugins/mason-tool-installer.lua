return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    dependencies = {
      "mason-org/mason.nvim",
    },
    opts_extend = { "ensure_installed" },
    opts = function(_, opts)
      opts = opts or {}
      opts.ensure_installed = opts.ensure_installed or {}

      local tools = {
        "java-debug-adapter",
        "java-test",
        "codelldb",
        "delve",
        "goimports",
        "gofumpt",
        "gomodifytags",
        "impl",
        "xcode-build-server",
        "swiftformat",
        "swiftlint",
      }

      for _, tool in ipairs(tools) do
        if not vim.tbl_contains(opts.ensure_installed, tool) then
          table.insert(opts.ensure_installed, tool)
        end
      end

      opts.run_on_start = true
      opts.start_delay = 3000
      opts.debounce_hours = 24
      opts.auto_update = false

      return opts
    end,
  },
}
