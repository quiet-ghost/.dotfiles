return {
  "neovim/nvim-lspconfig",
  opts = {
    setup = {
      gopls = function(_, opts)
        opts.mason = false
      end,
      jdtls = function()
        return true
      end,
    },
  },
}
