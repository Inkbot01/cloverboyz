local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Theme = require(script.Parent.Theme)
local Model = require(script.Parent.Model)
local Layout = require(script.Parent.Layout)
local Motion = require(script.Parent.Motion)
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
	local presence = Motion.Presence(scope, state.Open)
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
			UI.Button(scope, {
				Name = "Tab" .. page,
				LayoutOrder = index,
				SelectionOrder = index,
				Text = string.upper(page),
				Font = Theme.PixelFont,
				TextSize = scope:Computed(function(use)
					return if use(state.Tight) then 18 else 30
				end),
				Size = UDim2.fromScale(0, 1),
				Variant = "Ghost",
				Selected = selected,
				HoverColor = Theme.MenuHover,
				OnActivated = function()
					actions.Open(page)
				end,
			})
		)
	end
	return scope:New("CanvasGroup")({
		Name = "CharacterOverlay",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		GroupTransparency = presence.Transparency,
		Size = UDim2.fromScale(1, 1),
		Visible = presence.Visible,
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
				Position = scope:Computed(function(use)
					return UDim2.fromScale(0.5, Layout.Window.CenterY + (1 - use(presence.Progress)) * 0.018)
				end),
				Size = scope:Computed(function(use)
					return if use(state.Layout).TouchControls
						then UDim2.fromScale(0.94, 0.90)
						else UDim2.fromScale(Layout.Window.WidthScale, Layout.Window.HeightScale)
				end),
				[Children] = {
					scope:Computed(function(use, inner)
						return if use(state.Layout).TouchControls
							then nil
							else inner:New("UIAspectRatioConstraint")({
								AspectRatio = Layout.Window.AspectRatio,
								AspectType = Enum.AspectType.FitWithinMaxSize,
							})
					end),
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
								Name = "Content",
								Size = UDim2.fromScale(1, 1),
								[Children] = {
									scope:New("UIPadding")({
										PaddingLeft = scope:Computed(function(use)
											return UDim.new(0, use(state.Layout).PanelPadding)
										end),
										PaddingRight = scope:Computed(function(use)
											return UDim.new(0, use(state.Layout).PanelPadding)
										end),
										PaddingTop = scope:Computed(function(use)
											return UDim.new(0, use(state.Layout).PanelPadding)
										end),
										PaddingBottom = scope:Computed(function(use)
											return UDim.new(0, use(state.Layout).PanelPadding)
										end),
									}),
									scope:New("UIListLayout")({
										SortOrder = Enum.SortOrder.LayoutOrder,
										Padding = scope:Computed(function(use)
											return UDim.new(0, if use(state.Layout).ShortPanel then 8 else 12)
										end),
									}),
									UI.Frame(scope, {
										Name = "Header",
										LayoutOrder = 1,
										Size = scope:Computed(function(use)
											local l = use(state.Layout)
											return UDim2.new(1, 0, 0, if l.ShortPanel then 44 else 64)
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
													local n = if use(state.Tight) then 28 else 52
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
														Padding = UDim.new(0, 0),
														VerticalAlignment = Enum.VerticalAlignment.Center,
													}),
													Art.Text(scope, {
														Name = "Title",
														LayoutOrder = 1,
														Font = Theme.PixelFont,
														TextSize = scope:Computed(function(use)
															return if use(state.Tight) then 30 else 44
														end),
														Size = scope:Computed(function(use)
															return UDim2.new(
																1,
																0,
																0,
																if use(state.Layout).ShortPanel then 38 else 44
															)
														end),
														Text = scope:Computed(function(use)
															return titles[use(state.Page)] or "CHARACTER"
														end),
													}),
													Art.Text(scope, {
														LayoutOrder = 2,
														Text = "C L O V E R  K I N G D O M",
														Font = Theme.StrongFont,
														TextSize = 18,
														TextColor3 = Theme.GoldLight,
														Size = UDim2.new(1, 0, 0, 20),
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
													return UDim2.fromOffset(
														44,
														if use(state.Layout).ShortPanel then 44 else 64
													)
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
														Font = Theme.StrongFont,
														TextSize = 18,
														Size = UDim2.fromOffset(44, 18),
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
										LayoutOrder = 2,
										Size = scope:Computed(function(use)
											return UDim2.new(1, 0, 0, if use(state.Layout).ShortPanel then 40 else 42)
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
														HorizontalFlex = Enum.UIFlexAlignment.Fill,
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
			}),
		},
	})
end

return function(scope, state, actions)
	local customizing = scope:Computed(function(use)
		return use(state.Page) == "Customization"
	end)
	return scope:Computed(function(use, inner)
		if use(customizing) then
			return Customization(inner, state, actions)
		end
		return characterWindow(inner, state, actions)
	end)
end
