local function toggle_split_zoom_tab()
  if vim.t.split_zoom_tab then
    vim.cmd.tabclose()
    return
  end

  if vim.fn.winnr("$") == 1 then
    vim.notify("No split to expand", vim.log.levels.INFO)
    return
  end

  vim.cmd("tab split")
  vim.t.split_zoom_tab = true
end

return {
  "LazyVim/LazyVim",
  keys = {
    { "<leader>m", toggle_split_zoom_tab, desc = "Toggle split maximize tab" },
  },
}
