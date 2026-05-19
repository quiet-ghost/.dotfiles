local function rust_root(filename)
  local marker = vim.fs.find({ "Cargo.toml", "rust-project.json", ".git" }, {
    path = filename,
    upward = true,
  })[1]

  if marker then
    return vim.fs.dirname(marker)
  end

  return vim.fs.dirname(filename)
end

local function start_rust_analyzer(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == "" or vim.bo[bufnr].filetype ~= "rust" or vim.fn.executable("rust-analyzer") ~= 1 then
    return
  end

  if #vim.lsp.get_clients({ bufnr = bufnr, name = "rust-analyzer" }) > 0 then
    return
  end

  vim.lsp.start({
    name = "rust-analyzer",
    cmd = { "rust-analyzer" },
    root_dir = rust_root(filename),
    filetypes = { "rust" },
    init_options = {
      detachedFiles = { filename },
    },
  }, { bufnr = bufnr })
end

vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = true, desc = "Hover Documentation" })

vim.defer_fn(function()
  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if #vim.lsp.get_clients({ bufnr = bufnr, name = "rust-analyzer" }) > 0 then
    return
  end

  local ok = pcall(function()
    require("rustaceanvim.lsp").start(bufnr)
  end)

  if ok then
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        start_rust_analyzer(bufnr)
      end
    end, 500)
    return
  end

  start_rust_analyzer(bufnr)
end, 100)
