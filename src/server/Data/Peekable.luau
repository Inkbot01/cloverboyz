--!strict

-- Subset of the profile replicated PUBLICLY to every player (nameplates,
-- leaderboards, party UI). Keys are dot-separated paths into the profile data;
-- a matching server `:Set`/`:SetValues`/... is mirrored into the public replica.
--
-- ADDING A PATH HERE MAKES IT PUBLIC FOREVER — the whole sub-tree under it, not
-- just the field you were thinking of, readable by every player in the server.
-- The default answer to "should this be peekable" is no.
--
-- The mirror matches EXACT string paths, so dynamic array indices like
-- "Slots.Characters.3.FirstName" are awkward; prefer mirroring a fixed field you
-- keep in sync (e.g. a top-level "Public.DisplayName" the owning module updates).
--
-- The mirror DEEP-COPIES on the way out (see getPeekableData in Data/init), so a
-- mutation of the private profile that never went through :Set cannot leak here
-- by sharing a table with it.

local Peekable: { [string]: boolean } = {}

return Peekable
