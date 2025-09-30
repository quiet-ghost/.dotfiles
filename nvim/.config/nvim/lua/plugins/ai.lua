return {
  {
    "supermaven-inc/supermaven-nvim",
    config = function()
      require("supermaven-nvim").setup({
        keymaps = {
          accept_suggestion = "<Tab>",
        },
        ignore_filetypes = { cpp = false },
        color = {
          suggestion_color = "#6d6d70",
          cterm = 244,
        },
        log_level = "info",
        disable_inline_completion = false,
        disable_keymaps = false,
        condition = function()
          return true
        end,
      })
    end,
  },
}
