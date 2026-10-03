--!strict

-- Wraps a raw ReplicaServer replica to add three things stock Replica V5 lacks:
--   1. A `.Changed` signal that fires on every write (used to mirror into peekable).
--   2. `:SafeSubscribe(player)` that defers until the player is ready.
--   3. Destroyed-state guards so holding a wrapper after :Destroy() never throws
--      (raw Replica swaps to a LockedReplica metatable and throws on every method).
--
-- Ported verbatim from the Forsaken data system — it is schema-agnostic.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local ReplicaShared = require(Packages:WaitForChild("ReplicaShared"))
local ReplicaServer = require(Packages:WaitForChild("ReplicaServer"))

local Signal = ReplicaShared.Signal

local ReplicaWrapper = {}

export type Wrapped = {
	Data: { [any]: any },
	Tags: { [string]: any },
	Id: number,
	Token: string,
	Maid: any,
	Changed: any,
	Raw: any,
	Set: (self: Wrapped, path: { string | number }, value: any) -> (),
	SetValues: (self: Wrapped, path: { string | number }, values: { [string]: any }) -> (),
	TableInsert: (self: Wrapped, path: { string | number }, value: any, index: number?) -> number,
	TableRemove: (self: Wrapped, path: { string | number }, index: number) -> any,
	Subscribe: (self: Wrapped, player: Player) -> (),
	SafeSubscribe: (self: Wrapped, player: Player) -> (),
	Unsubscribe: (self: Wrapped, player: Player) -> (),
	Replicate: (self: Wrapped) -> (),
	DontReplicate: (self: Wrapped) -> (),
	IsActive: (self: Wrapped) -> boolean,
	Destroy: (self: Wrapped) -> (),
}

local function fire(signal: any, ...)
	signal:Fire(...)
end

function ReplicaWrapper.wrap(replica: any): Wrapped
	local changed = Signal.New()
	local destroyed = false

	local self: any = {
		Raw = replica,
		Data = replica.Data,
		Tags = replica.Tags,
		Id = replica.Id,
		Token = replica.Token,
		Maid = replica.Maid,
		Changed = changed,
	}

	replica.Maid:Add(function()
		destroyed = true
	end)

	function self:Set(path, value)
		if destroyed then
			return
		end
		local old = replica.Data
		for _, key in ipairs(path) do
			if typeof(old) ~= "table" then
				old = nil
				break
			end
			old = old[key]
		end
		replica:Set(path, value)
		fire(changed, "Set", path, value, old)
	end

	function self:SetValues(path, values)
		if destroyed then
			return
		end
		replica:SetValues(path, values)
		fire(changed, "SetValues", path, values)
	end

	function self:TableInsert(path, value, index)
		if destroyed then
			return 0
		end
		local newIndex = replica:TableInsert(path, value, index)
		fire(changed, "TableInsert", path, value, newIndex)
		return newIndex
	end

	function self:TableRemove(path, index)
		if destroyed then
			return nil
		end
		local removed = replica:TableRemove(path, index)
		fire(changed, "TableRemove", path, removed, index)
		return removed
	end

	function self:Subscribe(player: Player)
		if destroyed then
			return
		end
		replica:Subscribe(player)
	end

	function self:SafeSubscribe(player: Player)
		if destroyed then
			return
		end
		if ReplicaServer.ReadyPlayers[player] == true then
			replica:Subscribe(player)
			return
		end
		local readyConnection: any
		local leaveConnection: RBXScriptConnection
		local function cleanup()
			if readyConnection ~= nil then
				readyConnection:Disconnect()
				readyConnection = nil
			end
			if leaveConnection ~= nil then
				leaveConnection:Disconnect()
				leaveConnection = nil :: any
			end
		end
		readyConnection = ReplicaServer.NewReadyPlayer:Connect(function(readyPlayer)
			if readyPlayer ~= player then
				return
			end
			cleanup()
			if not destroyed and player.Parent ~= nil then
				replica:Subscribe(player)
			end
		end)
		leaveConnection = Players.PlayerRemoving:Connect(function(leaving)
			if leaving == player then
				cleanup()
			end
		end)
		replica.Maid:Add(cleanup)
	end

	function self:Unsubscribe(player: Player)
		if destroyed then
			return
		end
		replica:Unsubscribe(player)
	end

	function self:Replicate()
		if destroyed then
			return
		end
		replica:Replicate()
	end

	function self:DontReplicate()
		if destroyed then
			return
		end
		replica:DontReplicate()
	end

	function self:IsActive(): boolean
		return not destroyed
	end

	function self:Destroy()
		if destroyed then
			return
		end
		destroyed = true
		replica:Destroy()
	end

	return self
end

return ReplicaWrapper
