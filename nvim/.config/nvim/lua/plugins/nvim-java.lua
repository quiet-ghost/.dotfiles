return {
  "nvim-java/nvim-java",
  lazy = false,
  dependencies = {
    "JavaHello/spring-boot.nvim",
    "nvim-java/lua-async-await",
    "nvim-java/nvim-java-core",
    "nvim-java/nvim-java-test",
    "nvim-java/nvim-java-dap",
    "nvim-java/nvim-java-refactor",
    "MunifTanjim/nui.nvim",
    "mfussenegger/nvim-dap",
    "theHamsta/nvim-dap-virtual-text",
    {
      "rcarriga/nvim-dap-ui",
      dependencies = { "nvim-neotest/nvim-nio" },
      config = function()
        require("dapui").setup()
        require("nvim-dap-virtual-text").setup({
          enabled = true, -- Enable the plugin
          enabled_commands = true, -- Create commands like :DapVirtualTextEnable
          highlight_changed_variables = true, -- Highlight changed variables
          highlight_new_as_changed = true, -- Highlight new variables as changed
          show_stop_reason = true, -- Show why DAP stopped (e.g., breakpoint)
          commented = false, -- Show virtual text as comments (e.g., // value)
          virt_text_pos = "eol", -- Position of virtual text ("eol" or "inline")
          all_frames = false, -- Show virtual text for all stack frames
          virt_lines = false, -- Use virtual lines instead of virtual text
          virt_text_win_col = nil, -- Set to a number to fix column position
        })
      end,
    },
    {
      "mason-org/mason.nvim",
      opts = {
        registries = {
          "github:mason-org/mason-registry",
          "github:nvim-java/mason-registry",
        },
      },
    },
    {
      "neovim/nvim-lspconfig",
      opts = {
        servers = {
          jdtls = {
            capabilities = vim.lsp.protocol.make_client_capabilities(),
          },
        },
        setup = {
          jdtls = function()
            local InstallLocation = require("mason-core.installer.InstallLocation")
            local location = InstallLocation.global()
            local bundles = {
              vim.fn.glob(location:package("java-debug-adapter") .. "/extension/server/*.jar"),
              vim.fn.glob(location:package("java-test") .. "/extension/server/*.jar"),
            }
            -- Use JAVA_HOME from environment (set by mise)
            local java_home = os.getenv("JAVA_HOME")
            local java_exec = java_home and (java_home .. "/bin/java") or vim.fn.exepath("java")
            require("java").setup({
              jdk = {
                auto_install = true,
                path = java_exec,
              },
              notifications = {
                dap = true,
              },
            })
            local lspconfig = require("lspconfig")
            lspconfig.jdtls.setup({
              init_options = {
                bundles = bundles,
              },
              settings = {
                java = {
                  configuration = {
                    runtimes = require("utils.java").get_runtimes_config(),
                  },
                  import = {
                    gradle = {
                      enabled = true,
                    },
                    maven = {
                      enabled = true,
                    },
                    exclusions = {},
                  },
                  project = {
                    referencedLibraries = {
                      "lib/**/*.jar",
                    },
                  },
                },
              },
              -- Project root detection for single files, Maven, and IntelliJ projects
              root_dir = function(fname)
                local util = require("lspconfig.util")
                return util.root_pattern(
                  "pom.xml",           -- Maven
                  "build.gradle",      -- Gradle
                  "build.gradle.kts",  -- Gradle Kotlin
                  ".idea",             -- IntelliJ IDEA
                  ".project",          -- Eclipse
                  ".git"               -- Git repository
                )(fname) or vim.fn.getcwd()
              end,
            })
            -- Configure DAP for Java
            local dap = require("dap")
            dap.configurations.java = {
              {
                type = "java",
                request = "launch",
                name = "Launch Java",
                mainClass = "${fileBasenameNoExtension}",
                classPaths = { "${workspaceFolder}", vim.fn.getcwd() },
                javaExec = java_exec, -- Use detected JDK
                projectName = "${fileBasenameNoExtension}",
              },
              {
                type = "java",
                request = "attach",
                name = "Debug (Attach) - Remote",
                hostName = "127.0.0.1",
                port = 1326,
              },
            }
            return true -- Skip mason-lspconfig's default jdtls setup
          end,
        },
      },
    },
   },
 }
