return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      jdtls = { enabled = false },
      omnisharp = { enabled = false },
      ts_ls = { enabled = false },
    },
    setup = {
      jdtls = function()
        return true
      end,
    },
  },
}
