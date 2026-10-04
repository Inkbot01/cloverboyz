local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Theme = require(script.Parent.Theme)
local Model = require(script.Parent.Model)
local UI = require(script.Parent.Components)
local Art = require(script.Parent.HudParts)
local PageLayout = require(script.Parent.PageLayout)
local Children = Fusion.Children
local icons = { Vitality = "Heart", Strength = "Strength", Magic = "Magic", Defense = "Shield" }

local function list(scope, horizontal, gap, alignment)
	return scope:New("UIListLayout")({
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, gap or 0),
		VerticalAlignment = alignment or Enum.VerticalAlignment.Top,
	})
end

local function caption(scope, props)
	props.Font = Theme.CaptionFont
	props.TextSize = props.TextSize or 16
	return Art.Text(scope, props)
end

local function identity(scope, state)
	local metadata = {}
	for order, entry in { { "RANK", "Rank" }, { "SQUAD", "Squad" } } do
		table.insert(
			metadata,
			UI.Frame(scope, {
				Name = entry[2],
				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, 24),
				[Children] = {
					UI.Line(scope, UDim2.new(0, 0, 1, -1), UDim2.new(1, 0, 0, 1)),
					UI.Frame(scope, {
						Size = UDim2.fromScale(1, 1),
						[Children] = {
							list(scope, true, 12),
							caption(scope, {
								LayoutOrder = 1,
								Text = entry[1],
								TextColor3 = Theme.Faint,
								Size = UDim2.new(0, 70, 1, 0),
								TextSize = 14,
							}),
							caption(scope, {
								LayoutOrder = 2,
								Text = state.Fields[entry[2]],
								Size = UDim2.new(0, 0, 1, 0),
								[Children] = scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
							}),
						},
					}),
				},
			})
		)
	end
	return UI.Frame(scope, {
		Name = "Identity",
		LayoutOrder = 1,
		Size = UDim2.new(0, 288, 1, 0),
		[Children] = {
			list(scope, false, 10),
			Art.Panel(scope, {
				Name = "PortraitCard",
				LayoutOrder = 1,
				Skin = "window",
				BorderColor = Theme.GoldDim,
				Size = UDim2.new(1, 0, 0, 0),
				[Children] = {
					scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
					Art.Sprite(scope, {
						Name = "CloverWatermark",
						Icon = "Clover",
						Size = UDim2.fromScale(0.85, 0.8),
						Position = UDim2.fromScale(0.5, 0.4),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Tint = Theme.Line,
						Transparency = 0.75,
					}),
					UI.Frame(scope, {
						Name = "PortraitContents",
						Size = UDim2.fromScale(1, 1),
						[Children] = {
							scope:New("UIPadding")({
								PaddingLeft = UDim.new(0, 12),
								PaddingRight = UDim.new(0, 12),
								PaddingTop = UDim.new(0, 12),
								PaddingBottom = UDim.new(0, 10),
							}),
							list(scope, false, 6),
							UI.Frame(scope, {
								Name = "AvatarDock",
								LayoutOrder = 1,
								Size = UDim2.new(1, 0, 0, 0),
								[Children] = {
									scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
									UI.Avatar(scope, state, { ShowFallback = false }),
								},
							}),
							Art.Text(scope, {
								Name = "PlayerName",
								LayoutOrder = 2,
								Size = UDim2.new(1, 0, 0, 30),
								Font = Theme.PixelFont,
								TextSize = scope:Computed(function(use)
									return if use(state.Tight) then 28 else 38
								end),
								TextXAlignment = Enum.TextXAlignment.Center,
								Text = scope:Computed(function(use)
									return string.upper(use(state.Fields.Name))
								end),
							}),
							UI.Frame(scope, {
								Name = "SquadBadge",
								LayoutOrder = 3,
								Size = UDim2.new(1, 0, 0, 26),
								[Children] = {
									scope:New("UIListLayout")({
										FillDirection = Enum.FillDirection.Horizontal,
										SortOrder = Enum.SortOrder.LayoutOrder,
										HorizontalAlignment = Enum.HorizontalAlignment.Center,
										VerticalAlignment = Enum.VerticalAlignment.Center,
										Padding = UDim.new(0, 8),
									}),
									Art.Sprite(
										scope,
										{ Icon = "Bull", LayoutOrder = 1, Size = UDim2.fromOffset(26, 26) }
									),
									caption(scope, {
										LayoutOrder = 2,
										Text = scope:Computed(function(use)
											return string.upper(use(state.Fields.Squad))
										end),
										AutomaticSize = Enum.AutomaticSize.X,
										Size = UDim2.fromOffset(0, 24),
										TextColor3 = Theme.Muted,
										TextSize = 16,
									}),
								},
							}),
						},
					}),
				},
			}),
			UI.Frame(scope, {
				Name = "Experience",
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 0, 44),
				[Children] = {
					list(scope, false, 6),
					UI.Frame(scope, {
						Name = "ExperienceLabels",
						LayoutOrder = 1,
						Size = UDim2.new(1, 0, 0, 20),
						[Children] = {
							list(scope, true, 8),
							caption(scope, {
								LayoutOrder = 1,
								Text = scope:Computed(function(use)
									return "LEVEL " .. use(state.Fields.Level)
								end),
								Size = UDim2.new(0, 80, 1, 0),
								TextSize = 16,
							}),
							caption(scope, {
								LayoutOrder = 2,
								Text = scope:Computed(function(use)
									return Model.FormatNumber(use(state.Fields.XP))
										.. " / "
										.. Model.FormatNumber(use(state.Fields.XPToNext))
										.. " XP"
								end),
								TextSize = 13,
								TextXAlignment = Enum.TextXAlignment.Right,
								Size = UDim2.fromScale(0, 1),
								[Children] = scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
							}),
						},
					}),
					Art.Panel(scope, {
						Name = "ExperienceTrack",
						LayoutOrder = 2,
						Cut = 2,
						Size = UDim2.new(1, 0, 0, 14),
						BorderColor = Theme.GoldDim,
						[Children] = UI.Frame(scope, {
							Name = "Clip",
							Position = UDim2.fromOffset(3, 3),
							Size = UDim2.new(1, -6, 1, -6),
							ClipsDescendants = true,
							[Children] = UI.Frame(scope, {
								Name = "Fill",
								BackgroundColor3 = Theme.Green,
								BackgroundTransparency = 0,
								Size = scope:Computed(function(use)
									return UDim2.fromScale(
										Model.Ratio(use(state.Fields.XP), use(state.Fields.XPToNext)),
										1
									)
								end),
							}),
						}),
					}),
				},
			}),
			UI.Frame(scope, {
				Name = "IdentityFields",
				LayoutOrder = 3,
				Size = UDim2.new(1, 0, 0, 48),
				[Children] = { list(scope, false, 0), metadata },
			}),
		},
	})
end

local function attribute(scope, state, actions, name, order)
	local hovered = scope:Value(false)
	local staged = scope:Computed(function(use)
		return use(state.Pending)[name] or 0
	end)
	local focused = scope:Computed(function(use)
		return use(hovered) or use(staged) > 0 or (state.FocusedAttribute and use(state.FocusedAttribute) == name)
	end)
	local enabled = scope:Computed(function(use)
		return use(state.CanAllocate) and use(state.PointsRemaining) > 0 and not use(state.Busy)
	end)
	return UI.Frame(scope, {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, -8, 0, 72),
		BackgroundTransparency = scope:Computed(function(use)
			return if use(focused) then 0.5 else 1
		end),
		BackgroundColor3 = Theme.GreenDark,
		[Fusion.OnEvent("MouseEnter")] = function()
			hovered:set(true)
		end,
		[Fusion.OnEvent("MouseLeave")] = function()
			hovered:set(false)
		end,
		[Children] = {
			scope:New("UIStroke")({
				Color = Theme.GoldDim,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Transparency = scope:Computed(function(use)
					return if use(focused) then 0.45 else 1
				end),
			}),
			UI.Line(scope, UDim2.new(0, 0, 1, -1), UDim2.new(1, 0, 0, 1)),
			UI.Frame(scope, {
				Name = "AttributeContents",
				Size = UDim2.fromScale(1, 1),
				[Children] = {
					scope:New("UIPadding")({
						PaddingLeft = UDim.new(0, 12),
						PaddingRight = UDim.new(0, 10),
						PaddingTop = UDim.new(0, 8),
						PaddingBottom = UDim.new(0, 8),
					}),
					list(
						scope,
						true,
						scope:Computed(function(use)
							return if use(state.Tight) then 8 else 16
						end),
						Enum.VerticalAlignment.Center
					),
					Art.Panel(scope, {
						Name = "IconWell",
						Skin = "well",
						LayoutOrder = 1,
						BorderColor = Theme.GoldDim,
						Size = scope:Computed(function(use)
							local n = if use(state.Tight) then 32 else 48
							return UDim2.fromOffset(n, n)
						end),
						[Children] = Art.Sprite(
							scope,
							{ Icon = icons[name], Position = UDim2.fromOffset(7, 7), Size = UDim2.new(1, -14, 1, -14) }
						),
					}),
					UI.Frame(scope, {
						Name = "Description",
						LayoutOrder = 2,
						Size = UDim2.fromScale(0, 1),
						[Children] = {
							scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
							list(scope, false, 4, Enum.VerticalAlignment.Center),
							Art.Text(scope, {
								Name = "AttributeName",
								LayoutOrder = 1,
								Text = string.upper(name),
								Font = Theme.PixelFont,
								TextSize = scope:Computed(function(use)
									return if use(state.Tight) then 24 else 28
								end),
								Size = UDim2.new(1, 0, 0, 24),
							}),
							caption(scope, {
								LayoutOrder = 2,
								Text = Model.AttributeDescriptions[name],
								TextColor3 = Theme.Muted,
								TextSize = 16,
								Size = UDim2.new(1, 0, 0, 20),
								Visible = scope:Computed(function(use)
									return not use(state.Tight)
								end),
							}),
						},
					}),
					UI.Frame(scope, {
						Name = "AttributeValue",
						LayoutOrder = 3,
						Size = scope:Computed(function(use)
							return UDim2.fromOffset(if use(state.Tight) then 40 else 64, 48)
						end),
						[Children] = {
							list(scope, false, 0, Enum.VerticalAlignment.Center),
							Art.Text(scope, {
								Name = "Value",
								LayoutOrder = 1,
								Font = Theme.PixelFont,
								TextSize = scope:Computed(function(use)
									return if use(state.Tight) then 28 else 38
								end),
								TextXAlignment = Enum.TextXAlignment.Right,
								TextColor3 = scope:Computed(function(use)
									return if use(staged) > 0 then Theme.Green else Theme.Text
								end),
								Size = UDim2.new(1, 0, 0, 30),
								Text = scope:Computed(function(use)
									local value = use(state.Fields.Attributes)[name] + use(staged)
									return if value >= 1000 then Model.FormatShort(value) else tostring(value)
								end),
							}),
							caption(scope, {
								Name = "Pending",
								LayoutOrder = 2,
								Text = scope:Computed(function(use)
									return "+" .. use(staged)
								end),
								TextColor3 = Theme.Green,
								TextXAlignment = Enum.TextXAlignment.Right,
								TextSize = 12,
								Size = UDim2.new(1, 0, 0, 14),
								Visible = scope:Computed(function(use)
									return use(staged) > 0
								end),
							}),
						},
					}),
					Art.Button(scope, {
						Name = "Add" .. name,
						LayoutOrder = 4,
						Size = UDim2.fromOffset(44, 44),
						Enabled = enabled,
						Selected = focused,
						Accent = Theme.Green,
						BorderColor = Theme.GoldDim,
						SelectionOrder = order,
						OnActivated = function()
							actions.Stage(name)
						end,
						[Children] = Art.Text(scope, {
							Text = "+",
							Font = Theme.PixelFont,
							TextSize = 36,
							TextXAlignment = Enum.TextXAlignment.Center,
							TextColor3 = Theme.GoldLight,
						}),
					}),
				},
			}),
		},
	})
end

local function overview(scope, state)
	local metrics = {}
	for order, entry in
		{
			{ "Max Health", "MaxHealth" },
			{ "Stamina", "MaxStamina" },
			{ "Max Mana", "MaxMana" },
			{ "Magic Power", "MagicPower" },
		}
	do
		table.insert(
			metrics,
			UI.Frame(scope, {
				Name = entry[2],
				LayoutOrder = order,
				[Children] = {
					list(scope, true, 8),
					caption(scope, {
						LayoutOrder = 1,
						Text = entry[1],
						TextColor3 = Theme.Muted,
						TextSize = 16,
						Size = UDim2.fromScale(0, 1),
						[Children] = scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
					}),
					caption(scope, {
						LayoutOrder = 2,
						Size = UDim2.new(0, 68, 1, 0),
						TextXAlignment = Enum.TextXAlignment.Right,
						TextSize = 18,
						Text = scope:Computed(function(use)
							return Model.FormatNumber(use(state.Fields[entry[2]]))
						end),
					}),
				},
			})
		)
	end
	return UI.Frame(scope, {
		Name = "CombatOverview",
		LayoutOrder = 5,
		Size = scope:Computed(function(use)
			return UDim2.new(1, -8, 0, if use(state.Tight) then 148 else 92)
		end),
		[Children] = {
			list(scope, false, 10),
			UI.Frame(scope, {
				Name = "SectionHeading",
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 22),
				[Children] = {
					list(scope, true, 12, Enum.VerticalAlignment.Center),
					caption(scope, {
						LayoutOrder = 1,
						Text = "COMBAT OVERVIEW",
						TextSize = 16,
						TextColor3 = Theme.Muted,
						Size = UDim2.fromOffset(166, 22),
					}),
					UI.Frame(scope, {
						LayoutOrder = 2,
						Size = UDim2.fromOffset(0, 1),
						BackgroundColor3 = Theme.GoldDim,
						BackgroundTransparency = 0,
						[Children] = scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
					}),
				},
			}),
			UI.Frame(scope, {
				Name = "Metrics",
				LayoutOrder = 2,
				Size = scope:Computed(function(use)
					return UDim2.new(1, 0, 0, if use(state.Tight) then 108 else 52)
				end),
				[Children] = {
					scope:New("UIGridLayout")({
						SortOrder = Enum.SortOrder.LayoutOrder,
						CellSize = scope:Computed(function(use)
							return if use(state.Tight) then UDim2.new(1, 0, 0, 24) else UDim2.new(0.5, -16, 0, 24)
						end),
						CellPadding = UDim2.fromOffset(32, 4),
						FillDirectionMaxCells = scope:Computed(function(use)
							return if use(state.Tight) then 1 else 2
						end),
					}),
					metrics,
				},
			}),
		},
	})
end

return function(scope, state, actions)
	local rows = {}
	for order, name in Model.AttributeOrder do
		table.insert(rows, attribute(scope, state, actions, name, order))
	end
	table.insert(rows, overview(scope, state))
	local pending = scope:Computed(function(use)
		return use(state.PendingCount) > 0
	end)
	local canApply = scope:Computed(function(use)
		return use(pending) and use(state.CanAllocate) and not use(state.Busy)
	end)
	return PageLayout(scope, state, {
		Name = "StatsContent",
		Body = {
			list(scope, true, 22),
			scope:Computed(function(use, inner)
				return if use(state.Compact) then nil else identity(inner, state)
			end),
			UI.Frame(scope, {
				Name = "Divider",
				LayoutOrder = 2,
				Size = UDim2.new(0, 1, 1, 0),
				BackgroundColor3 = Theme.GoldDim,
				BackgroundTransparency = 0.4,
				Visible = scope:Computed(function(use)
					return not use(state.Compact)
				end),
			}),
			UI.Frame(scope, {
				Name = "Attributes",
				LayoutOrder = 3,
				Size = UDim2.fromScale(0, 1),
				[Children] = {
					scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
					list(scope, false, 10),
					UI.Frame(scope, {
						Name = "AttributesHeader",
						LayoutOrder = 1,
						Size = UDim2.new(1, -8, 0, 34),
						[Children] = {
							list(scope, true, 12, Enum.VerticalAlignment.Center),
							Art.Text(scope, {
								LayoutOrder = 1,
								Text = "ATTRIBUTES",
								Font = Theme.PixelFont,
								TextSize = scope:Computed(function(use)
									return if use(state.Tight) then 24 else 32
								end),
								Size = UDim2.fromScale(0, 1),
								[Children] = scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
							}),
							Art.Panel(scope, {
								Name = "AvailablePoints",
								Skin = "key",
								LayoutOrder = 2,
								Cut = 2,
								Size = scope:Computed(function(use)
									return UDim2.fromOffset(if use(state.Tight) then 96 else 176, 28)
								end),
								BorderColor = Theme.Gold,
								[Children] = caption(scope, {
									TextSize = 14,
									TextXAlignment = Enum.TextXAlignment.Center,
									Text = scope:Computed(function(use)
										return use(state.PointsRemaining)
											.. (if use(state.Tight) then " POINTS" else " POINTS AVAILABLE")
									end),
								}),
							}),
						},
					}),
					UI.Scroll(scope, {
						Name = "AttributeList",
						LayoutOrder = 2,
						Size = UDim2.new(1, 0, 0, 0),
						[Children] = {
							scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
							list(scope, false, 0),
							rows,
						},
					}),
				},
			}),
		},
		Footer = {
			scope:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 12),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
			}),
			Art.Sprite(scope, {
				Icon = "Clover",
				LayoutOrder = 1,
				Size = UDim2.fromOffset(24, 24),
				Visible = scope:Computed(function(use)
					return not use(state.Compact)
				end),
			}),
			caption(scope, {
				Name = "Help",
				LayoutOrder = 2,
				Size = UDim2.fromScale(0, 1),
				TextSize = 14,
				TextColor3 = Theme.Faint,
				Visible = scope:Computed(function(use)
					return not use(state.Compact)
				end),
				[Children] = scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
				Text = scope:Computed(function(use)
					return if use(pending)
						then use(state.PendingCount) .. " points ready to apply."
						else "Choose an attribute to spend a point."
				end),
			}),
			Art.Button(scope, {
				Name = "Undo",
				LayoutOrder = 3,
				Size = scope:Computed(function(use)
					return UDim2.fromOffset(if use(state.Tight) then 116 else 148, 44)
				end),
				Enabled = pending,
				OnActivated = actions.Undo,
				[Children] = caption(
					scope,
					{ Text = "RESET POINTS", TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center }
				),
			}),
			Art.Button(scope, {
				Name = "Apply",
				LayoutOrder = 4,
				Size = scope:Computed(function(use)
					return UDim2.fromOffset(if use(state.Tight) then 116 else 148, 44)
				end),
				Enabled = canApply,
				Visible = pending,
				Accent = Theme.Green,
				Selected = canApply,
				OnActivated = actions.Apply,
				[Children] = caption(
					scope,
					{ Text = "APPLY POINTS", TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center }
				),
			}),
		},
	})
end
