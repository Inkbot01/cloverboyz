local RunService = game:GetService("RunService")
local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Theme = require(script.Parent.Theme)
local Art = require(script.Parent.HudParts)
local UI = require(script.Parent.Components)
local Model = require(script.Parent.Model)

return function(scope, state, parent)
	local destination = scope:Computed(function(use)
		local quest = use(state.Fields.Quest)
		return if quest then quest.TargetPosition else nil
	end)
	local enabled = scope:Computed(function(use)
		return use(state.NavigationEnabled) and use(destination) ~= nil and not use(state.Open)
	end)
	local target = scope:New("Attachment")({
		Name = "CloverQuestDestination",
		Parent = workspace.Terrain,
		Position = scope:Computed(function(use)
			return use(destination) or Vector3.zero
		end),
	})
	scope:New("BillboardGui")({
		Name = "CloverQuestWaypoint",
		Parent = parent,
		Adornee = target,
		Enabled = enabled,
		AlwaysOnTop = true,
		LightInfluence = 0,
		Size = UDim2.fromOffset(160, 84),
		StudsOffsetWorldSpace = Vector3.new(0, 5, 0),
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		[Fusion.Children] = UI.Frame(scope, {
			Size = UDim2.fromScale(1, 1),
			[Fusion.Children] = {
				scope:New("UIListLayout")({
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0, 5),
				}),
				Art.Sprite(scope, { Icon = "Compass", LayoutOrder = 1, Size = UDim2.fromOffset(44, 44) }),
				Art.Panel(scope, {
					Name = "DistancePlate",
					LayoutOrder = 2,
					Size = UDim2.fromOffset(112, 28),
					Skin = "plaque",
					[Fusion.Children] = Art.Text(scope, {
						TextXAlignment = Enum.TextXAlignment.Center,
						Font = Theme.NumberFont,
						TextSize = 20,
						TextColor3 = Theme.HudGoldLight,
						Text = scope:Computed(function(use)
							local distance = use(state.QuestDistance)
							return if distance then Model.FormatShort(distance) .. " studs" else "QUEST"
						end),
					}),
				}),
			},
		}),
	})
	local elapsed = 0
	table.insert(
		scope,
		RunService.Heartbeat:Connect(function(delta)
			elapsed += delta
			if elapsed < 0.075 then
				return
			end
			elapsed = 0
			local position = Fusion.peek(destination)
			local camera = workspace.CurrentCamera
			if camera then
				local look = camera.CFrame.LookVector
				state.Heading:set(math.deg(math.atan2(look.X, -look.Z)) % 360)
			end
			if not position or not camera or not Fusion.peek(state.NavigationEnabled) then
				state.QuestHeading:set(nil)
				state.QuestDistance:set(nil)
				return
			end
			local character = Fusion.peek(state.Character)
			local origin = if character and character.Parent
				then character:GetPivot().Position
				else camera.CFrame.Position
			local direction = position - camera.CFrame.Position
			state.QuestDistance:set(math.floor((position - origin).Magnitude + 0.5))
			state.QuestHeading:set(math.deg(math.atan2(direction.X, -direction.Z)) % 360)
		end)
	)
end
