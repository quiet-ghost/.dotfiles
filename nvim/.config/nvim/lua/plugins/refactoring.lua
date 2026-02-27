return {
  "ThePrimeagen/refactoring.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("refactoring").setup({
      prompt_func_return_type = {
        go = false,
        java = true,
        cpp = true,
        c = false,
        h = false,
        hpp = false,
        cxx = false,
      },
      prompt_func_param_type = {
        go = false,
        java = true,
        cpp = true,
        c = false,
        h = false,
        hpp = false,
        cxx = false,
      },
      printf_statements = {},
      print_var_statements = {},
      show_success_message = true,
    })

    -- Load refactoring Telescope extension
    require("telescope").load_extension("refactoring")

    local map = vim.keymap.set

    local function refactor_expr(name)
      return function()
        return require("refactoring").refactor(name)
      end
    end

    -- Refactoring.nvim keymaps (using <leader>r prefix for general refactoring)
    -- Extract function (works in visual mode)
    map({ "n", "x" }, "<leader>re", refactor_expr("Extract Function"), { expr = true, desc = "Extract Function" })

    -- Extract function to file (works in visual mode)
    map({ "n", "x" }, "<leader>rf", refactor_expr("Extract Function To File"),
      { expr = true, desc = "Extract Function To File" })

    -- Extract variable (works in visual and normal mode)
    map({ "n", "x" }, "<leader>rv", refactor_expr("Extract Variable"), { expr = true, desc = "Extract Variable" })

    -- Inline variable (works in visual and normal mode)
    map({ "n", "x" }, "<leader>ri", refactor_expr("Inline Variable"), { expr = true, desc = "Inline Variable" })

    -- Extract block
    map("n", "<leader>rb", refactor_expr("Extract Block"), { expr = true, desc = "Extract Block" })

    -- Extract block to file
    map("n", "<leader>rbf", refactor_expr("Extract Block To File"), { expr = true, desc = "Extract Block To File" })

    -- Refactoring menu via Telescope with centered layout
    map({ "n", "x" }, "<leader>rr", function()
      require("telescope").extensions.refactoring.refactors({
        layout_strategy = "center",
        layout_config = {
          height = 0.4,
          width = 0.6,
          prompt_position = "top",
        },
        sorting_strategy = "ascending",
      })
    end, { desc = "Refactoring Menu" })

    -- Debug operations
    map("n", "<leader>rp", function()
      require("refactoring").debug.printf({ below = false })
    end, { desc = "Debug Print" })

    map({ "x", "n" }, "<leader>rdv", function()
      require("refactoring").debug.print_var()
    end, { desc = "Debug Print Variable" })

    map("n", "<leader>rc", function()
      require("refactoring").debug.cleanup({})
    end, { desc = "Debug Cleanup" })
  end,
}
