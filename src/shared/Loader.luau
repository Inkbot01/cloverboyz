--!strict

-- Boot loader for side-effect modules. Requires every ModuleScript under a
-- container concurrently — one module yielding (assets, DataStores, remotes)
-- can never stall the rest — then runs an ordered lifecycle over whatever
-- loaded. LoadAll blocks until every module settles or the timeout elapses,
-- so callers get a real "boot finished" point and an honest report.
--
-- What a module gets for free:
--   • Errors surface with a full traceback instead of dying silently in
--     their own thread.
--   • A watchdog names any module still pending after RequireTimeout —
--     the usual culprit is an infinite WaitForChild.
--   • Requires slower than SlowThreshold are called out with their timing.
--
-- Opt-in per module, via attributes on the ModuleScript (set in Studio or a
-- .meta.json, no code changes needed):
--   • LoadDisabled (boolean) — skipped entirely. For TEMP debug modules.
--   • LoadPriority (number, default 0) — higher loads and inits first.
--     Ties break alphabetically so boot order is deterministic.
--
-- Opt-in lifecycle, via fields on the returned table:
--   • OnInit(self)  — runs sequentially in priority order after every
--     module has been required. Must not yield. The sanctioned place for
--     cross-module wiring, since everything is registered by then.
--   • OnStart(self) — spawned on its own thread after all OnInits finish.
--     May yield forever (loops, listeners).
-- Named OnInit/OnStart rather than Init/Start deliberately: modules like
-- Cooldown export a public Start(self) for their own instances, and the
-- loader must never mistake those for lifecycle hooks.
--
-- A module that finishes requiring after the timeout still gets its
-- lifecycle run on arrival; it is just reported as Pending in the summary.

local Loader = {}

export type Options = {
	Descendants: boolean?,
	Exclude: { string }?,
	RequireTimeout: number?,
	SlowThreshold: number?,
}

export type Report = {
	Loaded: { ModuleScript },
	Failed: { ModuleScript },
	Pending: { ModuleScript },
	Duration: number,
}

type Entry = {
	Module: ModuleScript,
	Priority: number,
	State: "Pending" | "Loaded" | "Failed",
	Value: any,
	Duration: number,
	LifecycleRan: boolean,
}

local DEFAULT_REQUIRE_TIMEOUT = 10
local DEFAULT_SLOW_THRESHOLD = 1
local POLL_INTERVAL = 0.05

local loadedContainers: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function gather(container: Instance, options: Options): { Entry }
	local exclude: { [string]: boolean } = {}
	for _, name in options.Exclude or {} do
		exclude[name] = true
	end

	local pool = if options.Descendants then container:GetDescendants() else container:GetChildren()

	local entries: { Entry } = {}
	for _, instance in pool do
		if not instance:IsA("ModuleScript") then
			continue
		end
		if exclude[instance.Name] or instance:GetAttribute("LoadDisabled") == true then
			continue
		end

		local priority = instance:GetAttribute("LoadPriority")
		table.insert(entries, {
			Module = instance,
			Priority = if typeof(priority) == "number" then priority else 0,
			State = "Pending" :: "Pending",
			Value = nil,
			Duration = 0,
			LifecycleRan = false,
		})
	end

	table.sort(entries, function(a, b)
		if a.Priority ~= b.Priority then
			return a.Priority > b.Priority
		end
		return a.Module:GetFullName() < b.Module:GetFullName()
	end)

	return entries
end

local function callLifecycle(entry: Entry)
	if entry.LifecycleRan then
		return
	end
	entry.LifecycleRan = true

	local value = entry.Value
	if typeof(value) ~= "table" then
		return
	end

	if typeof(value.OnInit) == "function" then
		local ok, err = pcall(value.OnInit, value)
		if not ok then
			warn(`[Loader] {entry.Module:GetFullName()}.OnInit failed — {err}`)
			return
		end
	end

	if typeof(value.OnStart) == "function" then
		task.spawn(function()
			local ok, err = pcall(value.OnStart, value)
			if not ok then
				warn(`[Loader] {entry.Module:GetFullName()}.OnStart failed — {err}`)
			end
		end)
	end
end

function Loader.LoadAll(container: Instance, options: Options?): Report
	local opts: Options = options or {}
	local requireTimeout = opts.RequireTimeout or DEFAULT_REQUIRE_TIMEOUT
	local slowThreshold = opts.SlowThreshold or DEFAULT_SLOW_THRESHOLD

	if loadedContainers[container] then
		warn(`[Loader] {container:GetFullName()} was already loaded; skipping`)
		return { Loaded = {}, Failed = {}, Pending = {}, Duration = 0 }
	end
	loadedContainers[container] = true

	local entries = gather(container, opts)
	local startClock = os.clock()
	local settled = 0
	local initPhaseDone = false

	for _, entry in entries do
		task.spawn(function()
			local began = os.clock()
			local ok, result = xpcall(require, function(err)
				return debug.traceback(tostring(err), 2)
			end, entry.Module)

			entry.Duration = os.clock() - began
			if ok then
				entry.State = "Loaded"
				entry.Value = result
			else
				entry.State = "Failed"
				warn(`[Loader] {entry.Module:GetFullName()} failed to load —\n{result}`)
			end
			settled += 1

			-- A straggler that lands after the init phase already ran still
			-- gets its lifecycle, just late and on its own thread.
			if initPhaseDone and entry.State == "Loaded" then
				callLifecycle(entry)
			end
		end)
	end

	local deadline = startClock + requireTimeout
	while settled < #entries and os.clock() < deadline do
		task.wait(POLL_INTERVAL)
	end

	local report: Report = {
		Loaded = {},
		Failed = {},
		Pending = {},
		Duration = os.clock() - startClock,
	}

	for _, entry in entries do
		if entry.State == "Loaded" then
			table.insert(report.Loaded, entry.Module)
			if entry.Duration >= slowThreshold then
				warn(`[Loader] {entry.Module:GetFullName()} took {string.format("%.2f", entry.Duration)}s to load`)
			end
		elseif entry.State == "Failed" then
			table.insert(report.Failed, entry.Module)
		else
			table.insert(report.Pending, entry.Module)
			warn(
				`[Loader] {entry.Module:GetFullName()} still loading after {requireTimeout}s — probable infinite yield`
			)
		end
	end

	-- Flag first: a straggler landing while an OnInit below is misbehaving
	-- and yielding will then run its own lifecycle, and LifecycleRan keeps
	-- the two paths from double-firing.
	initPhaseDone = true
	for _, entry in entries do
		if entry.State == "Loaded" then
			callLifecycle(entry)
		end
	end

	local elapsed = string.format("%.2f", report.Duration)
	local summary = `[Loader] {container.Name}: {#report.Loaded}/{#entries} modules in {elapsed}s`
	if #report.Failed > 0 or #report.Pending > 0 then
		warn(`{summary} ({#report.Failed} failed, {#report.Pending} pending)`)
	else
		print(summary)
	end

	return report
end

return Loader
