--!strict

-- Schema migration callbacks applied on every load (updateKeys traversal in
-- Data/init). Redactions drop keys; Renames move a key to a new name. Both are
-- keyed by dot-separated path. Use these for small, mechanical migrations;
-- bump Game_Settings.DataStore.StoreVersion for a full clean break.

local Redactions: { [string]: boolean } = {}

local Renames: { [string]: string } = {}

local Revisions = {}

function Revisions.IsRedacted(_key: string, path: string): boolean
	return Redactions[path] == true
end

function Revisions.GetNewName(key: string, path: string): string
	local renamed = Renames[path]
	if renamed ~= nil then
		return renamed
	end
	return key
end

return Revisions
