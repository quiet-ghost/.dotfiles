return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      panel = { enabled = false },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = false,
        trigger_on_accept = false,
        keymap = {
          accept = false,
          accept_word = false,
          accept_line = false,
          next = false,
          prev = false,
          dismiss = false,
        },
      },
      filetypes = {
        ["*"] = true,
      },
    },
    config = function(_, opts)
      require("copilot").setup(opts)
      local suggestion = require("copilot.suggestion")

      local function accept_copilot_or_tab(accept)
        return function()
          if suggestion.is_visible() then
            accept()
          else
            -- Supermaven inserts a literal Tab, bypassing Blink, when no suggestion exists.
            vim.api.nvim_feedkeys(vim.keycode("<Tab>"), "n", true)
          end
        end
      end

      vim.keymap.set("i", "<C-f>", accept_copilot_or_tab(suggestion.accept), {
        silent = true,
        desc = "Accept Copilot suggestion",
      })
      vim.keymap.set("i", "<C-j>", accept_copilot_or_tab(suggestion.accept_word), {
        silent = true,
        desc = "Accept Copilot word",
      })
      vim.keymap.set("i", "<C-]>", suggestion.dismiss, {
        silent = true,
        desc = "Dismiss Copilot suggestion",
      })
    end,
  },
}
