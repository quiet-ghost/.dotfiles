return {
  {
    "lukas-reineke/virt-column.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      char = { " " },
      virtcolumn = "80",
      highlight = { "NonText" },
    },
  },
}
