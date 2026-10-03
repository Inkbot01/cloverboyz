--!strict

-- Central place for tunable constants shared across server + client.
-- Token names live here so the string is never typed twice (typo-safe).

local Settings = {
	DataStore = {
		StoreName = "PlayerData",
		-- ⚠ THIS NUMBER IS THE KEYSPACE. The store is `PlayerData<version>`, so
		-- changing it does not migrate anything — it points the whole game at an
		-- EMPTY store and every account in it starts from nothing. The old data is
		-- not deleted (it sits at the old key) and the only way back is putting
		-- the number back, but any progress made in between is lost for good.
		--
		-- A new FIELD needs no version bump at all — add it to Data/Default and
		-- Global.FillTable backfills it on load. A renamed or dropped field is
		-- Data/Revisions. This is only for a break neither of those can express,
		-- on a live game, deliberately.
		StoreVersion = 1,
	},

	Tokens = {
		PlayerData = "PlayerData",
		PeekableData = "PeekableData",
	},
}

return Settings
