return {
  {
    lazy = false,
    priority = 1000,
    -- dir = "~/plugins/colorbuddy.nvim",
    "tjdevries/colorbuddy.nvim",
    config = function()
      vim.cmd.colorscheme("rose-pine-moon")
      vim.api.nvim_set_hl(0, "Cursor", { fg = "#232136", bg = "#569fbc" })
      vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#908caa", bg = "NONE", italic = true })
      vim.api.nvim_set_hl(0, "LspReferenceText", { bg = "#2f2c3c" })
      vim.api.nvim_set_hl(0, "LspReferenceRead", { bg = "#2f2c3c" })
      vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = "#2f2c3c" })
      vim.api.nvim_set_hl(0, "YankHighlight", { bg = "#56d4dd" })
    end,
  },
  "rktjmp/lush.nvim",
  "tckmn/hotdog.vim",
  "dundargoc/fakedonalds.nvim",
  "craftzdog/solarized-osaka.nvim",
  { "rose-pine/neovim", name = "rose-pine" },
  "eldritch-theme/eldritch.nvim",
  "jesseleite/nvim-noirbuddy",
  "miikanissi/modus-themes.nvim",
  "rebelot/kanagawa.nvim",
  "gremble0/yellowbeans.nvim",
  "rockyzhang24/arctic.nvim",
  "folke/tokyonight.nvim",
  "Shatur/neovim-ayu",
  "RRethy/base16-nvim",
  "xero/miasma.nvim",
  "cocopon/iceberg.vim",
  "kepano/flexoki-neovim",
  "ntk148v/komau.vim",
  { "catppuccin/nvim", name = "catppuccin" },
  "uloco/bluloco.nvim",
  "LuRsT/austere.vim",
  "ricardoraposo/gruvbox-minor.nvim",
  "NTBBloodbath/sweetie.nvim",
  "vim-scripts/MountainDew.vim",
  {
    "maxmx03/fluoromachine.nvim",
    -- config = function()
    --   local fm = require "fluoromachine"
    --   fm.setup { glow = true, theme = "fluoromachine" }
    -- end,
  },
}
