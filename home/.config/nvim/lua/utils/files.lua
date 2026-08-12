local M = {}

function M.create_new_file()
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir = current_file ~= "" and vim.fs.dirname(current_file) or vim.fn.getcwd()

  -- Create a centered floating window for input
  local width = 60
  local height = 1
  local buf = vim.api.nvim_create_buf(false, true)

  local ui = vim.api.nvim_list_uis()[1]
  local win_width = ui.width
  local win_height = ui.height

  local col = math.floor((win_width - width) / 2)
  local row = math.floor((win_height - height) / 2)

  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " Create New File ",
    title_pos = "center",
  }

  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Set prompt text
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
  vim.bo[buf].modifiable = true

  -- Start insert mode
  vim.cmd("startinsert")

  -- Set up keymaps for the floating window
  vim.api.nvim_buf_set_keymap(buf, "i", "<CR>", "", {
    callback = function()
      local input = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1]
      vim.api.nvim_win_close(win, true)

      if input and input ~= "" then
        local path = input
        if vim.fn.fnamemodify(path, ":h") == "." then
          path = vim.fs.joinpath(current_dir, path)
        end

        path = vim.fn.fnamemodify(path, ":p")
        vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
        vim.cmd.edit(vim.fn.fnameescape(path))
      end
    end,
    noremap = true,
    silent = true,
  })

  vim.api.nvim_buf_set_keymap(buf, "i", "<Esc>", "", {
    callback = function()
      vim.api.nvim_win_close(win, true)
    end,
    noremap = true,
    silent = true,
  })

  -- Add a placeholder/hint text
  vim.fn.prompt_setprompt(buf, "File name (e.g., src/main.cpp or include/math.h): ")
end

return M
