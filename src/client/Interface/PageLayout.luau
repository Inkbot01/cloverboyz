local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Motion = require(script.Parent.Motion)

return function(scope, state, props)
	local presence = Motion.Presence(scope, true)
	return scope:New("CanvasGroup")({
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		GroupTransparency = presence.Transparency,
		Name = props.Name,
		LayoutOrder = 3,
		Size = UDim2.fromScale(1, 0),
		[Fusion.Children] = {
			scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
			scope:New("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 12),
			}),
			UI.Frame(scope, {
				Name = "Body",
				LayoutOrder = 1,
				Size = UDim2.fromScale(1, 0),
				[Fusion.Children] = {
					scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
					props.Body,
				},
			}),
			UI.Frame(scope, {
				Name = "FooterDivider",
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = Theme.Line,
				BackgroundTransparency = 0,
			}),
			UI.Frame(scope, {
				Name = "Footer",
				LayoutOrder = 3,
				Size = UDim2.new(1, 0, 0, 44),
				[Fusion.Children] = props.Footer,
			}),
		},
	})
end
