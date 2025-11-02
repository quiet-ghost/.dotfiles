-- Function to read environment variables from ~/.env.private
local function load_env_file()
  local env_file = vim.fn.expand("~/.env.private")
  local env_vars = {}

  if vim.fn.filereadable(env_file) == 1 then
    for line in io.lines(env_file) do
      local key, value = line:match("^export%s+([%w_]+)%s*=%s*[\"']?([^\"']*)[\"']?")
      if key and value then
        env_vars[key] = value
      end
    end
  end

  return env_vars
end

local env = load_env_file()

return {
  "yetone/avante.nvim",
  build = function()
    if vim.fn.has("win32") == 1 then
      return "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
    else
      return "make"
    end
  end,
  event = "VeryLazy",
  version = false,
  ---@module 'avante'
  ---@type avante.Config
  opts = {
    provider = "claude",
    providers = {
      claude = {
        endpoint = "https://api.anthropic.com",
        api_key = env.ANTHROPIC_API_KEY,
        model = "claude-sonnet-4-20250514",
        timeout = 30000,
        extra_request_body = {
          temperature = 0.75,
          max_tokens = 20480,
        },
      },
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-mini/mini.pick",
    "nvim-telescope/telescope.nvim",
    "hrsh7th/nvim-cmp",
    "ibhagwan/fzf-lua",
    "stevearc/dressing.nvim",
    "folke/snacks.nvim",
    "nvim-tree/nvim-web-devicons",
    "zbirenbaum/copilot.lua",
    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = false,
          },
          use_absolute_path = true,
        },
      },
    },
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
