local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local UI = require(script.Parent.Components)

return function(scope, state, props)
	return UI.Frame(scope, {
		Name = props.Name,
		Size = UDim2.fromScale(1, 1),
		[Fusion.Children] = {
			UI.Frame(scope, {
				Name = "Body",
				Position = scope:Computed(function(use)
					local layout = use(state.Layout)
					return UDim2.fromOffset(layout.PanelPadding, layout.BodyTop)
				end),
				Size = scope:Computed(function(use)
					local layout = use(state.Layout)
					return UDim2.new(1, -layout.PanelPadding * 2, 1, -layout.BodyTop - layout.FooterHeight)
				end),
				[Fusion.Children] = props.Body,
			}),
			UI.Line(scope, UDim2.new(0, 16, 1, -64), UDim2.new(1, -32, 0, 1)),
			UI.Frame(scope, {
				Name = "Footer",
				Position = scope:Computed(function(use)
					return UDim2.new(0, use(state.Layout).PanelPadding, 1, -54)
				end),
				Size = scope:Computed(function(use)
					return UDim2.new(1, -use(state.Layout).PanelPadding * 2, 0, 44)
				end),
				[Fusion.Children] = props.Footer,
			}),
		},
	})
end
