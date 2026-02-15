return {
  "NickvanDyke/opencode.nvim",
  dependencies = {
    -- Recommended for `ask()` and `select()`.
    -- Required for default `toggle()` implementation.
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  init = function()
    vim.g.opencode_opts = {
      provider = {
        snacks = {
          win = {
            position = "right",
            width = 0.35,
          },
        },
      },
    }

    vim.o.autoread = true
  end,
  keys = {
    {
      "<C-a>",
      mode = { "n", "x" },
      function()
        require("opencode").ask("@this: ", { submit = true })
      end,
      desc = "Ask opencode",
    },
    {
      "<C-x>",
      mode = { "n", "x" },
      function()
        require("opencode").select()
      end,
      desc = "Execute opencode action",
    },
    {
      "ga",
      mode = { "n", "x" },
      function()
        require("opencode").prompt("@this")
      end,
      desc = "Add to opencode",
    },
    {
      "<C-.>",
      mode = { "n", "t" },
      function()
        require("opencode").toggle()
      end,
      desc = "Toggle opencode",
    },
    {
      "<S-C-u>",
      mode = "n",
      function()
        require("opencode").command("session.half.page.up")
      end,
      desc = "opencode half page up",
    },
    {
      "<S-C-d>",
      mode = "n",
      function()
        require("opencode").command("session.half.page.down")
      end,
      desc = "opencode half page down",
    },
  },
}
