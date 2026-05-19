return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "alfaix/neotest-gtest",
    },
    keys = {
      {
        "<leader>tn",
        function()
          require("neotest").run.run()
        end,
        desc = "Test Nearest",
      },
      {
        "<leader>td",
        function()
          require("neotest").run.run({ strategy = "dap" })
        end,
        desc = "Debug Nearest Test",
      },
      {
        "<leader>tF",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Test Current File",
      },
      {
        "<leader>tD",
        function()
          require("neotest").run.run({ vim.fn.expand("%"), strategy = "dap" })
        end,
        desc = "Debug Current File Tests",
      },
      {
        "<leader>ta",
        function()
          require("neotest").run.run(vim.fn.getcwd())
        end,
        desc = "Test All (cwd)",
      },
      {
        "<leader>to",
        function()
          require("neotest").output.open({ enter = true, auto_close = true })
        end,
        desc = "Test Output",
      },
      {
        "<leader>tp",
        function()
          require("neotest").output_panel.toggle()
        end,
        desc = "Toggle Test Output Panel",
      },
      {
        "<leader>ts",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "Toggle Test Summary",
      },
      {
        "<leader>tg",
        function()
          require("neotest-gtest.executables").configure_executable()
        end,
        desc = "Configure GTest Binary",
      },
    },
    opts = function(_, opts)
      opts = opts or {}
      opts.adapters = opts.adapters or {}

      local gtest_adapter = require("neotest-gtest").setup({
        root = require("neotest.lib").files.match_root_pattern(
          "compile_commands.json",
          "compile_flags.txt",
          "CMakeLists.txt",
          "Makefile",
          "meson.build",
          ".git"
        ),
        debug_adapter = "codelldb",
        mappings = { configure = "C" },
        is_test_file = function(file_path)
          local is_cpp_file = file_path:match("%.cpp$")
            or file_path:match("%.cc$")
            or file_path:match("%.cxx$")
            or file_path:match("%.c%+%+$")
            or file_path:match("%.cppm$")

          if not is_cpp_file then
            return false
          end

          local filename = vim.fn.fnamemodify(file_path, ":t")
          return filename:match("^test_")
            or filename:match("_test%.")
            or filename:match("%.spec%.")
            or file_path:match("/tests?/")
        end,
      })

      table.insert(opts.adapters, gtest_adapter)
      return opts
    end,
  },

}
