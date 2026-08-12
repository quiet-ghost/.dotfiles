return {
  {
    "stevearc/quicker.nvim",
    ft = "qf",
    config = function(_, opts)
      require("quicker").setup(opts)

      local display = require("quicker.display")
      display.get_filename_from_item = function(item)
        if item.module and item.module ~= "" then
          return item.module
        elseif item.bufnr > 0 then
          local bufname = vim.api.nvim_buf_get_name(item.bufnr)
          local name = vim.fn.fnamemodify(bufname, ":t")
          if name == "" then
            return ""
          end
          return "../" .. name
        else
          return ""
        end
      end
    end,
    opts = {
      opts = {
        signcolumn = "yes",
        cursorline = true,
        winhighlight = "QuickFixLineNr:LineNr,QuickFixFilename:Directory,QuickFixText:Normal,QuickFixTextInvalid:Comment,CursorLine:Visual",
      },
      max_filename_width = function()
        return math.floor(math.min(40, vim.o.columns * 0.35))
      end,
      keys = {
        {
          ">",
          function()
            require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
          end,
          desc = "Expand quickfix context",
        },
        {
          "<",
          function()
            require("quicker").collapse()
          end,
          desc = "Collapse quickfix context",
        },
      },
    },
  },
}
