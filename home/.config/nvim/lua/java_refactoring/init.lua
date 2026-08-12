local M = {}

-- Main entry point for refactor menu
function M.show_refactor_menu()
  -- Currently only Extract Interface is implemented
  -- This can be expanded with more refactoring options later
  require("java_refactoring.extract_interface").extract()
end

return M
