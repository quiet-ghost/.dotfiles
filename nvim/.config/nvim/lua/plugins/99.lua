return {
  "ThePrimeagen/99",
  config = function()
    local _99 = require("99")

    -- For logging that is to a file if you wish to trace through requests
    -- for reporting bugs, i would not rely on this, but instead the provided
    -- logging mechanisms within 99.  This is for more debugging purposes
    local cwd = vim.uv.cwd()
    local basename = vim.fs.basename(cwd)
    _99.setup({
      model = "opencode/kimi-k2.5",
      logger = {
        level = _99.DEBUG,
        path = "/tmp/" .. basename .. ".99.debug",
        print_on_error = true,
      },

      --- A new feature that is centered around tags
      completion = {
        custom_rules = {
          "home/ghost/dev/skills/",
        },
        -- source = "cmp",
      },

      --- WARNING: if you change cwd then this is likely broken
      --- ill likely fix this in a later change
      md_files = {
        "AGENT.md",
      },
    })

    -- Create your own short cuts for the different types of actions
    vim.keymap.set("n", "<leader>9g", function()
      _99.fill_in_function_prompt()
    end)

    vim.keymap.set("v", "<leader>9f", function()
      _99.visual_prompt()
    end)

    vim.keymap.set("n", "<leader>9i", function()
      _99.info()
    end)

    vim.keymap.set("n", "<leader>9l", function()
      _99.view_logs()
    end)

    vim.keymap.set("v", "<leader>9s", function()
      _99.stop_all_requests()
    end)

    --- Example: Using rules + actions for custom behaviors
    --- Create a rule file like ~/.rules/debug.md that defines custom behavior.
    --- For instance, a "debug" rule could automatically add printf statements
    --- throughout a function to help debug its execution flow.
    vim.keymap.set("n", "<leader>9fd", function()
      _99.fill_in_function({
        additional_rules = {
          _99:rule_from_path("~/dev/skills/printf_debug/debug.md"),
        },
      })
    end)
  end,
}
