local function apply_python_path(config, python_path, root)
  if not python_path or python_path == "" then
    return
  end

  config.settings = config.settings or {}
  config.settings.python = config.settings.python or {}
  config.settings.python.pythonPath = python_path

  local venv_dir = vim.fn.fnamemodify(python_path, ":h:h")
  local venv_name = vim.fn.fnamemodify(venv_dir, ":t")
  local venv_parent = vim.fn.fnamemodify(venv_dir, ":h")

  if vim.fn.isdirectory(venv_dir) == 1 then
    config.settings.python.venv = venv_name
    config.settings.python.venvPath = venv_parent
  end

  config.cmd_env = vim.tbl_deep_extend("force", config.cmd_env or {}, {
    VIRTUAL_ENV = venv_dir,
    PATH = vim.fn.fnamemodify(python_path, ":h") .. ":" .. (vim.env.PATH or ""),
  })

  if root and root ~= "" then
    config.settings.python.analysis = config.settings.python.analysis or {}
    local extra = config.settings.python.analysis.extraPaths or {}
    if not vim.tbl_contains(extra, root) then
      table.insert(extra, 1, root)
    end
    config.settings.python.analysis.extraPaths = extra
  end
end

local function configure_python_lsp(_, config)
  local root = config.root_dir or vim.fn.getcwd()
  local ok, python_util = pcall(require, "utils.python")
  if not ok then
    return
  end

  local python_path = python_util.resolve_interpreter(root)
  if python_path then
    apply_python_path(config, python_path, root)
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      local function with_python(server)
        opts.servers[server] = vim.tbl_deep_extend("force", opts.servers[server] or {}, {
          before_init = configure_python_lsp,
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                diagnosticMode = "workspace",
                useLibraryCodeForTypes = true,
                autoImportCompletions = true,
              },
            },
          },
        })
      end

      with_python("pyright")
      with_python("basedpyright")
    end,
  },
  {
    "linux-cultist/venv-selector.nvim",
    opts = {
      options = {
        notify_user_on_venv_activation = true,
        cached_venv_automatic_activation = true,
        enable_cached_venvs = true,
      },
    },
  },
}
