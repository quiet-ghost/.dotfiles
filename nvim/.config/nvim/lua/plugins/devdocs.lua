return {
  "maskudo/devdocs.nvim",
  lazy = false,
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  cmd = { "DevDocs" },
  keys = {
    {
      "<leader>ho",
      mode = "n",
      "<cmd>DevDocs get<cr>",
      desc = "Get Devdocs (two-step)",
    },
    {
      "<leader>hi",
      mode = "n",
      "<cmd>DevDocs install<cr>",
      desc = "Install Devdocs",
    },
    -- Two-step: select doc → select page (opens in new tab)
    {
      "<leader>hv",
      mode = "n",
      function()
        local devdocs = require("devdocs")
        local installedDocs = devdocs.GetInstalledDocs()
        vim.ui.select(installedDocs, {
          prompt = "Select documentation:",
        }, function(selected)
          if not selected then
            return
          end
          local docDir = devdocs.GetDocDir(selected)
          require("telescope.builtin").find_files({
            cwd = docDir,
            prompt_title = "DevDocs: " .. selected,
            results_title = "Documentation Files",
            preview_title = "Preview",
            attach_mappings = function(_, map)
              local actions = require("telescope.actions")
              -- Override default action to open in new tab
              actions.select_default:replace(function(prompt_bufnr)
                local entry = require("telescope.actions.state").get_selected_entry()
                actions.close(prompt_bufnr)
                vim.cmd("tabedit " .. entry.path)
                vim.bo.readonly = true
                vim.bo.modifiable = false
              end)
              return true
            end,
          })
        end)
      end,
      desc = "Browse Devdocs (two-step)",
    },
    -- Single-step: search all pages from all docs at once
    {
      "<leader>ha",
      mode = "n",
      function()
        local devdocs = require("devdocs")
        local installedDocs = devdocs.GetInstalledDocs()
        
        if #installedDocs == 0 then
          vim.notify("No DevDocs installed. Use <leader>hi to install.", vim.log.levels.WARN)
          return
        end
        
        -- Collect all files from all installed docs
        local all_files = {}
        for _, doc in ipairs(installedDocs) do
          local files = devdocs.GetDoc(doc)
          if files then
            for _, file in ipairs(files) do
              -- Add doc name prefix for better context
              local display_name = file:match("([^/]+)%.md$") or file
              table.insert(all_files, {
                path = file,
                display = doc .. ": " .. display_name,
                doc = doc,
              })
            end
          end
        end
        
        -- Use telescope to browse all docs
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        
        pickers.new({}, {
          prompt_title = "DevDocs: All Documentation",
          finder = finders.new_table({
            results = all_files,
            entry_maker = function(entry)
              return {
                value = entry,
                display = entry.display,
                ordinal = entry.display,
                path = entry.path,
              }
            end,
          }),
          sorter = conf.generic_sorter({}),
          previewer = conf.file_previewer({}),
          attach_mappings = function(prompt_bufnr, map)
            -- Override default action to open in new tab
            actions.select_default:replace(function()
              local selection = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              vim.cmd("tabedit " .. selection.path)
              vim.bo.readonly = true
              vim.bo.modifiable = false
            end)
            return true
          end,
        }):find()
      end,
      desc = "Browse All Devdocs (single-step)",
    },
    {
      "<leader>hd",
      mode = "n",
      "<cmd>DevDocs delete<cr>",
      desc = "Delete Devdoc",
    },
  },
  opts = {
    ensure_installed = {
      "cpp",
      "go",
      "html",
      "dom",
      "http",
      "css",
      "javascript",
      "rust",
      -- some docs such as lua require version number along with the language name
      -- check `DevDocs install` to view the actual names of the docs
      "openjdk~21",
    },
  },
}
