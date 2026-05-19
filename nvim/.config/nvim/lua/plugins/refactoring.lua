return {
  "ThePrimeagen/refactoring.nvim",
  event = "VeryLazy",
  dependencies = {
    "lewis6991/async.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("refactoring").setup({
      show_success_message = true,
    })

    local map = vim.keymap.set

    local function refactor_expr(refactor)
      return function()
        return require("refactoring")[refactor]()
      end
    end

    -- Refactoring.nvim keymaps (using <leader>r prefix for general refactoring)
    -- Extract function (works in visual mode)
    map({ "n", "x" }, "<leader>re", refactor_expr("extract_func"), { expr = true, desc = "Extract Function" })

    -- Extract function to file (works in visual mode)
    map(
      { "n", "x" },
      "<leader>rf",
      refactor_expr("extract_func_to_file"),
      { expr = true, desc = "Extract Function To File" }
    )

    -- Extract variable (works in visual and normal mode)
    map({ "n", "x" }, "<leader>rv", refactor_expr("extract_var"), { expr = true, desc = "Extract Variable" })

    -- Inline variable (works in visual and normal mode)
    map({ "n", "x" }, "<leader>ri", refactor_expr("inline_var"), { expr = true, desc = "Inline Variable" })

    -- Inline function
    map({ "n", "x" }, "<leader>rI", refactor_expr("inline_func"), { expr = true, desc = "Inline Function" })

    -- Refactoring menu
    map({ "n", "x" }, "<leader>rr", function()
      require("refactoring").select_refactor()
    end, { desc = "Refactoring Menu" })

    -- Debug operations
    map("n", "<leader>rp", function()
      return require("refactoring.debug").print_loc({ output_location = "above" })
    end, { expr = true, desc = "Debug Print Location" })

    map("n", "<leader>rdv", function()
      return require("refactoring.debug").print_var({ output_location = "below" }) .. "iw"
    end, { expr = true, desc = "Debug Print Variable" })

    map("x", "<leader>rdv", function()
      return require("refactoring.debug").print_var({ output_location = "below" })
    end, { expr = true, desc = "Debug Print Variable" })

    map("n", "<leader>rc", function()
      return "gg" .. require("refactoring.debug").cleanup({ restore_view = true }) .. "G"
    end, { expr = true, desc = "Debug Cleanup" })
  end,
}
