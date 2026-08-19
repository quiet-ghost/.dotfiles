return {
  {
    "saghen/blink.compat",
    version = "2.*",
    lazy = true,
    opts = {},
  },

  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "*",
    opts = {
      keymap = {
        preset = "none", -- Don't use any preset, define everything custom

        -- Your custom Alt keybindings
        ["<M-n>"] = { "select_next", "fallback" },
        ["<M-j>"] = { "select_prev", "fallback" },
        ["<M-CR>"] = { "accept", "fallback" },
        ["<M-c>"] = { "cancel", "fallback" },

        -- Essential functions
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },

        -- DISABLE Enter - only Alt+Enter works
        ["<CR>"] = { "fallback" },

        ["<Tab>"] = { "snippet_forward", "accept", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
      },

      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
      },

      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },

      completion = {
        accept = {
          auto_brackets = {
            enabled = true,
          },
        },
        menu = {
          draw = {
            treesitter = { "lsp" },
            columns = {
              -- { "kind_icon" }, -- Icon for the kind
              { "label", gap = 1 }, -- The actual completion text
              { "kind" }, -- Shows: Function, Variable, Method, etc.
              { "source_name" }, -- Shows: LSP, Snippet, Buffer, Path
            },
            components = {
              source_name = {
                width = { max = 30 },
                text = function(ctx)
                  return "[" .. ctx.source_name .. "]"
                end,
                highlight = "BlinkCmpSource",
              },
            },
          },
        },
        documentation = {
          auto_show = false,
          auto_show_delay_ms = 200,
        },
      },

      snippets = {
        expand = function(snippet)
          require("luasnip").lsp_expand(snippet)
        end,
        active = function(filter)
          if filter and filter.direction then
            return require("luasnip").jumpable(filter.direction)
          end
          return require("luasnip").in_snippet()
        end,
        jump = function(direction)
          require("luasnip").jump(direction)
        end,
      },
    },

    -- Add LuaSnip dependency for snippets
    dependencies = {
      "L3MON4D3/LuaSnip",
      "rafamadriz/friendly-snippets",
      "onsails/lspkind.nvim",
    },

    config = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.providers = opts.sources.providers or {}
      local enabled = opts.sources.default

      for _, source in ipairs(opts.sources.compat or {}) do
        opts.sources.providers[source] = vim.tbl_deep_extend(
          "force",
          { name = source, module = "blink.compat.source" },
          opts.sources.providers[source] or {}
        )
        if type(enabled) == "table" and not vim.tbl_contains(enabled, source) then
          table.insert(enabled, source)
        end
      end

      opts.sources.compat = nil

      require("blink.cmp").setup(opts)

      -- Load snippets
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
