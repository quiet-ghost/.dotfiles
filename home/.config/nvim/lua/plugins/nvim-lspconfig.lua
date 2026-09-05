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
    opts.servers.roslyn_ls = { enabled = false }
    opts.servers.ts_ls = { enabled = false }

    opts.servers.sourcekit = vim.tbl_deep_extend("force", opts.servers.sourcekit or {}, {
      mason = false,
      filetypes = { "swift" },
    })

    local clangd = opts.servers.clangd or {}
    local clangd_cmd = vim.deepcopy(clangd.cmd or { "clangd" })
    local query_driver = "--query-driver=/usr/bin/g++,/usr/bin/gcc,/usr/bin/c++,/usr/bin/clang++"
    local has_query_driver = false
    for _, arg in ipairs(clangd_cmd) do
      if vim.startswith(arg, "--query-driver=") then
        has_query_driver = true
        break
      end
    end
    if not has_query_driver then
      table.insert(clangd_cmd, query_driver)
    end
    opts.servers.clangd = vim.tbl_deep_extend("force", clangd, {
      cmd = clangd_cmd,
    })

    opts.servers.gopls = vim.tbl_deep_extend("force", opts.servers.gopls or {}, {
      settings = {
        gopls = {
          gofumpt = true,
          usePlaceholders = true,
          completeUnimported = true,
          staticcheck = true,
          templateExtensions = { "gotmpl" },
          directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
          semanticTokens = true,
          codelenses = {
            gc_details = false,
            generate = true,
            regenerate_cgo = true,
            run_govulncheck = true,
            test = true,
            tidy = true,
            upgrade_dependency = true,
            vendor = true,
          },
          hints = {
            assignVariableTypes = true,
            compositeLiteralFields = true,
            compositeLiteralTypes = true,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = true,
            rangeVariableTypes = true,
          },
          analyses = {
            nilness = true,
            unusedparams = true,
            unusedwrite = true,
            useany = true,
          },
        },
      },
    })

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

    opts.setup.gopls = function()
      Snacks.util.lsp.on({ name = "gopls" }, function(_, client)
        if client.server_capabilities.semanticTokensProvider then
          return
        end

        local semantic = client.config.capabilities
          and client.config.capabilities.textDocument
          and client.config.capabilities.textDocument.semanticTokens

        if not semantic then
          return
        end

        client.server_capabilities.semanticTokensProvider = {
          full = true,
          legend = {
            tokenTypes = semantic.tokenTypes,
            tokenModifiers = semantic.tokenModifiers,
          },
          range = true,
        }
      end)
    end

    opts.setup.jdtls = function()
      return true
    end

    return opts
  end,
}
