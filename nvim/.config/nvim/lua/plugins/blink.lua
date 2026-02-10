return {
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "*",
    opts = {
      keymap = {
        preset = "none", -- Don't use any preset, define everything custom

        -- Your custom Alt keybindings
        ["<M-j>"] = { "select_next", "fallback" },
        ["<M-k>"] = { "select_prev", "fallback" },
        ["<M-CR>"] = { "accept", "fallback" },
        ["<M-c>"] = { "cancel", "fallback" },

        -- Essential functions
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
        ["<C-f>"] = { "scroll_documentation_up", "fallback" },

        -- DISABLE Enter - only Alt+Enter works
        ["<CR>"] = { "fallback" },

        -- Tab accepts completion (including Supermaven suggestions)
        ["<Tab>"] = { "accept", "fallback" },
        ["<S-Tab>"] = { "fallback" },
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
      require("blink.cmp").setup(opts)

      -- Load snippets
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
