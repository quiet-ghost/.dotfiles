local M = {}

local function notify_error(message)
  vim.notify(message, vim.log.levels.ERROR)
end

local function run_system(args)
  local output = vim.fn.system(args)
  local status = vim.v.shell_error
  return status == 0, output, status
end

local function decode_json(output)
  local ok, decoded = pcall(vim.json.decode, output)
  if ok then
    return decoded
  end
  return nil
end

local function command_error(label, output)
  local detail = vim.trim(output or "")
  if detail == "" then
    return label
  end
  return label .. ": " .. detail
end

function M.backend()
  if vim.env.HERDR_ENV == "1" then
    return "herdr"
  end

  if vim.env.TMUX and vim.env.TMUX ~= "" then
    return "tmux"
  end

  return nil
end

function M.ensure()
  if M.backend() then
    return true
  end

  notify_error("Not in tmux or herdr! Run from a multiplexer terminal instead.")
  return false
end

function M.current_pane_id()
  local backend = M.backend()
  if backend == "tmux" then
    local ok, output = run_system({ "tmux", "display-message", "-p", "#{pane_id}" })
    if ok then
      local pane_id = vim.trim(output)
      return pane_id ~= "" and pane_id or nil
    end
    return nil
  end

  if backend == "herdr" then
    if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
      return vim.env.HERDR_PANE_ID
    end

    local ok, output = run_system({ "herdr", "pane", "current" })
    if not ok then
      return nil
    end
    local response = decode_json(output)
    return response and response.result and response.result.pane and response.result.pane.pane_id or nil
  end

  return nil
end

---Create a new multiplexer pane.
---@param opts table direction: "right"|"down", percent, cwd, focus, target_pane
---@return string|nil pane_id
function M.split(opts)
  opts = opts or {}
  local backend = M.backend()
  local direction = opts.direction == "down" and "down" or "right"
  local percent = math.max(1, math.min(99, tonumber(opts.percent) or 20))
  local focus = opts.focus ~= false

  if backend == "tmux" then
    local args = {
      "tmux",
      "split-window",
      direction == "down" and "-v" or "-h",
      "-p",
      tostring(math.floor(percent + 0.5)),
      "-P",
      "-F",
      "#{pane_id}",
    }
    if opts.target_pane then
      vim.list_extend(args, { "-t", opts.target_pane })
    end
    if opts.cwd and opts.cwd ~= "" then
      vim.list_extend(args, { "-c", opts.cwd })
    end
    if not focus then
      table.insert(args, "-d")
    end

    local ok, output = run_system(args)
    if not ok then
      notify_error(command_error("Failed to create tmux pane", output))
      return nil
    end

    local pane_id = vim.trim(output)
    return pane_id ~= "" and pane_id or nil
  end

  if backend == "herdr" then
    local args = { "herdr", "pane", "split" }
    if opts.target_pane then
      table.insert(args, opts.target_pane)
    else
      table.insert(args, "--current")
    end
    vim.list_extend(args, {
      "--direction",
      direction,
      "--ratio",
      -- tmux -p sizes the new pane; herdr's ratio sizes the existing pane.
      string.format("%.2f", (100 - percent) / 100),
    })
    if opts.cwd and opts.cwd ~= "" then
      vim.list_extend(args, { "--cwd", opts.cwd })
    end
    table.insert(args, focus and "--focus" or "--no-focus")

    local ok, output = run_system(args)
    if not ok then
      notify_error(command_error("Failed to create herdr pane", output))
      return nil
    end

    local response = decode_json(output)
    local pane = response and response.result and response.result.pane
    local pane_id = pane and pane.pane_id
    if not pane_id or pane_id == "" then
      notify_error("Herdr created a pane but did not return its pane id")
      return nil
    end
    return pane_id
  end

  notify_error("Not in tmux or herdr! Run from a multiplexer terminal instead.")
  return nil
end

local function wait_for_herdr_shell(pane_id)
  return vim.wait(1500, function()
    local ok, output = run_system({ "herdr", "pane", "process-info", "--pane", pane_id })
    if not ok then
      return false
    end
    local response = decode_json(output)
    local info = response and response.result and response.result.process_info
    return info and info.shell_pid ~= nil
  end, 25)
end

---Submit a shell command to an existing pane.
---@param pane_id string
---@param command string
---@return boolean
function M.run(pane_id, command)
  local backend = M.backend()
  if not pane_id or pane_id == "" then
    notify_error("Cannot run command without a pane id")
    return false
  end

  local args
  if backend == "tmux" then
    args = { "tmux", "send-keys", "-t", pane_id, command, "Enter" }
  elseif backend == "herdr" then
    if not wait_for_herdr_shell(pane_id) then
      notify_error("Herdr pane shell did not become ready: " .. pane_id)
      return false
    end
    args = { "herdr", "pane", "run", pane_id, command }
  else
    notify_error("Not in tmux or herdr! Run from a multiplexer terminal instead.")
    return false
  end

  local ok, output = run_system(args)
  if not ok then
    notify_error(command_error("Failed to run command in " .. backend .. " pane", output))
  end
  return ok
end

function M.focus_pane(pane_id)
  if M.backend() == "tmux" then
    local ok = run_system({ "tmux", "select-pane", "-t", pane_id })
    return ok
  end

  -- Herdr splits can be created with --no-focus, which is more reliable than
  -- trying to navigate back to a pane after creating a nested layout.
  return M.backend() == "herdr" and pane_id == M.current_pane_id()
end

local function wrapped_command(opts)
  local body = opts.command
  if opts.title and opts.title ~= "" then
    body = string.format("echo %s && echo '' && %s", vim.fn.shellescape("--- " .. opts.title .. " ---"), body)
  end
  if opts.cwd and opts.cwd ~= "" then
    body = string.format("cd %s && %s", vim.fn.shellescape(opts.cwd), body)
  end
  if opts.wait_for_enter ~= false then
    -- split() starts an interactive shell in both backends. Exit that shell
    -- after Enter so the temporary pane closes, matching tmux's old behavior.
    body = body .. "; echo ''; echo 'Press Enter to close...'; read; exit"
  end
  return body
end

---Create a split and run a command with the standard runner UI.
---@param opts table command, cwd, title, percent, direction, focus, wait_for_enter
---@return boolean, string|nil
function M.run_in_split(opts)
  opts = opts or {}
  if not M.ensure() then
    return false, nil
  end
  if not opts.command or opts.command == "" then
    notify_error("Cannot create runner pane without a command")
    return false, nil
  end

  local pane_id = M.split({
    direction = opts.direction,
    percent = opts.percent,
    cwd = opts.cwd,
    focus = opts.focus,
    target_pane = opts.target_pane,
  })
  if not pane_id then
    return false, nil
  end

  if opts.title and opts.title ~= "" and M.backend() == "herdr" then
    -- This is cosmetic; command output still has the title if rename fails.
    run_system({ "herdr", "pane", "rename", pane_id, opts.title })
  end

  local ok = M.run(pane_id, wrapped_command(opts))
  return ok, pane_id
end

return M
