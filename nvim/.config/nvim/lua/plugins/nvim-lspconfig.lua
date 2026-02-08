return {
  "neovim/nvim-lspconfig",
  opts = {
    setup = {
      jdtls = function()
        return true
      end,
    },
  },
}
