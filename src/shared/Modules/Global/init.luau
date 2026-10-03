--!strict

-- Global helpers shared by the data + replication stack.
-- Ported from the proven Forsaken data system.

local Global = {}

local activeReplicas: { [number]: any } = {}

-- Shared registry of live private replicas keyed by UserId. Other server modules
-- can reach in by UserId without a circular require on the Data service.
function Global.GetReplicaTable(): { [number]: any }
	return activeReplicas
end

function Global.osTime(utc: boolean?): number
	if utc == true then
		return os.time(os.date("!*t") :: any)
	end
	return os.time()
end

local function isTable(value: any): boolean
	return typeof(value) == "table"
end

-- Recursively fills missing keys in `target` from `source` (reconciliation).
-- Existing values in `target` are never overwritten. Sub-tables recurse.
function Global.FillTable<T>(target: T, source: T): T
	if not isTable(target) or not isTable(source) then
		return target
	end
	for key, defaultValue in pairs(source :: any) do
		local currentValue = (target :: any)[key]
		if currentValue == nil then
			if isTable(defaultValue) then
				(target :: any)[key] = Global.FillTable({}, defaultValue)
			else
				(target :: any)[key] = defaultValue
			end
		elseif isTable(currentValue) and isTable(defaultValue) then
			Global.FillTable(currentValue, defaultValue)
		end
	end
	return target
end

function Global.DeepClone<T>(source: T): T
	if not isTable(source) then
		return source
	end
	local copy: { [any]: any } = {}
	for key, value in pairs(source :: any) do
		copy[key] = Global.DeepClone(value)
	end
	return copy :: any
end

return Global
