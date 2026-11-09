-- Shared workspaces 1-10 across all monitors, replacing Omarchy's per-monitor
-- blocks ($OMARCHY_PATH/default/hypr/monitor-workspaces.lua, where each monitor
-- gets 1-10, 11-20, ...). Omarchy has no switch for that module, so
-- hyprland.lua installs this one under its name before Omarchy loads.
--
-- It keeps the same API, so Omarchy's SUPER + 1-0 bindings and the bar's
-- workspace widget keep working, but they act on plain workspace numbers.
-- Which monitor a workspace lives on comes from hl.workspace_rule in the
-- host's monitors_local.lua. Unlike Omarchy's module, this never renumbers or
-- moves workspaces on its own.
--
-- Recheck this API after Omarchy updates that touch monitor-workspaces.lua.

local paths = require("default.hypr.paths")

local STATE_DIR = paths.state_home .. "/omarchy"
local STATE_FILE = STATE_DIR .. "/monitor-workspaces"

local M = { slots = 10 }

-- The keybindings menu replays a bind through this expression.
local function action(fn, expression)
	o.bind_expressions[fn] = expression
	return fn
end

-- The bar's workspace widget maps each connector to a block of ten from this
-- file. Put every monitor on block 0 so each bar shows workspaces 1-10.
local written = nil

local function write_blocks(gone)
	local lines = {}
	for _, monitor in ipairs(hl.get_monitors()) do
		if monitor.name ~= gone and not monitor.is_mirror then
			local description = monitor.description or ""
			lines[#lines + 1] = "0\t" .. monitor.name .. "\t" .. (description ~= "" and description or monitor.name) .. "\n"
		end
	end
	local content = table.concat(lines)

	if content == written then
		return
	end

	local file = io.open(STATE_FILE, "w")
	if not file then
		os.execute("mkdir -p " .. o.shell_quote(STATE_DIR))
		file = io.open(STATE_FILE, "w")
	end

	if file then
		file:write(content)
		file:close()
		written = content
	end
end

function M.workspace_id(_, slot)
	return slot
end

-- `monitor_name` is accepted for the bar's calls and ignored: workspace N is
-- the same workspace on every monitor.
function M.focus(slot)
	return action(function()
		hl.dispatch(hl.dsp.focus({ workspace = tostring(slot) }))
	end, "o.workspaces.focus(" .. slot .. ")")
end

function M.move_window(slot, follow)
	return action(function()
		hl.dispatch(hl.dsp.window.move({ workspace = tostring(slot), follow = follow ~= false }))
	end, "o.workspaces.move_window(" .. slot .. (follow == false and ", false" or "") .. ")")
end

function M.move_to_monitor(direction)
	return action(function()
		-- Hyprland reports a move toward no monitor as an error on screen.
		local target = hl.get_monitor(direction)
		if target then
			hl.dispatch(hl.dsp.workspace.move({ monitor = target.name }))
		end
	end, "o.workspaces.move_to_monitor(" .. string.format("%q", direction) .. ")")
end

function M.move_window_to_monitor(direction)
	return action(function()
		local target = hl.get_monitor(direction)
		if target then
			hl.dispatch(hl.dsp.window.move({ monitor = target.name }))
		end
	end, "o.workspaces.move_window_to_monitor(" .. string.format("%q", direction) .. ")")
end

function M.reconcile(_, gone)
	write_blocks(gone)
end

hl.on("hyprland.start", function()
	write_blocks(nil)
end)

hl.on("config.reloaded", function()
	write_blocks(nil)
end)

hl.on("monitor.added", function()
	write_blocks(nil)
end)

hl.on("monitor.removed", function(monitor)
	write_blocks(monitor and monitor.name)
end)

o.workspaces = M

return M
