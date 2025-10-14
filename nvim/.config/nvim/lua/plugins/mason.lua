return {
  "mason-org/mason.nvim",
  opts = {
    ensure_installed = {
      "java-debug-adapter",
      "java-test",
    },
    exclude = {
      "jdtls",
    },
    ui = {
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗",
      },
    },
  },
}
