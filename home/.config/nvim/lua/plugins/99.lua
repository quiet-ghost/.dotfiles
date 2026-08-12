return {
  "ThePrimeagen/99",
  keys = {
    {
      "<leader>}f",
      mode = "v",
      function()
        require("99").visual()
      end,
      desc = "99 Visual",
    },
    {
      "<leader>}x",
      mode = { "n", "v" },
      function()
        require("99").stop_all_requests()
      end,
      desc = "99 Stop",
    },
    {
      "<leader>}s",
      mode = { "n", "v" },
      function()
        require("99").search()
      end,
    },
    {
      "<leader>}p",
      mode = { "n", "v" },
      function()
        require("99.extensions.telescope").select_provider()
      end,
    },
    {
      "<leader>}m",
      mode = { "n", "v" },
      function()
        require("99.extensions.telescope").select_model()
      end,
    },
  },
  config = function()
    local _99 = require("99")
    local cwd = vim.uv.cwd()
    local basename = vim.fs.basename(cwd)
    _99.setup({
      provider = _99.Providers.OpenCodeProvider,
      model = "opencode/kimi-k2.7-code",
      logger = {
        level = _99.DEBUG,
        path = "/tmp/" .. basename .. ".99.debug",
        print_on_error = true,
      },
      completion = {
        custom_rules = {
          "~/.agents/skills/",
        },
        source = "blink",
      },
      md_files = {
        "AGENT.md",
      },
    })
  end,
}
