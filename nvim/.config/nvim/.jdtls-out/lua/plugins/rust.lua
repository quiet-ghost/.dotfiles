return {
  {
    "mrcjkb/rustaceanvim",
    ft = { "rust" },
    dependencies = {
      "rachartier/tiny-inline-diagnostic.nvim",
    },
    opts = function(_, opts)
      opts = opts or {}
      opts.server = opts.server or {}

      opts.server.cmd = { "rust-analyzer" }
      opts.server.standalone = true

      local on_attach = opts.server.on_attach
      opts.server.on_attach = function(client, bufnr)
        if on_attach then
          on_attach(client, bufnr)
        end

        vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover Documentation" })
      end

      return opts
    end,
  },
}
