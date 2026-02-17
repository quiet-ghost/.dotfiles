return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "b0o/SchemaStore.nvim",
  },
  opts = function(_, opts)
    opts = opts or {}
    opts.servers = opts.servers or {}
    opts.setup = opts.setup or {}

    opts.servers.jdtls = { enabled = false }
    opts.servers.omnisharp = { enabled = false }
    opts.servers.ts_ls = { enabled = false }

    local ok, schemastore = pcall(require, "schemastore")
    if ok then
      opts.servers.jsonls = vim.tbl_deep_extend("force", opts.servers.jsonls or {}, {
        settings = {
          json = {
            schemas = schemastore.json.schemas(),
            validate = { enable = true },
          },
        },
      })

      opts.servers.yamlls = vim.tbl_deep_extend("force", opts.servers.yamlls or {}, {
        settings = {
          yaml = {
            schemaStore = {
              enable = false,
              url = "",
            },
            schemas = schemastore.yaml.schemas(),
          },
        },
      })
    end

    opts.setup.jdtls = function()
      return true
    end

    return opts
  end,
}
