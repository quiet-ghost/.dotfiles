return {
  {
    "hrsh7th/nvim-cmp",
    event = "CmdlineEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      -- nvim-cmp insert mode disabled - using blink.cmp instead
      -- Only keep cmdline completion below

      -- Set up command-line completion
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
          { name = "cmdline" },
          { name = "luasnip" },
        }),
      })

      -- Set up search completion with highlighting
      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
        view = {
          entries = { name = "wildmenu", separator = "|" },
        },
        formatting = {
          format = function(entry, vim_item)
            vim_item.kind = "Text"
            vim_item.menu = "Search"
            return vim_item
          end,
        },
      })

      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
