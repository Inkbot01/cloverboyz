local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Theme = require(script.Parent.Theme)
local Model = require(script.Parent.Model)
local UI = require(script.Parent.Components)
local Art = require(script.Parent.HudParts)
local Layout = require(script.Parent.Layout)
local MenuFlyout = require(script.Parent.MenuFlyout)
local Children = Fusion.Children

return function(scope, state, actions)
	return UI.Frame(scope, {
		Name = "Menu",
		LayoutOrder = 1,
		Size = scope:Computed(function(use)
			return UDim2.new(1, 0, 0, use(state.Layout).MenuHeight)
		end),
		Visible = scope:Computed(function(use)
			return not use(state.Open)
		end),
		[Children] = scope:Computed(function(use, inner)
			local compact = use(state.Mobile)
			local menuBeside = use(state.Layout).MenuBeside
			local menuAboveAbilities = use(state.Layout).MenuAboveAbilities
			local metrics = Layout.Menu(compact)
			local currencies = {}
			for index, info in { { "Coins", "Coin", 144, 84 }, { "Gems", "Gem", 120, 60 } } do
				table.insert(
					currencies,
					Art.Panel(inner, {
						Name = info[1],
						LayoutOrder = index + 1,
						Size = UDim2.fromOffset(if compact then info[4] else info[3], if compact then 36 else 42),
						Skin = "plaque",
						[Children] = UI.Frame(inner, {
							Name = "Readout",
							Size = UDim2.fromScale(1, 1),
							[Children] = {
								inner:New("UIPadding")({
									PaddingLeft = UDim.new(0, if compact then 6 else 14),
									PaddingRight = UDim.new(0, if compact then 6 else 14),
								}),
								inner:New("UIListLayout")({
									FillDirection = Enum.FillDirection.Horizontal,
									SortOrder = Enum.SortOrder.LayoutOrder,
									VerticalAlignment = Enum.VerticalAlignment.Center,
									Padding = UDim.new(0, if compact then 4 else 8),
								}),
								Art.Sprite(inner, {
									Icon = info[2],
									LayoutOrder = 1,
									Size = UDim2.fromOffset(if compact then 18 else 28, if compact then 18 else 28),
								}),
								Art.Text(inner, {
									Name = "Amount",
									LayoutOrder = 2,
									Size = UDim2.fromScale(0, 1),
									Font = Theme.NumberFont,
									TextSize = if compact then 17 else 27,
									TextColor3 = if index == 1 then Theme.HudGoldLight else Theme.Green,
									[Children] = inner:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
									Text = inner:Computed(function(read)
										local value = read(state.Fields[info[1]])
										return if value >= (if compact then 1000 else 10000)
											then Model.FormatShort(value)
											else Model.FormatNumber(value)
									end),
								}),
							},
						}),
					})
				)
			end
			return {
				inner:New("UIListLayout")({
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
					Padding = UDim.new(0, metrics.DockGap),
				}),
				if not menuBeside and not menuAboveAbilities then MenuFlyout(inner, state, actions, compact) else nil,
				UI.Frame(inner, {
					Name = "Toolbar",
					LayoutOrder = 2,
					Size = UDim2.new(1, 0, 0, metrics.ToolbarHeight),
					[Children] = {
						inner:New("UIListLayout")({
							FillDirection = Enum.FillDirection.Horizontal,
							SortOrder = Enum.SortOrder.LayoutOrder,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							Padding = UDim.new(0, if compact then 6 else 12),
						}),
						Art.Button(inner, {
							Name = "MenuToggle",
							LayoutOrder = 1,
							Size = UDim2.fromOffset(if compact then 80 else 136, metrics.ToolbarHeight),
							Skin = "plaque",
							Selected = state.MenuOpen,
							OnActivated = actions.ToggleMenu,
							[Children] = UI.Frame(inner, {
								Name = "Content",
								Size = UDim2.fromScale(1, 1),
								[Children] = {
									inner:New("UIListLayout")({
										FillDirection = Enum.FillDirection.Horizontal,
										SortOrder = Enum.SortOrder.LayoutOrder,
										HorizontalAlignment = Enum.HorizontalAlignment.Center,
										VerticalAlignment = Enum.VerticalAlignment.Center,
										Padding = UDim.new(0, if compact then 4 else 10),
									}),
									Art.Key(inner, {
										Text = "M",
										LayoutOrder = 1,
										Size = UDim2.fromOffset(if compact then 20 else 28, if compact then 24 else 28),
									}),
									Art.Text(inner, {
										Text = "MENU",
										LayoutOrder = 2,
										Size = UDim2.fromOffset(if compact then 42 else 64, 30),
										Font = Theme.NumberFont,
										TextSize = if compact then 16 else 24,
									}),
								},
							}),
						}),
						currencies,
					},
				}),
			}
		end),
	})
end
