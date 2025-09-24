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
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")
vim.opt.colorcolumn = "80"
vim.opt.laststatus = 3
vim.g.lazyvim_markdown = false
vim.opt.conceallevel = 2
vim.opt.shellslash = true
vim.g.lazyvim_blink_main = false

-- Ensure mise environment is available to Neovim
local function setup_mise_env()
  -- Add mise bin directory to PATH
  local mise_bin = vim.fn.expand("~/.local/share/mise/shims")
  if vim.fn.isdirectory(mise_bin) == 1 then
    vim.env.PATH = mise_bin .. ":" .. (vim.env.PATH or "")
  end

  -- Try to detect JAVA_HOME from mise
  local handle = io.popen("mise current java 2>/dev/null")
  if handle then
    local java_version = handle:read("*a"):gsub("%s+", "")
    handle:close()
    if java_version and java_version ~= "" and java_version ~= "No current java version in mise" then
      local java_path = vim.fn.expand("~/.local/share/mise/installs/java/" .. java_version)
      if vim.fn.isdirectory(java_path) == 1 then
        vim.env.JAVA_HOME = java_path
      end
    end
  end
end

setup_mise_env()

-- -- Terminal setup
-- local function setup_terminal()
--   local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
--   if is_windows then
--     vim.opt.shell = [["C:/Program Files/Git/bin/bash.exe"]]
--     vim.opt.shellcmdflag = "-c"
--     vim.opt.shellxquote = ""
--   else
--     vim.opt.shell = "/bin/zsh"
--     vim.opt.shellcmdflag = "-c"
--     vim.opt.shellquote = ""
--     vim.opt.shellxquote = ""
--     -- Fix PATH for shell commands
--     vim.env.PATH =
--       "/home/ghost-desktop/.local/bin:/home/ghost/.opencode/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/var/lib/flatpak/exports/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/usr/bin/nvim:/home/ghost-desktop/go/bin:/usr/bin"
--   end
-- end
--
-- setup_terminal()
