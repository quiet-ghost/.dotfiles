vim.api.nvim_create_user_command("TmuxSwitch", function(opts)
  vim.fn.system("tmux switch-client -t " .. opts.args)
end, { nargs = 1, desc = "Switch to tmux session" })

vim.api.nvim_create_user_command("JavaFX", function()
  require("utils.javafx").insert_template()
end, { desc = "Insert JavaFX template" })
