local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Theme = require(script.Parent.Theme)
local Model = require(script.Parent.Model)
local UI = require(script.Parent.Components)
local Art = require(script.Parent.HudParts)
local Stats = require(script.Parent.Stats)
local Grimoire = require(script.Parent.Grimoire)
local Equipment = require(script.Parent.Equipment)
local Customization = require(script.Parent.Customization)
local Children = Fusion.Children
local pages = { Stats = Stats, Grimoire = Grimoire, Equipment = Equipment }
local titles = { Stats = "CHARACTER", Grimoire = "GRIMOIRE", Equipment = "EQUIPMENT" }

local function characterWindow(scope, state, actions)
	local tabs = {}
	for index, page in Model.Pages do
		if page == "Customization" then
			continue
		end
		local selected = scope:Computed(function(use)
			return use(state.Page) == page
		end)
		table.insert(
			tabs,
			scope:New("TextButton")({
				Name = "Tab" .. page,
				LayoutOrder = index,
				Text = string.upper(page),
				Font = Theme.PixelFont,
				TextSize = scope:Computed(function(use)
					return if use(state.Tight) then 18 else 28
				end),
				TextColor3 = scope:Computed(function(use)
					return if use(selected) then Theme.Text else Theme.Faint
				end),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Size = scope:Computed(function(use)
					return UDim2.new(if use(state.Tight) then 1 / 3 else 0, if use(state.Tight) then 0 else 166, 1, 0)
				end),
				[Fusion.OnEvent("Activated")] = function()
					actions.Open(page)
				end,
				[Children] = {
					UI.Line(scope, UDim2.new(1, -1, 0.2, 0), UDim2.new(0, 1, 0.6, 0), Theme.Line),
					UI.Frame(scope, {
						Name = "ActiveTab",
						AnchorPoint = Vector2.new(0.5, 1),
						Position = UDim2.new(0.5, 0, 1, -2),
						Size = UDim2.new(1, -38, 0, 3),
						BackgroundColor3 = Theme.Green,
						BackgroundTransparency = 0,
						Visible = selected,
					}),
				},
			})
		)
	end
	return UI.Frame(scope, {
		Name = "CharacterOverlay",
		Size = UDim2.fromScale(1, 1),
		Visible = state.Open,
		ZIndex = 10,
		[Children] = {
			scope:New("TextButton")({
				Name = "Backdrop",
				Size = UDim2.fromScale(1, 1),
				Text = "",
				AutoButtonColor = false,
				Modal = true,
				Selectable = false,
				BackgroundColor3 = Theme.HudRim,
				BackgroundTransparency = 0.67,
				BorderSizePixel = 0,
				[Fusion.OnEvent("Activated")] = actions.Close,
			}),
			UI.Frame(scope, {
				Name = "PanelDock",
				ZIndex = 2,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = scope:Computed(function(use)
					local layout = use(state.Layout)
					return UDim2.new(1, -layout.Margin * 2, 1, -layout.Margin * 2)
				end),
				[Children] = {
					scope:New("UISizeConstraint")({ MaxSize = Vector2.new(940, 648) }),
					Art.Panel(scope, {
						Name = "Shadow",
						Skin = "window",
						Position = UDim2.fromOffset(5, 6),
						Color = Theme.HudRim,
						BorderColor = Theme.HudRim,
					}),
					Art.Panel(scope, {
						Name = "CharacterPanel",
						Skin = "window",
						ZIndex = 2,
						BorderColor = Theme.Gold,
						Color = Theme.Ink,
						[Children] = {
							UI.Frame(scope, { Name = "InputShield", Size = UDim2.fromScale(1, 1), Active = true }),
							Art.Sprite(scope, {
								Name = "CloverFinial",
								ZIndex = 5,
								Icon = "Clover",
								Size = UDim2.fromOffset(22, 22),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Position = UDim2.fromScale(0.5, 0),
							}),
							UI.Frame(scope, {
								Name = "Header",
								Position = scope:Computed(function(use)
									return UDim2.fromOffset(
										use(state.Layout).PanelPadding,
										if use(state.Layout).ShortPanel then 10 else 20
									)
								end),
								Size = scope:Computed(function(use)
									local l = use(state.Layout)
									return UDim2.new(1, -l.PanelPadding * 2, 0, if l.ShortPanel then 44 else 56)
								end),
								[Children] = {
									scope:New("UIListLayout")({
										FillDirection = Enum.FillDirection.Horizontal,
										SortOrder = Enum.SortOrder.LayoutOrder,
										Padding = UDim.new(0, 16),
										VerticalAlignment = Enum.VerticalAlignment.Center,
									}),
									Art.Sprite(scope, {
										Icon = "Clover",
										LayoutOrder = 1,
										Size = scope:Computed(function(use)
											local n = if use(state.Tight) then 28 else 44
											return UDim2.fromOffset(n, n)
										end),
									}),
									UI.Frame(scope, {
										Name = "TitleGroup",
										LayoutOrder = 2,
										Size = UDim2.new(0, 0, 1, 0),
										[Children] = {
											scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
											scope:New("UIListLayout")({
												SortOrder = Enum.SortOrder.LayoutOrder,
												Padding = UDim.new(0, 4),
												VerticalAlignment = Enum.VerticalAlignment.Center,
											}),
											Art.Text(scope, {
												Name = "Title",
												LayoutOrder = 1,
												Font = Theme.PixelFont,
												TextSize = scope:Computed(function(use)
													return if use(state.Tight) then 30 else 46
												end),
												Size = UDim2.new(1, 0, 0, 34),
												Text = scope:Computed(function(use)
													return titles[use(state.Page)] or "CHARACTER"
												end),
											}),
											Art.Text(scope, {
												LayoutOrder = 2,
												Text = "C L O V E R  K I N G D O M",
												Font = Theme.CaptionFont,
												TextSize = 13,
												TextColor3 = Theme.GoldLight,
												Size = UDim2.new(1, 0, 0, 18),
												Visible = scope:Computed(function(use)
													return not use(state.Layout).ShortPanel
												end),
											}),
										},
									}),
									UI.Frame(scope, {
										Name = "CloseGroup",
										LayoutOrder = 3,
										Size = scope:Computed(function(use)
											return UDim2.fromOffset(44, if use(state.Layout).ShortPanel then 44 else 56)
										end),
										[Children] = {
											scope:New("UIListLayout")({
												SortOrder = Enum.SortOrder.LayoutOrder,
												Padding = UDim.new(0, 2),
											}),
											Art.Button(scope, {
												Name = "Close",
												LayoutOrder = 1,
												Size = UDim2.fromOffset(44, 44),
												OnActivated = actions.Close,
												[Children] = Art.Text(scope, {
													Text = "X",
													Font = Theme.PixelFont,
													TextSize = 28,
													TextXAlignment = Enum.TextXAlignment.Center,
													TextColor3 = Theme.GoldLight,
												}),
											}),
											Art.Text(scope, {
												LayoutOrder = 2,
												Text = "ESC",
												Font = Theme.CaptionFont,
												TextSize = 13,
												Size = UDim2.fromOffset(44, 12),
												Visible = scope:Computed(function(use)
													return not use(state.Layout).ShortPanel
												end),
												TextXAlignment = Enum.TextXAlignment.Center,
											}),
										},
									}),
								},
							}),
							UI.Frame(scope, {
								Name = "Tabs",
								Position = scope:Computed(function(use)
									return UDim2.fromOffset(
										use(state.Layout).PanelPadding,
										if use(state.Layout).ShortPanel then 62 else 88
									)
								end),
								Size = scope:Computed(function(use)
									return UDim2.new(1, -use(state.Layout).PanelPadding * 2, 0, 38)
								end),
								[Children] = {
									scope:New("UIStroke")({
										Color = Theme.GoldDim,
										Thickness = 1,
										ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
									}),
									UI.Frame(scope, {
										Name = "TabButtons",
										Size = UDim2.fromScale(1, 1),
										[Children] = {
											scope:New("UIListLayout")({
												FillDirection = Enum.FillDirection.Horizontal,
												SortOrder = Enum.SortOrder.LayoutOrder,
											}),
											tabs,
										},
									}),
								},
							}),
							scope:Computed(function(use, inner)
								local page = pages[use(state.Page)]
								return if page then page(inner, state, actions) else nil
							end),
						},
					}),
				},
			}),
		},
	})
end

return function(scope, state, actions)
	return scope:Computed(function(use, inner)
		if use(state.Page) == "Customization" then
			return Customization(inner, state, actions)
		end
		return characterWindow(inner, state, actions)
	end)
end
