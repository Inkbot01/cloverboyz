--!strict

-- The profile template. Every profile is reconciled against this on load
-- (Global.FillTable), so adding a key here backfills existing players.
--
-- Every field states WHO OWNS ITS WRITES. One writing module per field; two
-- writers is a race you will not reproduce. See DATA.md §3 and §8.

local Default: { [string]: any } = {
	-- Lifecycle bookkeeping. FirstJoin and JoinDate are written once by
	-- Data/OnFirstJoin; LastOnline by Data on every session start.
	FirstJoin = false,
	JoinDate = 0,
	LastOnline = 0,
}

return Default
