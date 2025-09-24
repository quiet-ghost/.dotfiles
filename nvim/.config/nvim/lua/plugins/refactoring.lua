return {
  "ThePrimeagen/refactoring.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("refactoring").setup({
      prompt_func_return_type = {
        go = false,
        java = true,
        cpp = false,
        c = false,
        h = false,
        hpp = false,
        cxx = false,
      },
      prompt_func_param_type = {
        go = false,
        java = true,
        cpp = false,
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

    -- Refactoring.nvim keymaps (using <leader>r prefix for general refactoring)
    -- Extract function (works in visual mode)
    map("x", "<leader>re", function()
      require("refactoring").refactor("Extract Function")
    end, { desc = "Extract Function" })

    -- Extract function to file (works in visual mode)
    map("x", "<leader>rf", function()
      require("refactoring").refactor("Extract Function To File")
    end, { desc = "Extract Function To File" })

    -- Extract variable (works in visual and normal mode)
    map({ "n", "x" }, "<leader>rv", function()
      require("refactoring").refactor("Extract Variable")
    end, { desc = "Extract Variable" })

    -- Inline variable (works in visual and normal mode)
    map({ "n", "x" }, "<leader>ri", function()
      require("refactoring").refactor("Inline Variable")
    end, { desc = "Inline Variable" })

    -- Extract block
    map("n", "<leader>rb", function()
      require("refactoring").refactor("Extract Block")
    end, { desc = "Extract Block" })

    -- Extract block to file
    map("n", "<leader>rbf", function()
      require("refactoring").refactor("Extract Block To File")
    end, { desc = "Extract Block To File" })

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
