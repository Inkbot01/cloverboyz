--!strict

-- Player data service: ProfileStore persistence + Replica replication.
--
-- Public API (after require):
--   PlayerData.LoadPlayerData(player)        -- explicit load (auto on PlayerAdded)
--   PlayerData.GetReplica(player | userId)   -- private wrapped replica
--   PlayerData.GetPeekable(player | userId)  -- public wrapped replica
--   PlayerData.GetProfile(player | userId)   -- raw ProfileStore Profile
--   PlayerData.Await(player) -> replica?     -- yields until ready (nil if left)
--   PlayerData.IsLoaded(player) -> boolean
--   PlayerData.playerRemoval(player)         -- destroy replica (auto on leave)
--   PlayerData.OnSessionStart : Signal<Player, WrappedReplica>
--   PlayerData.OnSessionEnd   : Signal<Player>
--
-- Always mutate through the replica (GetReplica():Set{...}) — direct profile.Data
-- writes persist but do NOT replicate to the client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local ReplicaServer = require(Packages:WaitForChild("ReplicaServer"))
local ProfileStore = require(Packages:WaitForChild("ProfileStore"))
local ReplicaShared = require(Packages:WaitForChild("ReplicaShared"))

local Signal = ReplicaShared.Signal

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SharedModules = Shared:WaitForChild("Modules")
local GlobalFolder = SharedModules:WaitForChild("Global")
local Global = require(GlobalFolder)
local Game_Settings = require(GlobalFolder:WaitForChild("Libraries"):WaitForChild("Game_Settings"))

local Default = require(script:WaitForChild("Default"))
local OnFirstJoin = require(script:WaitForChild("OnFirstJoin"))
local PeekableData = require(script:WaitForChild("Peekable"))
local Revisions = require(script:WaitForChild("Revisions"))
local ReplicaWrapper = require(script:WaitForChild("ReplicaWrapper"))

local SHUTDOWN_DRAIN_TIMEOUT = 30
local SESSION_STOLEN_MESSAGE = "Your data session ended (it was opened elsewhere). Please rejoin."

local closing = false

local PlayerDataToken = ReplicaServer.Token(Game_Settings.Tokens.PlayerData)
local PeekableToken = ReplicaServer.Token(Game_Settings.Tokens.PeekableData)

local storeKey = `{Game_Settings.DataStore.StoreName}{Game_Settings.DataStore.StoreVersion}`

local profileStore = ProfileStore.New(storeKey, Default)

-- ProfileStore's own telemetry, which nothing was listening to. Without these a
-- DataStore outage, a throttle storm or a corrupted key that ProfileStore
-- silently replaced with the template all happened in total silence — the last
-- one turning a veteran into a brand-new player with nothing in the log to
-- explain it. None of these change behaviour; they make failure visible.
ProfileStore.OnError:Connect(function(message, store, key)
	warn(`[PlayerData] ProfileStore error on {store}/{key} — {message}`)
end)

ProfileStore.OnOverwrite:Connect(function(store, key)
	warn(`[PlayerData] ProfileStore OVERWROTE a corrupted key: {store}/{key} — that profile was reset`)
end)

ProfileStore.OnCriticalToggle:Connect(function(isCritical)
	if isCritical then
		warn("[PlayerData] ProfileStore is in CRITICAL state — saves are failing")
	else
		print("[PlayerData] ProfileStore recovered from critical state")
	end
end)

local activeReplicas: { [number]: ReplicaWrapper.Wrapped } = Global.GetReplicaTable()
local activePeekables: { [number]: ReplicaWrapper.Wrapped } = {}
local activeProfiles: { [number]: any } = {}

local OnSessionStart = Signal.New()
local OnSessionEnd = Signal.New()

local tableConcat = table.concat
local stringSplit = string.split

-- Redactions and renames only ever apply to NAMED fields (string keys). Numeric
-- keys are array indices — recurse into them, but never redact or rename them: a
-- rename returns a string, and comparing that string against a numeric key is always
-- "different", which silently rewrote e.g. Characters[1] (number) to Characters["1"]
-- (string). That turns the array into a dictionary `#`/ipairs can't see, so every
-- saved character read as missing and got re-rolled on load.
--
-- RENAMES ARE COLLECTED, THEN APPLIED. Inserting a key into a table while
-- `pairs()` is walking it is undefined in Luau and commonly raises "invalid key
-- to 'next'". Deleting during a walk is legal, so the redaction branch may stay
-- inline; the rename branch may not. `Revisions.Renames` is empty today, so this
-- has never fired — the first rename anyone adds would have turned every
-- affected profile load into a throw inside the session lock (see LoadPlayerData).
local function updateKeys(data: { [string]: any }, path: string)
	local renames: { { from: string, to: string, value: any } } = {}
	for key, value in pairs(data) do
		local pathKey = if path == "" then tostring(key) else `{path}.{key}`
		if typeof(key) == "string" and Revisions.IsRedacted(key, pathKey) then
			data[key] = nil
		else
			if typeof(key) == "string" then
				local newKey = Revisions.GetNewName(key, pathKey)
				if newKey ~= key then
					table.insert(renames, { from = key, to = newKey, value = value })
				end
			end
			if typeof(value) == "table" then
				updateKeys(value, pathKey)
			end
		end
	end
	for _, rename in renames do
		data[rename.to] = rename.value
		data[rename.from] = nil
	end
end

local function completeData<T>(data: T): T
	updateKeys(data :: any, "")
	Global.FillTable(data, Default :: any)
	return data
end

local function getPeekableData(data: { [string]: any }): { [string]: any }
	local peekable: { [string]: any } = {}
	for path in pairs(PeekableData) do
		local parts = stringSplit(path, ".")
		if #parts > 1 then
			local refData: any = data
			local refPeek: any = peekable
			local last = #parts
			for index, key in ipairs(parts) do
				if typeof(refData) ~= "table" then
					break
				end
				refData = refData[key]
				if index ~= last then
					refPeek[key] = refPeek[key] or {}
					refPeek = refPeek[key]
				else
					-- COPIED, never aliased. The public replica is readable by
					-- every player in the server, and handing it the PRIVATE
					-- profile's own table means any in-place mutation of that
					-- table — one that never went through :Set, so nothing knows
					-- to ask whether it should be public — is published to the
					-- whole room the instant it happens.
					refPeek[key] = Global.DeepClone(refData)
				end
			end
		else
			local key = parts[1]
			local value = data[key]
			if value ~= nil then
				peekable[key] = Global.DeepClone(value)
			end
		end
	end
	return peekable
end

local PlayerData = {
	OnSessionStart = OnSessionStart,
	OnSessionEnd = OnSessionEnd,
	-- The DataStore name every profile lives under (`PlayerData<version>`), for
	-- any reader outside ProfileStore, so a version bump moves it with
	-- everything else.
	StoreKey = storeKey,
}

function PlayerData.GetReplica(player: Player | number): ReplicaWrapper.Wrapped?
	local userId = if typeof(player) == "number" then player else player.UserId
	return activeReplicas[userId]
end

function PlayerData.GetPeekable(player: Player | number): ReplicaWrapper.Wrapped?
	local userId = if typeof(player) == "number" then player else player.UserId
	return activePeekables[userId]
end

function PlayerData.GetProfile(player: Player | number): any?
	local userId = if typeof(player) == "number" then player else player.UserId
	return activeProfiles[userId]
end

function PlayerData.IsLoaded(player: Player): boolean
	return activeReplicas[player.UserId] ~= nil
end

function PlayerData.Await(player: Player): ReplicaWrapper.Wrapped?
	local existing = activeReplicas[player.UserId]
	if existing ~= nil then
		return existing
	end
	if player.Parent == nil then
		return nil
	end

	local thread = coroutine.running()
	local startConnection: any
	local leaveConnection: RBXScriptConnection

	local function resume(result: any)
		if startConnection ~= nil then
			startConnection:Disconnect()
			startConnection = nil
		end
		if leaveConnection ~= nil then
			leaveConnection:Disconnect()
			leaveConnection = nil :: any
		end
		task.spawn(thread, result)
	end

	startConnection = OnSessionStart:Connect(function(targetPlayer: Player, replica: any)
		if targetPlayer == player then
			resume(replica)
		end
	end)

	leaveConnection = Players.PlayerRemoving:Connect(function(leaving)
		if leaving == player then
			resume(nil)
		end
	end)

	return coroutine.yield()
end

-- Assigned below LoadPlayerData, which is its only caller.
local buildSession: (Player, any, any) -> ReplicaWrapper.Wrapped?

function PlayerData.LoadPlayerData(player: Player): ReplicaWrapper.Wrapped?
	local userId = player.UserId

	local existing = activeReplicas[userId]
	if existing ~= nil then
		existing:Destroy()
		warn(`[PlayerData] previous session found for {player.Name}, replacing`)
	end

	local profile = profileStore:StartSessionAsync(`Player_{userId}`, {
		Cancel = function()
			return player.Parent == nil
		end,
	})

	if profile == nil then
		if player.Parent ~= nil then
			player:Kick("Data failed to load. Please rejoin.")
		end
		return nil
	end

	profile:AddUserId(userId)

	if not player:IsDescendantOf(Players) then
		profile:EndSession()
		return nil
	end

	-- A SESSION CAN END WITHOUT US ENDING IT: another server steals it, the same
	-- player rejoins elsewhere, or ProfileStore gives up after ten minutes of
	-- failed updates and assumes this server is dead. When that happens the
	-- profile stops autosaving and every later write is discarded — and nothing
	-- in the game could see it, because `replica:IsActive()` only reports whether
	-- the WRAPPER was destroyed and has no relationship to `Profile:IsActive()`.
	-- The player carried on playing and lost everything from that moment, with no
	-- sign on either side. Kicking is the honest answer: they rejoin, the session
	-- is theirs again, and they lose the last autosave window instead of the rest
	-- of the night.
	profile.OnSessionEnd:Connect(function()
		if closing or activeProfiles[userId] ~= profile then
			return
		end
		if player.Parent ~= nil then
			player:Kick(SESSION_STOLEN_MESSAGE)
		end
	end)

	local profileData = profile.Data

	-- THE SESSION LOCK IS ALREADY HELD by the time we get here, so everything
	-- below runs under xpcall. It used to be bare: anything that threw between
	-- StartSessionAsync and the Maid registration — a bad reconcile, a template
	-- change, a malformed stored blob — left the key locked to this server with
	-- nothing left holding a reference that could release it. The player was
	-- neither loaded nor kicked (Await yields forever), and could not load their
	-- own data anywhere else until ProfileStore assumed the session dead, about
	-- ten minutes later. Releasing the lock is the whole point of the handler.
	local ok, result = xpcall(function()
		return buildSession(player, profile, profileData)
	end, function(err)
		return debug.traceback(tostring(err), 2)
	end)
	if not ok then
		warn(`[PlayerData] session build failed for {player.Name} —\n{result}`)
		activeProfiles[userId] = nil
		activeReplicas[userId] = nil
		activePeekables[userId] = nil
		profile:EndSession()
		if player.Parent ~= nil then
			player:Kick("Data failed to load. Please rejoin.")
		end
		return nil
	end
	return result
end

-- Everything from the first profile write to the Maid registration. Split out
-- so LoadPlayerData can run it under one xpcall and still release the session
-- lock on any failure inside it. Forward-declared above, since the caller is
-- written first.
buildSession = function(player: Player, profile: any, profileData: any): ReplicaWrapper.Wrapped?
	local userId = player.UserId
	profileData.LastOnline = Global.osTime(true)

	-- RECONCILE FIRST, GRANT SECOND. OnFirstJoin may dereference nested
	-- template fields, and on a profile that has not been through FillTable yet
	-- that is an index into nil, thrown inside the session lock. Reconciled
	-- first, the template guarantees every field OnFirstJoin touches, and the
	-- grant is the last word rather than something a backfill can undo.
	local reconciled = completeData(profileData)

	if not reconciled.FirstJoin then
		OnFirstJoin(reconciled)
	end

	local rawData = ReplicaServer.New({
		Token = PlayerDataToken,
		Data = reconciled,
		Tags = { UserId = userId },
	})

	local rawPeekable = ReplicaServer.New({
		Token = PeekableToken,
		Data = getPeekableData(rawData.Data),
		Tags = { UserId = userId },
	})

	local data = ReplicaWrapper.wrap(rawData)
	local peekable = ReplicaWrapper.wrap(rawPeekable)

	-- MIRROR A PUBLIC PATH ONTO THE PUBLIC REPLICA.
	--
	-- Dispatched by name rather than reflectively, because the wrapper's Changed
	-- signal and its methods do NOT share an argument order. TableRemove fires
	-- (path, removedValue, index) but takes (path, index) — so forwarding the
	-- varargs blind handed the removed VALUE where an index belongs, and
	-- `table.remove(list, <a table>)` is a corrupt public mirror on the first
	-- array path anyone adds to Peekable. Nothing reaches it today (Peekable is
	-- empty), which is exactly why it would have shipped. Set and TableInsert
	-- happened to line up; that was luck.
	local changedConnection = data.Changed:Connect(function(funcName: string, path: { string | number }, ...)
		local stringPath = tableConcat(path, ".")
		if not PeekableData[stringPath] then
			return
		end
		local a, b = ...
		if funcName == "Set" then
			peekable:Set(path, a) -- (value, old) — `old` is for listeners, not for us
		elseif funcName == "SetValues" then
			peekable:SetValues(path, a)
		elseif funcName == "TableInsert" then
			peekable:TableInsert(path, a, b) -- (value, index)
		elseif funcName == "TableRemove" then
			peekable:TableRemove(path, b) -- (removedValue, index) → we want the INDEX
		end
	end)

	activeProfiles[userId] = profile
	activeReplicas[userId] = data
	activePeekables[userId] = peekable

	data:SafeSubscribe(player)
	peekable:Replicate()

	-- TABLES FIRST. EndSession fires profile.OnSessionEnd synchronously (before
	-- the save's first yield), and the handler above kicks whenever this profile
	-- is still the active one for the player. A re-entrant LoadPlayerData that
	-- destroys the previous session would otherwise kick the very player it is
	-- reloading, with the "opened elsewhere" message.
	rawData.Maid:Add(function()
		changedConnection:Disconnect()
		activeProfiles[userId] = nil
		activeReplicas[userId] = nil
		activePeekables[userId] = nil
		profile:EndSession()
		peekable:Destroy()
	end)

	player:SetAttribute("Data_Loaded", true)

	OnSessionStart:Fire(player, data)
	return data
end

function PlayerData.playerRemoval(player: Player)
	local replica = activeReplicas[player.UserId]
	if replica ~= nil then
		replica:Destroy()
	end
	OnSessionEnd:Fire(player)
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerData.LoadPlayerData, player)
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(PlayerData.LoadPlayerData, player)
end)

Players.PlayerRemoving:Connect(function(player)
	task.wait()
	PlayerData.playerRemoval(player)
end)

-- SHUTDOWN. ProfileStore installs its own BindToClose that ends and saves every
-- active session, and Roblox runs every handler concurrently — so this one's job
-- is only to give that a chance to finish, not to do the saving itself.
--
-- It used to spin on `activeProfiles`, which is cleared by the replica's Maid and
-- therefore only by `replica:Destroy()`. During a shutdown PlayerRemoving may not
-- fire at all, so the table never emptied and this burned the FULL 30 seconds of
-- every shutdown — 30 seconds being Roblox's hard cap, leaving ProfileStore's own
-- retry backoff no room at the end. Releasing the profiles ourselves is both the
-- correct thing to wait on and the thing that makes the wait end early.
game:BindToClose(function()
	closing = true
	-- Release every live session up front. EndSession saves with the
	-- is-ending-session flag, which is what makes ProfileStore retry the write
	-- until it lands instead of dropping it.
	-- Snapshotted first: Destroy runs the Maid, which clears this very table.
	local live = {}
	for _, replica in activeReplicas do
		table.insert(live, replica)
	end
	for _, replica in live do
		pcall(function()
			replica:Destroy() -- the Maid ends the session and clears the tables
		end)
	end

	local startTime = os.clock()
	while next(activeProfiles) ~= nil do
		if os.clock() - startTime > SHUTDOWN_DRAIN_TIMEOUT then
			warn(`[PlayerData] {SHUTDOWN_DRAIN_TIMEOUT}s shutdown drain elapsed with sessions still open`)
			break
		end
		task.wait(0.2)
	end
end)

return PlayerData
