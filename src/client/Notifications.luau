--!strict

-- Where server notifications land. There is no HUD yet, so they go to the
-- output; when one exists it listens on OnNotification instead of on the
-- network, so the toast and anything else that cares share one subscription.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Net = require(Shared:WaitForChild("Network"):WaitForChild("Client"))
local Types = require(Shared:WaitForChild("Network"):WaitForChild("Types"))
local ReplicaShared = require(Packages:WaitForChild("ReplicaShared"))

local Signal = ReplicaShared.Signal

local Notifications = {
	OnNotification = Signal.New(),
}

Net.Notify.On(function(notification: Types.Notification)
	local suffix = if notification.Body ~= "" then ` — {notification.Body}` else ""
	print(`[{notification.Kind}] {notification.Title}{suffix}`)
	Notifications.OnNotification:Fire(notification)
end)

return Notifications
