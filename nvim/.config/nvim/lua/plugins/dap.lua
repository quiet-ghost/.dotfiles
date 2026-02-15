return {
  "mfussenegger/nvim-dap",
  cmd = {
    "DapContinue",
    "DapStepOver",
    "DapStepInto",
    "DapStepOut",
    "DapTerminate",
    "DapUIToggle",
    "DapToggleBreakpoint",
  },
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "theHamsta/nvim-dap-virtual-text",
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")
    local uv = vim.uv or vim.loop

    local function path_join(...)
      local joined = table.concat({ ... }, "/")
      return (joined:gsub("//+", "/"))
    end

    local function is_executable_file(path)
      if not path or path == "" then
        return false
      end
      local stat = uv.fs_stat(path)
      return stat and stat.type == "file" and vim.fn.executable(path) == 1
    end

    local function project_root()
      if vim.fs and vim.fs.root then
        return vim.fs.root(0, { "CMakeLists.txt", "Makefile", ".git" }) or vim.fn.getcwd()
      end
      return vim.fn.getcwd()
    end

    local function list_executables(dir, max_results)
      local results = {}
      local limit = max_results or 150

      local function walk(current, depth)
        if #results >= limit or depth > 5 then
          return
        end

        local fs = uv.fs_scandir(current)
        if not fs then
          return
        end

        while #results < limit do
          local name, entry_type = uv.fs_scandir_next(fs)
          if not name then
            break
          end

          local full_path = path_join(current, name)
          if entry_type == "directory" then
            if name ~= "CMakeFiles" and name ~= ".git" and name ~= ".cache" then
              walk(full_path, depth + 1)
            end
          elseif entry_type == "file" and is_executable_file(full_path) then
            if not full_path:match("%.so$") and not full_path:match("%.a$") then
              table.insert(results, full_path)
            end
          end
        end
      end

      walk(dir, 1)
      return results
    end

    local debug_symbol_cache = {}
    local function has_debug_symbols(path)
      if not is_executable_file(path) then
        return false
      end

      if debug_symbol_cache[path] ~= nil then
        return debug_symbol_cache[path]
      end

      local ok = false
      if vim.fn.executable("readelf") == 1 then
        local out = vim.fn.system({ "readelf", "--sections", path })
        ok = out:find(".debug_info", 1, true) ~= nil or out:find(".zdebug_info", 1, true) ~= nil
      end

      debug_symbol_cache[path] = ok
      return ok
    end

    local function choose_best_executable(paths, basename, project_name)
      local best_path = nil
      local best_score = -math.huge
      local best_mtime = -math.huge

      for _, path in ipairs(paths) do
        local score = 0
        if path:match("/" .. vim.pesc(basename) .. "$") then
          score = score + 100
        end
        if path:match("/" .. vim.pesc(project_name) .. "$") then
          score = score + 90
        end
        if path:match("/build/") or path:match("/cmake%-build") then
          score = score + 30
        end
        if path:match("/tests?/") then
          score = score - 10
        end
        if has_debug_symbols(path) then
          score = score + 80
        else
          score = score - 40
        end

        local stat = uv.fs_stat(path)
        local mtime = stat and stat.mtime and (stat.mtime.sec or 0) or 0

        if score > best_score or (score == best_score and mtime > best_mtime) then
          best_score = score
          best_mtime = mtime
          best_path = path
        end
      end

      return best_path
    end

    local function resolve_cpp_program()
      local cwd = vim.fn.getcwd()
      local root = project_root()
      local file_dir = vim.fn.expand("%:p:h")
      local basename = vim.fn.expand("%:t:r")
      local build_dirs = {
        "build",
        "cmake-build-debug",
        "cmake-build-relwithdebinfo",
        "cmake-build-release",
      }

      local remembered = vim.g.cpp_last_executable or vim.g.dap_cpp_last_executable
      if is_executable_file(remembered) then
        vim.notify("DAP executable: " .. remembered, vim.log.levels.INFO)
        return remembered
      end

      local roots = {}
      local seen_roots = {}
      local function add_root(path)
        if path and path ~= "" and not seen_roots[path] then
          seen_roots[path] = true
          table.insert(roots, path)
        end
      end

      add_root(cwd)
      add_root(root)
      add_root(file_dir)

      local scan_dir = file_dir
      for _ = 1, 6 do
        if not scan_dir or scan_dir == "" then
          break
        end

        for _, build_dir in ipairs(build_dirs) do
          local build_path = path_join(scan_dir, build_dir)
          local stat = uv.fs_stat(build_path)
          if stat and stat.type == "directory" then
            add_root(scan_dir)
            break
          end
        end

        local parent = vim.fn.fnamemodify(scan_dir, ":h")
        if parent == scan_dir then
          break
        end
        scan_dir = parent
      end

      local seen = {}
      local direct_candidates = {}
      local function add_candidate(path)
        if path and path ~= "" and not seen[path] then
          seen[path] = true
          table.insert(direct_candidates, path)
        end
      end

      for _, current_root in ipairs(roots) do
        local project_name = vim.fn.fnamemodify(current_root, ":t")
        add_candidate(path_join(current_root, basename))
        add_candidate(path_join(current_root, project_name))
        add_candidate(path_join(current_root, "a.out"))

        for _, build_dir in ipairs(build_dirs) do
          add_candidate(path_join(current_root, build_dir, basename))
          add_candidate(path_join(current_root, build_dir, project_name))
        end
      end

      local executable_candidates = {}
      for _, candidate in ipairs(direct_candidates) do
        if is_executable_file(candidate) then
          table.insert(executable_candidates, candidate)
        end
      end

      if #executable_candidates == 0 then
        for _, current_root in ipairs(roots) do
          for _, build_dir in ipairs(build_dirs) do
            local abs_dir = path_join(current_root, build_dir)
            local stat = uv.fs_stat(abs_dir)
            if stat and stat.type == "directory" then
              vim.list_extend(executable_candidates, list_executables(abs_dir))
            end
          end
        end
      end

      local selected = choose_best_executable(executable_candidates, basename, vim.fn.fnamemodify(cwd, ":t"))
      if selected then
        vim.g.cpp_last_executable = selected
        vim.g.dap_cpp_last_executable = selected
        if not has_debug_symbols(selected) then
          vim.notify("Selected executable has no debug symbols: " .. selected, vim.log.levels.WARN)
        end
        vim.notify("DAP executable: " .. selected, vim.log.levels.INFO)
        return selected
      end

      local manual = vim.fn.input("Path to executable: ", path_join(cwd, "build/"), "file")
      local resolved = vim.fn.fnamemodify(vim.fn.expand(manual), ":p")
      if is_executable_file(resolved) then
        vim.g.cpp_last_executable = resolved
        vim.g.dap_cpp_last_executable = resolved
        if not has_debug_symbols(resolved) then
          vim.notify("Executable has no debug symbols: " .. resolved, vim.log.levels.WARN)
        end
      end
      return resolved
    end

    local function cpp_source_map()
      local map = {}
      local seen = {}

      local function add_mapping(from_path, to_path)
        if not from_path or not to_path or from_path == "" or to_path == "" or from_path == to_path then
          return
        end
        local key = from_path .. "->" .. to_path
        if seen[key] then
          return
        end
        seen[key] = true
        map[from_path] = to_path
      end

      local candidates = {
        vim.fn.getcwd(),
        project_root(),
        vim.fn.expand("%:p:h"),
      }

      for _, path in ipairs(candidates) do
        local real = uv.fs_realpath(path)
        if real and real ~= path then
          add_mapping(real, path)
          add_mapping(path, real)
        end
      end

      if next(map) then
        return map
      end
      return nil
    end

    local function setup_codelldb_adapter()
      local codelldb = vim.fn.exepath("codelldb")
      if codelldb == "" then
        codelldb = "codelldb"
      end

      dap.adapters.codelldb = {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = {
          command = codelldb,
          args = { "--port", "${port}" },
          detached = false,
        },
      }

      for _, lang in ipairs({ "c", "cpp" }) do
        dap.configurations[lang] = {
          {
            type = "codelldb",
            request = "launch",
            name = "Launch (auto-detect binary)",
            program = resolve_cpp_program,
            cwd = function()
              return vim.fn.getcwd()
            end,
            sourceMap = cpp_source_map,
            stopOnEntry = false,
          },
          {
            type = "codelldb",
            request = "attach",
            name = "Attach to process",
            pid = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
        }
      end
    end

    setup_codelldb_adapter()

    dapui.setup()

    require("nvim-dap-virtual-text").setup({
      enabled = true, -- Enable the plugin
      enabled_commands = true, -- Create commands like :DapVirtualTextEnable
      highlight_changed_variables = true, -- Highlight changed variables
      highlight_new_as_changed = true, -- Highlight new variables as changed
      show_stop_reason = true, -- Show why DAP stopped (e.g., breakpoint)
      commented = false, -- Show virtual text as comments (e.g., // value)
      virt_text_pos = "eol", -- Position of virtual text ("eol" or "inline")
      all_frames = false, -- Show virtual text for all stack frames
      virt_lines = false, -- Use virtual lines instead of virtual text
      virt_text_win_col = nil, -- Set to a number to fix column position
    })

    vim.api.nvim_set_hl(0, "NvimDapVirtualText", { fg = "#c53737", italic = true })
    vim.api.nvim_set_hl(0, "NvimDapVirtualTextChanged", { fg = "#c53737", italic = true, bold = true })

    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end

    dap.listeners.before.event_terminated.dapui_config = function()
      -- Intentionally empty - prevents auto-close
    end
    dap.listeners.before.event_exited.dapui_config = function()
      -- Intentionally empty - prevents auto-close
    end
    dap.listeners.after.event_terminated.dapui_config = function()
      -- Intentionally empty - prevents auto-close
    end
    dap.listeners.after.event_exited.dapui_config = function()
      -- Intentionally empty - prevents auto-close
    end

    -- Refresh virtual text when debugger stops at breakpoint
    dap.listeners.after.event_stopped.dap_virtual_text = function()
      require("nvim-dap-virtual-text").refresh()
    end

    dap.configurations.java = {
      {
        type = "java",
        request = "launch",
        name = "Launch Current File",
      },
    }
  end,
}
