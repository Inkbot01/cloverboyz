local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Theme = require(script.Parent.Theme)
local Layout = require(script.Parent.Layout)
local UI = require(script.Parent.Components)
local Art = require(script.Parent.HudParts)
local Children = Fusion.Children

return function(scope, state, actions, compact)
	local metrics = Layout.Menu(compact)
	local entries = {}
	for index, info in
		{
			{ "Stats", "Character", "Stats", "Stats" },
			{ "Grimoire", "Book", "Grimoire", "Book" },
			{ "Equipment", "Bag", "Items", "Items" },
		}
	do
		table.insert(
			entries,
			UI.Button(scope, {
				Name = info[1],
				LayoutOrder = index,
				SelectionOrder = index,
				Size = UDim2.fromScale(0, 1),
				Variant = "Ghost",
				HoverColor = Theme.MenuHover,
				OnActivated = function()
					actions.Open(info[1])
				end,
				[Children] = UI.Frame(scope, {
					Name = "Content",
					Size = UDim2.fromScale(1, 1),
					[Children] = {
						scope:New("UIListLayout")({
							SortOrder = Enum.SortOrder.LayoutOrder,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							Padding = UDim.new(0, if compact then 4 else 8),
						}),
						Art.Sprite(scope, {
							Icon = info[2],
							LayoutOrder = 1,
							Size = UDim2.fromOffset(if compact then 26 else 42, if compact then 26 else 42),
						}),
						Art.Text(scope, {
							Name = "Label",
							LayoutOrder = 2,
							Size = UDim2.new(1, 0, 0, if compact then 16 else 24),
							Text = if compact then info[4] else info[3],
							TextSize = if compact then 15 else 22,
							TextXAlignment = Enum.TextXAlignment.Center,
						}),
					},
				}),
			})
		)
	end
	return Art.Panel(scope, {
		Name = "MenuFlyout",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(metrics.Width, metrics.Height),
		Skin = if compact then "plaque" else "window",
		Color = Theme.MenuSurface,
		MaterialTransparency = 0.94,
		Visible = state.MenuOpen,
		[Children] = UI.Frame(scope, {
			Name = "Content",
			Size = UDim2.fromScale(1, 1),
			[Children] = {
				scope:New("UIPadding")({
					PaddingLeft = UDim.new(0, metrics.Padding),
					PaddingRight = UDim.new(0, metrics.Padding),
					PaddingTop = UDim.new(0, metrics.Padding),
					PaddingBottom = UDim.new(0, metrics.Padding),
				}),
				scope:New("UIListLayout")({
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, metrics.RowGap),
				}),
				UI.Frame(scope, {
					Name = "Pages",
					LayoutOrder = 1,
					Size = UDim2.new(1, 0, 0, metrics.PagesHeight),
					[Children] = {
						scope:New("UIListLayout")({
							FillDirection = Enum.FillDirection.Horizontal,
							HorizontalFlex = Enum.UIFlexAlignment.Fill,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, metrics.PageGap),
						}),
						entries,
					},
				}),
				UI.Frame(scope, {
					Name = "NavigationDivider",
					LayoutOrder = 2,
					Size = UDim2.new(1, 0, 0, 2),
					BackgroundColor3 = Theme.GoldDim,
					BackgroundTransparency = 0.55,
				}),

				UI.Frame(scope, {
					Name = "Utilities",
					LayoutOrder = 3,
					Size = UDim2.new(1, 0, 0, 44),
					[Children] = {
						scope:New("UIListLayout")({
							FillDirection = Enum.FillDirection.Horizontal,
							HorizontalFlex = Enum.UIFlexAlignment.Fill,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, metrics.PageGap),
						}),

						UI.Button(scope, {
							Name = "Customization",
							LayoutOrder = 1,
							SelectionOrder = 4,
							Size = UDim2.fromScale(0, 1),
							Variant = "Ghost",
							HoverColor = Theme.MenuHover,
							OnActivated = function()
								actions.Open("Customization")
							end,
							[Children] = UI.Frame(scope, {
								Name = "Content",
								Size = UDim2.fromScale(1, 1),
								[Children] = {
									scope:New("UIListLayout")({
										FillDirection = Enum.FillDirection.Horizontal,
										SortOrder = Enum.SortOrder.LayoutOrder,
										VerticalAlignment = Enum.VerticalAlignment.Center,
										HorizontalAlignment = Enum.HorizontalAlignment.Center,
										Padding = UDim.new(0, if compact then 6 else 10),
									}),
									Art.Sprite(scope, {
										Icon = "Character",
										LayoutOrder = 1,
										Size = UDim2.fromOffset(if compact then 22 else 26, if compact then 22 else 26),
									}),
									Art.Text(scope, {
										Text = if compact then "Edit" else "Customize",
										LayoutOrder = 2,
										Size = UDim2.fromOffset(if compact then 40 else 88, 24),
										TextSize = if compact then 16 else 19,
									}),
								},
							}),
						}),
						UI.Button(scope, {
							Name = "Navigation",
							LayoutOrder = 2,
							SelectionOrder = 5,
							Size = UDim2.fromScale(0, 1),
							Variant = "Ghost",
							HoverColor = Theme.MenuHover,
							Selected = state.NavigationEnabled,
							OnActivated = actions.ToggleNavigation,
							[Children] = UI.Frame(scope, {
								Name = "Content",
								Size = UDim2.fromScale(1, 1),
								[Children] = {
									scope:New("UIPadding")({
										PaddingLeft = UDim.new(0, if compact then 4 else 8),
										PaddingRight = UDim.new(0, if compact then 4 else 8),
									}),
									scope:New("UIListLayout")({
										FillDirection = Enum.FillDirection.Horizontal,
										SortOrder = Enum.SortOrder.LayoutOrder,
										VerticalAlignment = Enum.VerticalAlignment.Center,
										Padding = UDim.new(0, if compact then 4 else 8),
									}),
									Art.Sprite(scope, {
										Icon = "Compass",
										LayoutOrder = 1,
										Size = UDim2.fromOffset(if compact then 18 else 26, if compact then 18 else 26),
									}),
									Art.Text(scope, {
										Name = "Label",
										LayoutOrder = 2,
										Size = UDim2.fromScale(0, 1),
										Text = "Guide",
										TextSize = if compact then 14 else 18,
										[Children] = scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
									}),
									UI.Frame(scope, {
										Name = "NavigationState",
										LayoutOrder = 3,
										Size = UDim2.fromOffset(if compact then 28 else 40, if compact then 24 else 28),
										BackgroundTransparency = 0,
										BackgroundColor3 = scope:Computed(function(use)
											return if use(state.NavigationEnabled)
												then Theme.GreenDark
												else Theme.MenuHover
										end),
										[Children] = Art.Text(scope, {
											Name = "State",
											Font = Theme.NumberFont,
											TextSize = if compact then 12 else 16,
											TextXAlignment = Enum.TextXAlignment.Center,
											TextColor3 = scope:Computed(function(use)
												return if use(state.NavigationEnabled) then Theme.Green else Theme.Muted
											end),
											Text = scope:Computed(function(use)
												return if use(state.NavigationEnabled) then "ON" else "OFF"
											end),
										}),
									}),
								},
							}),
						}),
					},
				}),
			},
		}),
	})
end
