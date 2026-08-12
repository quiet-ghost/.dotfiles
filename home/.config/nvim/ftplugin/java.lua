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
local jdtls_setup = require("jdtls.setup")

-- Paths
local mason_path = home .. "/.local/share/nvim/mason/packages"
local jdtls_path = mason_path .. "/jdtls"
local java_debug_path = mason_path .. "/java-debug-adapter"
local java_test_path = mason_path .. "/java-test"
local jdtls_bin = mason_path .. "/jdtls/bin/jdtls"

-- Latest Lombok jar from local Maven repo (for jdtls annotation processing)
local function find_lombok_jar()
  local pattern = home .. "/.m2/repository/org/projectlombok/lombok/*/lombok-*.jar"
  local candidates = {}
  for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
    if
      path ~= ""
      and not path:match("%-sources%.jar$")
      and not path:match("%-javadoc%.jar$")
      and vim.fn.filereadable(path) == 1
    then
      table.insert(candidates, path)
    end
  end
  if #candidates == 0 then
    return nil
  end

  local function version_parts(path)
    local ver = path:match("lombok%-(%d+%.%d+%.%d+)")
    if not ver then
      return { 0, 0, 0 }
    end
    local major, minor, patch = ver:match("(%d+)%.(%d+)%.(%d+)")
    return { tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0 }
  end

  table.sort(candidates, function(a, b)
    local va, vb = version_parts(a), version_parts(b)
    for i = 1, 3 do
      if va[i] ~= vb[i] then
        return va[i] < vb[i]
      end
    end
    return false
  end)

  return candidates[#candidates]
end

local lombok_jar = find_lombok_jar()
if not lombok_jar and not vim.g.lombok_jar_warned then
  vim.g.lombok_jar_warned = true
  vim.notify(
    "Lombok jar not found under ~/.m2; @Data/@Getter will look undefined in jdtls",
    vim.log.levels.WARN
  )
end

-- Root/workspace
local current_file = vim.api.nvim_buf_get_name(0)
if current_file == "" then
  current_file = vim.fn.expand("%:p")
end
local file_dir = vim.fn.fnamemodify(current_file, ":h")
if file_dir == "" then
  file_dir = vim.fn.getcwd()
end

local function detect_package_name()
  local line_count = vim.api.nvim_buf_line_count(0)
  local max_lines = math.min(line_count, 200)
  local lines = vim.api.nvim_buf_get_lines(0, 0, max_lines, false)

  for _, line in ipairs(lines) do
    local package_name = line:match("^%s*package%s+([%w_.]+)%s*;")
    if package_name then
      return package_name
    end
  end

  return nil
end

local function derive_unmanaged_root()
  local package_name = detect_package_name()
  if not package_name or package_name == "" then
    return file_dir
  end

  local package_path = package_name:gsub("%.", "/")
  local normalized_dir = file_dir:gsub("\\", "/")
  local suffix = "/" .. package_path

  if #normalized_dir >= #suffix and normalized_dir:sub(-#suffix) == suffix then
    local root = normalized_dir:sub(1, #normalized_dir - #suffix)
    return root ~= "" and root or "/"
  end

  return file_dir
end

local managed_root = jdtls_setup.find_root({
  "mvnw",
  "gradlew",
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
  "settings.gradle",
  "settings.gradle.kts",
})
local root_dir = managed_root or derive_unmanaged_root() or vim.fn.getcwd()
local project_name = vim.fs.basename(root_dir)
if not project_name or project_name == "" then
  project_name = "default"
end
project_name = project_name:gsub("[^%w_.-]", "_")
local root_hash = vim.fn.sha256(root_dir):sub(1, 8)
local workspace_dir = home .. "/.local/share/nvim-data/jdtls-workspace/" .. project_name .. "-" .. root_hash
vim.fn.mkdir(workspace_dir, "p")

if vim.fn.executable(jdtls_bin) ~= 1 then
  vim.notify("jdtls launcher not found: " .. jdtls_bin, vim.log.levels.ERROR)
  return
end

if vim.fn.isdirectory(jdtls_path .. "/config_linux") ~= 1 then
  vim.notify("jdtls config_linux not found in Mason package", vim.log.levels.ERROR)
  return
end

-- Bundles for java-debug and java-test
local function collect_jars(pattern)
  local jars = {}
  for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
    if path ~= "" and vim.fn.filereadable(path) == 1 then
      table.insert(jars, path)
    end
  end
  return jars
end

if vim.fn.isdirectory(java_debug_path) == 0 and not vim.g.java_debug_bundle_warned then
  vim.g.java_debug_bundle_warned = true
  vim.notify("java-debug-adapter not found in Mason; Java DAP may be limited", vim.log.levels.WARN)
end

if vim.fn.isdirectory(java_test_path) == 0 and not vim.g.java_test_bundle_warned then
  vim.g.java_test_bundle_warned = true
  vim.notify("java-test not found in Mason; Java test integration may be limited", vim.log.levels.WARN)
end

local bundles = {}
vim.list_extend(bundles, collect_jars(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar"))
vim.list_extend(bundles, collect_jars(java_test_path .. "/extension/server/*.jar"))

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

  if vim.lsp.inlay_hint then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end

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

  local launch_config_name = "Debug (Launch) - Current File"

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

  local launch_config = {
    type = "java",
    request = "launch",
    name = launch_config_name,
    mainClass = find_main_class_simple,
    projectName = "",
    cwd = "${workspaceFolder}",
    classPaths = { "${workspaceFolder}" },
    modulePaths = {},
  }

  local replaced = false
  for i, cfg in ipairs(dap.configurations.java) do
    if cfg.name == launch_config_name then
      dap.configurations.java[i] = launch_config
      replaced = true
      break
    end
  end

  if not replaced then
    table.insert(dap.configurations.java, launch_config)
  end

  vim.defer_fn(function()
    local ok = pcall(require("jdtls.dap").setup_dap_main_class_configs)
    if not ok then
      vim.notify("DAP: Using manual config for standalone files", vim.log.levels.DEBUG)
    end
  end, 100)
end

-- JDTLS configuration
local java_settings = {
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
  inlayHints = {
    parameterNames = {
      enabled = "all",
    },
    variableTypes = {
      enabled = true,
    },
    parameterTypes = {
      enabled = true,
    },
    formatParameters = {
      enabled = true,
    },
  },
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
}

if not managed_root then
  java_settings.configuration.updateBuildConfiguration = "disabled"
  java_settings.project = {
    sourcePaths = { "." },
    outputPath = ".jdtls-out",
  }
end

local cmd = {
  jdtls_bin,
}
if lombok_jar then
  table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok_jar)
end
vim.list_extend(cmd, {
  "-configuration",
  jdtls_path .. "/config_linux",
  "-data",
  workspace_dir,
})

local config = {
  cmd = cmd,

  root_dir = root_dir,
  settings = {
    java = java_settings,
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
local config_root = config.root_dir
local clients = vim.lsp.get_clients({ name = "jdtls" })
for _, client in ipairs(clients) do
  if client.config.root_dir == config_root then
    -- Reuse existing client for the same root directory
    vim.lsp.buf_attach_client(0, client.id)
    vim.notify("Reusing JDTLS client for root: " .. config_root, vim.log.levels.DEBUG)
    return
  end
end

-- Start new JDTLS instance for this root
jdtls.start_or_attach(config)
