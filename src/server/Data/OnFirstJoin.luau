--!strict

-- Runs exactly once, the first time a profile is ever created (before the
-- replica exists). Use it for one-time grants that must never be re-applied to
-- returning players. Mutate `profileData` directly here.
--
-- IT RUNS AFTER THE RECONCILE, not before — see buildSession in Data/init. That
-- ordering is what lets this file dereference nested fields at all: before
-- Global.FillTable has run, a nested template table may not exist, and indexing
-- it throws inside the session lock, which locks the player out of their own
-- data for ten minutes. Anything added here can assume the template's shape.
--
-- Grants here are RAISED TO, never set to. A plain assignment is a first-join
-- grant that also DESTROYS a balance: any profile whose FirstJoin flag was ever
-- lost (a redaction, a partial write, a schema break) would have its earned
-- value replaced with the starting amount on the next join.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SharedModules = Shared:WaitForChild("Modules")
local Global = require(SharedModules:WaitForChild("Global"))

return function(profileData: { [string]: any })
	profileData.FirstJoin = true
	profileData.JoinDate = Global.osTime(true)
end
