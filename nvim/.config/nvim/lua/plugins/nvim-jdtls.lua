return {
  "mfussenegger/nvim-jdtls",
  ft = "java",
  -- lazy = false,
  -- cond = function()
  --   return vim.fn.glob("*.java") ~= "" or vim.fn.glob("**/*.java") ~= ""
  -- end,
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

    -- Workspace directory (equivalent to  data directory)
    local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. get_project_name()

    -- Mason installation paths
    local mason_path = vim.fn.stdpath("data") .. "/mason"
    local jdtls_path = mason_path .. "/packages/jdtls"
    local java_debug_path = mason_path .. "/packages/java-debug-adapter"
    local java_test_path = mason_path .. "/packages/java-test"

    -- Java executable (equivalent to  JAVA_HOME logic)
    local java_home = os.getenv("JAVA_HOME")
    local java_exec = java_home and (java_home .. "/bin/java") or vim.fn.exepath("java")

    -- Build bundles for debugging (equivalent to  bundles)
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

    -- Equivalent to runtimes configuration
    local function get_runtimes()
      return require("utils.java").get_runtimes_config()
    end

    -- Main JDTLS configuration (equivalent to lspconfig.jdtls.setup)
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

      -- Equivalent to  root_dir function
      root_dir = function(fname)
        if not fname:match("%.java$") then
          return nil
        end
        local util = require("lspconfig.util")

        -- First check for proper Java project markers
        local java_project_root = util.root_pattern("pom.xml", "build.gradle", ".idea", ".project", ".git", "")(fname)
        if java_project_root then
          return java_project_root
        end

        -- If in a git repo but no Java project files, treat as single file
        local git_root = util.root_pattern(".git")(fname)
        if git_root then
          -- Check if git repo has Java project structure
          local has_java_project = vim.fn.glob(git_root .. "/pom.xml") ~= ""
            or vim.fn.glob(git_root .. "/build.gradle") ~= ""
            or vim.fn.glob(git_root .. "/.idea") ~= ""
          if not has_java_project then
            return vim.fn.fnamemodify(fname, ":p:h") -- Single file mode
          end
          return git_root
        end

        return vim.fn.fnamemodify(fname, ":p:h") -- Default single file mode
      end,

      -- Equivalent to  settings
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
            sourcePaths = {},
            encoding = "UTF-8",
            outputPath = ".output",
          },
          sources = {
            organizeImports = {
              starThreshold = 9999,
              staticStarThreshold = 9999,
            },
          },
          eclipse = {
            downloadSources = true,
          },
          maven = {
            downloadSources = true,
          },
        },
      },

      -- Equivalent to  init_options
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
        virt_text_win_col = true,
      })
    end
  end,
}
