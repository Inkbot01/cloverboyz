--!strict

-- The server's one way to put words in front of a player. Kind is a hint for
-- the client's presentation, nothing more.
--
-- Title and Body are bounded in src/network.blink. Blink measures BYTES and
-- does not check ranges on the sending side, and a value over the bound is
-- dropped by the receiver along with everything batched behind it — so the cut
-- happens here, on a codepoint boundary, before anything is written.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Network"):WaitForChild("Server"))
local Types = require(Shared:WaitForChild("Network"):WaitForChild("Types"))
local Game_Settings = require(
	Shared:WaitForChild("Modules"):WaitForChild("Global"):WaitForChild("Libraries"):WaitForChild("Game_Settings")
)

export type Kind = "Info" | "Success" | "Warning" | "Error"

local TITLE_BYTES = Game_Settings.Network.Notify.TitleBytes
local BODY_BYTES = Game_Settings.Network.Notify.BodyBytes

local function cutBytes(text: string, maxBytes: number): string
	if #text <= maxBytes then
		return text
	end
	local cut = maxBytes
	while cut > 0 do
		local nextByte = string.byte(text, cut + 1)
		if nextByte == nil or bit32.band(nextByte, 0xC0) ~= 0x80 then
			break
		end
		cut -= 1
	end
	return string.sub(text, 1, cut)
end

local function build(kind: Kind, title: string, body: string?): Types.Notification
	local safeTitle = cutBytes(title, TITLE_BYTES)
	if safeTitle == "" then
		safeTitle = kind
	end
	return {
		Kind = kind,
		Title = safeTitle,
		Body = cutBytes(body or "", BODY_BYTES),
	}
end

local Notifications = {}

function Notifications.Send(player: Player, kind: Kind, title: string, body: string?)
	Net.Notify.Fire(player, build(kind, title, body))
end

function Notifications.Broadcast(kind: Kind, title: string, body: string?)
	Net.Notify.FireAll(build(kind, title, body))
end

return Notifications
