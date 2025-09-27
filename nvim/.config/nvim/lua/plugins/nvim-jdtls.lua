return {
  "mfussenegger/nvim-jdtls",
  lazy = false,
  cond = function()
    return vim.fn.glob("*.java") ~= "" or vim.fn.glob("**/*.java") ~= ""
  end,
  dependencies = {
    "mfussenegger/nvim-dap",
    "rcarriga/nvim-dap-ui",
    "theHamsta/nvim-dap-virtual-text",
    {
      "mason-org/mason.nvim",
      opts = {
        registries = {
          "github:nvim-java/mason-registry",
          "github:mason-org/mason-registry",
        },
      },
    },
  },
  config = function()
    local jdtls = require("jdtls")

    -- Helper function to get project name
    local function get_project_name()
      return vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
    end

    -- Workspace directory (equivalent to your data directory)
    local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. get_project_name()

    -- Mason installation paths
    local mason_path = vim.fn.stdpath("data") .. "/mason"
    local jdtls_path = mason_path .. "/packages/jdtls"
    local java_debug_path = mason_path .. "/packages/java-debug-adapter"
    local java_test_path = mason_path .. "/packages/java-test"

    -- Java executable (equivalent to your JAVA_HOME logic)
    local java_home = os.getenv("JAVA_HOME")
    local java_exec = java_home and (java_home .. "/bin/java") or vim.fn.exepath("java")

    -- Build bundles for debugging (equivalent to your bundles)
    local bundles = {}

    -- Add java-debug bundles
    local java_debug_jar = vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar")
    if java_debug_jar ~= "" then
      table.insert(bundles, java_debug_jar)
    end

    -- Add java-test bundles
    local java_test_jars = vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar"), "\n")
    local excluded = {
      "com.microsoft.java.test.runner-jar-with-dependencies.jar",
      "jacocoagent.jar",
    }
    for _, jar in ipairs(java_test_jars) do
      local fname = vim.fn.fnamemodify(jar, ":t")
      if jar ~= "" and not vim.tbl_contains(excluded, fname) then
        table.insert(bundles, jar)
      end
    end

    -- Equivalent to your runtimes configuration
    local function get_runtimes()
      -- You can customize this based on your utils/java.lua logic
      local runtimes = {}
      if java_home then
        table.insert(runtimes, {
          name = "JavaSE-21",
          path = java_home,
          default = true,
        })
      end
      return runtimes
    end

    -- Main JDTLS configuration (equivalent to your lspconfig.jdtls.setup)
    local config = {
      name = "jdtls",
      cmd = {
        java_exec,
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true",
        "-Dlog.level=ALL",
        "-Xms1g",
        "--add-modules=ALL-SYSTEM",
        "--add-opens",
        "java.base/java.util=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.lang=ALL-UNNAMED",
        "-jar",
        vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
        "-configuration",
        jdtls_path .. "/config_linux",
        "-data",
        workspace_dir,
      },

      -- Equivalent to your root_dir function
      root_dir = function(fname)
        if not fname:match("%.java$") then
          return nil
        end
        local util = require("lspconfig.util")
        local project_root = util.root_pattern("pom.xml", "build.gradle", ".idea", ".project", ".git")(fname)
        return project_root or vim.fn.fnamemodify(fname, ":p:h")
      end,

      -- Equivalent to your settings
      settings = {
        java = {
          configuration = {
            runtimes = get_runtimes(),
          },
          import = {
            gradle = { enabled = true },
            maven = { enabled = true },
            exclusions = {},
          },
          project = {
            referencedLibraries = {
              "lib/**/*.jar",
              "**/*.jar", -- Allow finding JARs anywhere for single files
            },
            resourceFilters = { "node_modules", ".git" },
            sourcePaths = { "" }, -- Current directory as source path
          },
        },
      },

      -- Equivalent to your init_options
      init_options = {
        bundles = bundles,
        -- Add this for single file support:
        extendedClientCapabilities = {
          classFileContentsSupport = true,
          overrideMethodsPromptSupport = true,
          hashCodeEqualsPromptSupport = true,
          advancedOrganizeImportsSupport = true,
          generateToStringPromptSupport = true,
          advancedGenerateAccessorsSupport = true,
          generateConstructorsPromptSupport = true,
          generateDelegateMethodsPromptSupport = true,
          advancedExtractRefactoringSupport = true,
          moveRefactoringSupport = true,
          clientHoverProvider = true,
          clientDocumentSymbolProvider = true,
          gradleChecksumWrapperPromptSupport = true,
          resolveAdditionalTextEditsSupport = true,
          inferSelectionSupport = { "extractMethod", "extractVariable", "extractConstant" },
        },
      },

      -- Additional nvim-jdtls specific options
      on_attach = function(client, bufnr)
        -- Enable completion triggered by <c-x><c-o>
        vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

        -- Setup DAP if available
        if pcall(require, "dap") then
          jdtls.setup_dap({ hotcodereplace = "auto" })
          jdtls.setup.add_commands()
        end

        -- Key mappings (equivalent to your refactoring setup)
        local opts = { buffer = bufnr, silent = true }
        vim.keymap.set("n", "<A-o>", jdtls.organize_imports, opts)
        vim.keymap.set("n", "crv", jdtls.extract_variable, opts)
        vim.keymap.set("v", "crv", function()
          jdtls.extract_variable(true)
        end, opts)
        vim.keymap.set("n", "crc", jdtls.extract_constant, opts)
        vim.keymap.set("v", "crc", function()
          jdtls.extract_constant(true)
        end, opts)
        vim.keymap.set("v", "crm", function()
          jdtls.extract_method(true)
        end, opts)

        -- Test runners (equivalent to your DAP test functionality)
        vim.keymap.set("n", "<leader>df", jdtls.test_class, opts)
        vim.keymap.set("n", "<leader>dn", jdtls.test_nearest_method, opts)
      end,

      capabilities = require("blink.cmp").get_lsp_capabilities(),
    }

    -- Start or attach JDTLS
    jdtls.start_or_attach(config)

    -- Setup DAP UI if available
    if pcall(require, "dapui") then
      require("dapui").setup()
      require("nvim-dap-virtual-text").setup({
        enabled = true,
        enabled_commands = true,
        highlight_changed_variables = true,
        highlight_new_as_changed = true,
        show_stop_reason = true,
        commented = false,
        virt_text_pos = "eol",
        all_frames = false,
        virt_lines = false,
        virt_text_win_col = nil,
      })
    end
  end,
}
