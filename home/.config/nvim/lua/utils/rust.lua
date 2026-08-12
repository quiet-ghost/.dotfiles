local M = {}
local mux = require("utils.mux")

local config = {
  edition = "2024",
  pane_sizes = {
    cargo = 30,
    single_file = 30,
  },
  title_formats = {
    cargo = "cargo: %s",
    cargo_test = "cargo test: %s",
    single_file = "rust: %s",
  },
}

local function find_file_upwards(filename, start_dir)
  local dir = start_dir
  local home = vim.fn.expand("~")

  while dir and dir ~= "" and dir ~= "/" and dir ~= home do
    local file_path = dir .. "/" .. filename
    if vim.fn.filereadable(file_path) == 1 then
      return dir, file_path
    end

    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end

  return nil, nil
end

local function relative_path(path, root)
  local normalized_path = path:gsub("\\", "/")
  local normalized_root = root:gsub("\\", "/")
  local prefix = normalized_root:sub(-1) == "/" and normalized_root or (normalized_root .. "/")

  if normalized_path:sub(1, #prefix) == prefix then
    return normalized_path:sub(#prefix + 1)
  end

  return vim.fn.fnamemodify(path, ":t")
end

local function run_in_split(command, pane_size, title, cwd)
  return mux.run_in_split({
    command = command,
    title = title,
    cwd = cwd or vim.fn.getcwd(),
    percent = pane_size,
    direction = "right",
  })
end

local function find_single_bin(root)
  local bin_files = vim.fn.glob(root .. "/src/bin/*.rs", false, true)
  if #bin_files == 1 then
    return vim.fn.fnamemodify(bin_files[1], ":t:r")
  end

  return nil
end

local function cargo_command_for_file(root, file)
  local rel_path = relative_path(file, root)

  if rel_path == "src/main.rs" then
    return "cargo run", false
  end

  local bin_name = rel_path:match("^src/bin/([^/]+)%.rs$")
  if bin_name then
    return "cargo run --bin " .. vim.fn.shellescape(bin_name), false
  end

  local example_name = rel_path:match("^examples/([^/]+)%.rs$")
  if example_name then
    return "cargo run --example " .. vim.fn.shellescape(example_name), false
  end

  if vim.fn.filereadable(root .. "/src/main.rs") == 1 then
    return "cargo run", false
  end

  local single_bin = find_single_bin(root)
  if single_bin then
    return "cargo run --bin " .. vim.fn.shellescape(single_bin), false
  end

  return "cargo test", true
end

local function run_cargo_project(root, file)
  if vim.fn.executable("cargo") ~= 1 then
    vim.notify("cargo not found. Install Rust/Cargo before running this project.", vim.log.levels.ERROR)
    return
  end

  local command, is_test = cargo_command_for_file(root, file)
  local project_name = vim.fn.fnamemodify(root, ":t")
  local title_format = is_test and config.title_formats.cargo_test or config.title_formats.cargo
  local title = string.format(title_format, project_name)

  run_in_split(command, config.pane_sizes.cargo, title, root)

  if is_test then
    vim.notify("Cargo library detected - running tests: " .. project_name, vim.log.levels.INFO)
  else
    vim.notify("Running Cargo project: " .. project_name, vim.log.levels.INFO)
  end
end

local function run_single_file(file, filename, basename, dir)
  if vim.fn.executable("rustc") ~= 1 then
    vim.notify("rustc not found. Install Rust before running this file.", vim.log.levels.ERROR)
    return
  end

  local build_dir = dir .. "/build"
  if vim.fn.isdirectory(build_dir) == 0 then
    vim.fn.mkdir(build_dir, "p")
  end

  local output = build_dir .. "/" .. basename
  local compile_cmd = string.format(
    "rustc --edition=%s -g %s -o %s",
    vim.fn.shellescape(config.edition),
    vim.fn.shellescape(file),
    vim.fn.shellescape(output)
  )
  local run_cmd = vim.fn.shellescape(output)
  local title = string.format(config.title_formats.single_file, filename)

  run_in_split(compile_cmd .. " && " .. run_cmd, config.pane_sizes.single_file, title, dir)
  vim.notify("Compiling and running Rust file: " .. filename, vim.log.levels.INFO)
end

function M.compile_and_run()
  local file = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t")
  local basename = vim.fn.expand("%:t:r")
  local dir = vim.fn.expand("%:p:h")

  if not filename:match("%.rs$") then
    vim.notify("Not a Rust file!", vim.log.levels.ERROR)
    return
  end

  vim.cmd("write")

  if not mux.ensure() then
    return
  end

  local cargo_root = find_file_upwards("Cargo.toml", dir)
  if cargo_root then
    run_cargo_project(cargo_root, file)
    return
  end

  run_single_file(file, filename, basename, dir)
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

return M
