vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.showmode = false
vim.opt.clipboard = "unnamedplus"
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 50
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split"
vim.opt.cursorline = false
vim.opt.scrolloff = 8
vim.opt.smoothscroll = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.isfname:append("@-@")
vim.opt.colorcolumn = "80"
vim.opt.laststatus = 3
vim.g.lazyvim_markdown = false
vim.opt.conceallevel = 2
vim.g.lazyvim_blink_main = false

-- Ensure mise environment is available to Neovim
local function setup_mise_env()
  if vim.fn.executable("mise") ~= 1 then
    return
  end

  local function read_cmd(cmd)
    local out = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      return ""
    end
    return vim.trim(out)
  end

  local function prepend_path(path)
    if vim.fn.isdirectory(path) == 1 then
      local segments = vim.split(vim.env.PATH or "", ":", { plain = true, trimempty = true })
      local filtered = {}
      for _, segment in ipairs(segments) do
        if segment ~= path then
          table.insert(filtered, segment)
        end
      end
      table.insert(filtered, 1, path)
      vim.env.PATH = table.concat(filtered, ":")
    end
  end

  local mise_shims = vim.fn.expand("~/.local/share/mise/shims")
  prepend_path(mise_shims)

  local go_root = read_cmd({ "mise", "where", "go" })
  if go_root ~= "" then
    prepend_path(go_root .. "/bin")
  end

  if not vim.env.JAVA_HOME or vim.env.JAVA_HOME == "" then
    local java_home = read_cmd({ "mise", "where", "java" })
    if java_home ~= "" and vim.fn.isdirectory(java_home) == 1 then
      vim.env.JAVA_HOME = java_home
    end
  end
end

setup_mise_env()

if vim.fn.has("nvim-0.12") == 1 then
  require("vim._core.ui2").enable({
    enable = true,
  })
end
