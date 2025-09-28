local M = {}

-- Core JDTLS operations
function M.organize_imports()
  require("jdtls").organize_imports()
end

function M.extract_variable()
  require("jdtls").extract_variable()
end

function M.extract_variable_visual()
  require("jdtls").extract_variable(true)
end

function M.extract_constant()
  require("jdtls").extract_constant()
end

function M.extract_constant_visual()
  require("jdtls").extract_constant(true)
end

function M.extract_method_visual()
  require("jdtls").extract_method(true)
end

-- Testing
function M.test_class()
  require("jdtls").test_class()
end

function M.test_nearest_method()
  require("jdtls").test_nearest_method()
end

-- Code generation via LSP code actions
function M.generate_getters_setters()
  vim.lsp.buf.code_action({
    filter = function(action)
      return string.match(action.title, "Generate.*getter.*setter") or
             string.match(action.title, "Generate.*Getter.*Setter")
    end,
    apply = true
  })
end

-- Setup buffer-local keymaps for Java files
function M.setup_keymaps()
  local map = vim.keymap.set
  local opts = { buffer = true, silent = true }

  -- Core JDTLS operations
  map("n", "<leader>jo", M.organize_imports, vim.tbl_extend("force", opts, { desc = "Organize Java imports" }))
  map("n", "<leader>jv", M.extract_variable, vim.tbl_extend("force", opts, { desc = "Extract variable" }))
  map("v", "<leader>jv", M.extract_variable_visual, vim.tbl_extend("force", opts, { desc = "Extract variable (visual)" }))
  map("n", "<leader>jk", M.extract_constant, vim.tbl_extend("force", opts, { desc = "Extract constant" }))
  map("v", "<leader>jk", M.extract_constant_visual, vim.tbl_extend("force", opts, { desc = "Extract constant (visual)" }))
  map("v", "<leader>jm", M.extract_method_visual, vim.tbl_extend("force", opts, { desc = "Extract method (visual)" }))

  -- Testing
  map("n", "<leader>jtf", M.test_class, vim.tbl_extend("force", opts, { desc = "Test Java class" }))
  map("n", "<leader>jtn", M.test_nearest_method, vim.tbl_extend("force", opts, { desc = "Test nearest Java method" }))

  -- Code generation via LSP code actions
  map("n", "<leader>jg", M.generate_getters_setters, vim.tbl_extend("force", opts, { desc = "Generate getters/setters" }))
end

return M