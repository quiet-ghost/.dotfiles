return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      gopls = {
        mason = false,
      },
      jdtls = false,
    },
    setup = {
      jdtls = function()
        return true
      end,
    },
  },
}
