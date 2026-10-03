--!strict

-- Answers GetServerTime: the one round trip every client countdown (cooldowns,
-- timers) can calibrate against. Cheap to serve and pointless to spam, so the
-- limiter turns a flood into nils and the client learns to ask less.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Network"):WaitForChild("Server"))
local Game_Settings = require(
	Shared:WaitForChild("Modules"):WaitForChild("Global"):WaitForChild("Libraries"):WaitForChild("Game_Settings")
)
local RateLimit = require(script.Parent:WaitForChild("RateLimit"))

local limiter = RateLimit.new(Game_Settings.Network.Clock.RequestsPerSecond, Game_Settings.Network.Clock.Burst)

Net.GetServerTime.On(function(player: Player): number?
	if not limiter:Allow(player) then
		return nil
	end
	return Workspace:GetServerTimeNow()
end)

return {}
