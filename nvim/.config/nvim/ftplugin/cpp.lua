-- C++ LSP configuration
if vim.bo.filetype == "cpp" or vim.bo.filetype == "c" then
  -- Basic C++ setup
  vim.opt_local.cindent = true
  vim.opt_local.tabstop = 2
  vim.opt_local.shiftwidth = 2
  vim.opt_local.expandtab = true
  
  -- Comment strings for C++
  vim.opt_local.commentstring = "// %s"
end