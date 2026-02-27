vim.api.nvim_create_user_command("TmuxSwitch", function(opts)
  vim.fn.system("tmux switch-client -t " .. opts.args)
end, { nargs = 1, desc = "Switch to tmux session" })

vim.api.nvim_create_user_command("JavaFX", function()
  require("utils.javafx").insert_template()
end, { desc = "Insert JavaFX template" })

vim.api.nvim_create_user_command("CppPrototypeToHeader", function()
  require("utils.cpp_header").prototype_to_header()
end, { desc = "Add C++ prototype to matching header" })

vim.api.nvim_create_user_command("CppNewPair", function(opts)
  require("utils.cpp_project").new_pair(opts.args)
end, { nargs = 1, desc = "Create C++ .h/.cpp pair" })

vim.api.nvim_create_user_command("CppNewPairPrompt", function()
  require("utils.cpp_project").new_pair_prompt()
end, { desc = "Prompt to create C++ .h/.cpp pair" })
