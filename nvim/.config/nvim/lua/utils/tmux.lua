local M = {}

function M.session_manager()
  require("telescope").extensions.mux_manager.sessions()
end

return M