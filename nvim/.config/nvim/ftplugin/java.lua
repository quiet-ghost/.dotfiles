vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.expandtab = true

-- Prevent multiple runs for the same buffer
if vim.b.jdtls_setup_done then
  return
end
vim.b.jdtls_setup_done = true

local home = os.getenv("HOME")
local jdtls = require("jdtls")

-- Paths
local mason_path = home .. "/.local/share/nvim/mason/packages"
local jdtls_path = mason_path .. "/jdtls"
local java_debug_path = mason_path .. "/java-debug-adapter"
local java_test_path = mason_path .. "/java-test"

-- Java executable - dynamically detect from mise/JAVA_HOME/PATH
local function get_java_executable()
  local mise_java = vim.fn.exepath("java")
  if mise_java and mise_java ~= "" then
    return mise_java
  end
  local java_home = os.getenv("JAVA_HOME")
  if java_home then
    return java_home .. "/bin/java"
  end
  return "java"
end

local java_exec = get_java_executable()

-- Workspace
local project_name = vim.fn.fnamemodify(vim.fn.expand("%:p:h"), ":t")
local workspace_dir = home .. "/.local/share/nvim-data/jdtls-workspace/" .. project_name

-- Bundles for java-debug and java-test
local bundles = {
  vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", true),
}

vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar", true), "\n"))

-- Filter out excluded bundles
local filtered_bundles = {}
for _, bundle in ipairs(bundles) do
  if
    bundle ~= ""
    and not bundle:match("com.microsoft.java.test.runner%-jar%-with%-dependencies%.jar")
    and not bundle:match("jacocoagent%.jar")
  then
    table.insert(filtered_bundles, bundle)
  end
end

-- LSP on_attach
local on_attach = function(client, bufnr)
  local opts = { buffer = bufnr, silent = true }

  -- Standard LSP keymaps
  vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover Documentation" }))
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to Definition" }))
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to Declaration" }))
  vim.keymap.set(
    "n",
    "gi",
    vim.lsp.buf.implementation,
    vim.tbl_extend("force", opts, { desc = "Go to Implementation" })
  )
  vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "References" }))
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code Action" }))
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
  vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature Help" }))

  -- Java specific keymaps
  vim.keymap.set(
    "n",
    "<leader>jo",
    jdtls.organize_imports,
    vim.tbl_extend("force", opts, { desc = "Organize Imports" })
  )
  vim.keymap.set(
    "n",
    "<leader>jv",
    jdtls.extract_variable,
    vim.tbl_extend("force", opts, { desc = "Extract Variable" })
  )
  vim.keymap.set("v", "<leader>jv", function()
    jdtls.extract_variable(true)
  end, vim.tbl_extend("force", opts, { desc = "Extract Variable" }))
  vim.keymap.set(
    "n",
    "<leader>jc",
    jdtls.extract_constant,
    vim.tbl_extend("force", opts, { desc = "Extract Constant" })
  )
  vim.keymap.set("v", "<leader>jc", function()
    jdtls.extract_constant(true)
  end, vim.tbl_extend("force", opts, { desc = "Extract Constant" }))
  vim.keymap.set("v", "<leader>jm", function()
    jdtls.extract_method(true)
  end, vim.tbl_extend("force", opts, { desc = "Extract Method" }))

  -- Test keymaps
  vim.keymap.set("n", "<leader>jtc", jdtls.test_class, vim.tbl_extend("force", opts, { desc = "Test Class" }))
  vim.keymap.set("n", "<leader>jtm", jdtls.test_nearest_method, vim.tbl_extend("force", opts, { desc = "Test Method" }))

  -- Setup DAP
  jdtls.setup_dap({ hotcodereplace = "auto" })
  jdtls.setup.add_commands()

  -- Manual DAP configuration
  local dap = require("dap")
  if not dap.configurations.java then
    dap.configurations.java = {}
  end

  local function find_main_class_simple()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    local main_line_idx = nil
    for i, line in ipairs(lines) do
      if line:match("public%s+static%s+void%s+main%s*%(") or line:match("static%s+public%s+void%s+main%s*%(") then
        main_line_idx = i
        break
      end
    end

    if not main_line_idx then
      return vim.fn.expand("%:t:r")
    end

    for i = main_line_idx, 1, -1 do
      local line = lines[i]
      local class_match = line:match("class%s+([%w_]+)")
      if class_match then
        return class_match
      end
    end

    return vim.fn.expand("%:t:r")
  end

  table.insert(dap.configurations.java, {
    type = "java",
    request = "launch",
    name = "Debug (Launch) - Current File",
    mainClass = find_main_class_simple,
    projectName = "",
    cwd = "${workspaceFolder}",
    classPaths = { "${workspaceFolder}" },
    modulePaths = {},
  })

  vim.defer_fn(function()
    local ok, err = pcall(require("jdtls.dap").setup_dap_main_class_configs)
    if not ok then
      vim.notify("DAP: Using manual config for standalone files", vim.log.levels.DEBUG)
    end
  end, 100)
end

-- JDTLS configuration
local config = {
  cmd = {
    mason_path .. "/jdtls/bin/jdtls",
    "-configuration",
    jdtls_path .. "/config_linux",
    "-data",
    workspace_dir,
  },

  root_dir = require("jdtls.setup").find_root({ "mvnw", "gradlew", "pom.xml", "build.gradle" }) or vim.fn.getcwd(),
  settings = {
    java = {
      eclipse = {
        downloadSources = true,
      },
      configuration = {
        updateBuildConfiguration = "interactive",
        runtimes = require("utils.java").get_runtimes_config(),
      },
      maven = {
        downloadSources = true,
      },
      import = {
        exclusions = {
          "**/node_modules/**",
          "**/.metadata/**",
          "**/archetype-resources/**",
          "**/target/**",
          "**/bin/**",
        },
      },
      implementationsCodeLens = {
        enabled = true,
      },
      referencesCodeLens = {
        enabled = true,
      },
      references = {
        includeDecompiledSources = true,
      },
      format = {
        enabled = true,
      },
      signatureHelp = { enabled = true },
      contentProvider = { preferred = "fernflower" },
      completion = {
        favoriteStaticMembers = {
          "org.hamcrest.MatcherAssert.assertThat",
          "org.hamcrest.Matchers.*",
          "org.hamcrest.CoreMatchers.*",
          "org.junit.jupiter.api.Assertions.*",
          "java.util.Objects.requireNonNull",
          "java.util.Objects.requireNonNullElse",
          "org.mockito.Mockito.*",
        },
        filteredTypes = {
          "com.sun.*",
          "io.micrometer.shaded.*",
          "java.awt.*",
          "jdk.*",
          "sun.*",
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
        },
        useBlocks = true,
      },
    },
  },

  init_options = {
    bundles = filtered_bundles,
    extendedClientCapabilities = jdtls.extendedClientCapabilities,
  },

  on_attach = on_attach,
  capabilities = (function()
    local capabilities = require("blink.cmp").get_lsp_capabilities()
    capabilities.textDocument.hover = {
      dynamicRegistration = false,
      contentFormat = { "markdown", "plaintext" },
    }
    return capabilities
  end)(),
}

-- Check if JDTLS is already running for this root
local root_dir = config.root_dir
local clients = vim.lsp.get_clients({ name = "jdtls" })
for _, client in ipairs(clients) do
  if client.config.root_dir == root_dir then
    -- Reuse existing client for the same root directory
    vim.lsp.buf_attach_client(0, client.id)
    vim.notify("Reusing JDTLS client for root: " .. root_dir, vim.log.levels.DEBUG)
    return
  end
end

-- Start new JDTLS instance for this root
jdtls.start_or_attach(config)
