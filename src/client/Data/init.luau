--!strict

-- Client-side view of the player's replicated data.
--
--   PlayerData.OnReady            : Signal<Replica>
--   PlayerData.OnPeekableAdded    : Signal<userId, Replica>
--   PlayerData.OnPeekableRemoved  : Signal<userId>
--   PlayerData.IsReady() -> boolean
--   PlayerData.Await() -> Replica              -- yields until our data arrives
--   PlayerData.GetReplica() -> Replica?        -- our private data
--   PlayerData.GetPeekable(userId) -> Replica? -- any player's public data
--   PlayerData.GetAllPeekables() -> { [userId] = Replica }
--   PlayerData.Get(path) -> value?             -- read a path off our data
--   PlayerData.OnSet(path, fn(new, old)) -> disconnect
--   PlayerData.OnChange(fn(action, path, ...)) -> disconnect
--
-- OnSet/OnChange defer cleanly if called before the replica arrives.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local ReplicaClient = require(Packages:WaitForChild("ReplicaClient"))
local ReplicaShared = require(Packages:WaitForChild("ReplicaShared"))

local Signal = ReplicaShared.Signal

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SharedModules = Shared:WaitForChild("Modules")
local Game_Settings =
	require(SharedModules:WaitForChild("Global"):WaitForChild("Libraries"):WaitForChild("Game_Settings"))

local PlayerDataReplica: any = nil
local peekableReplicas: { [number]: any } = {}

local readySignal = Signal.New()
local peekableAddedSignal = Signal.New()
local peekableRemovedSignal = Signal.New()

local PlayerData = {
	OnReady = readySignal,
	OnPeekableAdded = peekableAddedSignal,
	OnPeekableRemoved = peekableRemovedSignal,
}

function PlayerData.IsReady(): boolean
	return PlayerDataReplica ~= nil
end

function PlayerData.Await(): any
	if PlayerDataReplica == nil then
		readySignal:Wait()
	end
	return PlayerDataReplica
end

function PlayerData.GetReplica(): any
	return PlayerDataReplica
end

function PlayerData.GetPeekable(userId: number): any?
	return peekableReplicas[userId]
end

function PlayerData.GetAllPeekables(): { [number]: any }
	return peekableReplicas
end

function PlayerData.Get(path: { string | number }): any?
	if PlayerDataReplica == nil then
		return nil
	end
	local cursor: any = PlayerDataReplica.Data
	for _, key in ipairs(path) do
		if typeof(cursor) ~= "table" then
			return nil
		end
		cursor = cursor[key]
		if cursor == nil then
			return nil
		end
	end
	return cursor
end

function PlayerData.OnSet(path: { string | number }, callback: (newValue: any, oldValue: any) -> ()): () -> ()
	if typeof(callback) ~= "function" then
		error("[PlayerData] callback must be a function", 2)
	end
	local connection: any = nil
	local function bind(replica: any)
		connection = replica:OnSet(path, callback)
	end
	if PlayerDataReplica ~= nil then
		bind(PlayerDataReplica)
	else
		local waitConnection: any
		waitConnection = readySignal:Connect(function()
			waitConnection:Disconnect()
			waitConnection = nil
			bind(PlayerDataReplica)
		end)
		return function()
			if waitConnection ~= nil then
				waitConnection:Disconnect()
				waitConnection = nil
			end
			if connection ~= nil then
				connection:Disconnect()
				connection = nil
			end
		end
	end
	return function()
		if connection ~= nil then
			connection:Disconnect()
			connection = nil
		end
	end
end

function PlayerData.OnChange(callback: (action: string, path: { string | number }, ...any) -> ()): () -> ()
	if typeof(callback) ~= "function" then
		error("[PlayerData] callback must be a function", 2)
	end
	local connection: any = nil
	local function bind(replica: any)
		connection = replica:OnChange(callback)
	end
	if PlayerDataReplica ~= nil then
		bind(PlayerDataReplica)
	else
		local waitConnection: any
		waitConnection = readySignal:Connect(function()
			waitConnection:Disconnect()
			waitConnection = nil
			bind(PlayerDataReplica)
		end)
		return function()
			if waitConnection ~= nil then
				waitConnection:Disconnect()
				waitConnection = nil
			end
			if connection ~= nil then
				connection:Disconnect()
				connection = nil
			end
		end
	end
	return function()
		if connection ~= nil then
			connection:Disconnect()
			connection = nil
		end
	end
end

ReplicaClient.OnNew(Game_Settings.Tokens.PlayerData, function(replica)
	PlayerDataReplica = replica
	readySignal:Fire(replica)
	replica.Maid:Add(function()
		if PlayerDataReplica == replica then
			PlayerDataReplica = nil
		end
	end)
end)

ReplicaClient.OnNew(Game_Settings.Tokens.PeekableData, function(replica)
	local userId = replica.Tags and replica.Tags.UserId
	if typeof(userId) ~= "number" then
		return
	end
	peekableReplicas[userId] = replica
	peekableAddedSignal:Fire(userId, replica)
	replica.Maid:Add(function()
		if peekableReplicas[userId] == replica then
			peekableReplicas[userId] = nil
			peekableRemovedSignal:Fire(userId)
		end
	end)
end)

ReplicaClient.RequestData()

return PlayerData
