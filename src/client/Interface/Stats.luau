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
		Padding = scope:Computed(function(use)
			return UDim.new(0, use(gap) or 0)
		end),
		VerticalAlignment = alignment or Enum.VerticalAlignment.Top,
	})
end

local function caption(scope, props)
	props.Font = props.Font or Theme.StrongFont
	props.TextSize = props.TextSize or 20
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
				Size = UDim2.new(1, 0, 0, 32),
				[Children] = {
					UI.Line(scope, UDim2.new(0, 0, 1, -1), UDim2.new(1, 0, 0, 1)),
					UI.Frame(scope, {
						Size = UDim2.fromScale(1, 1),
						[Children] = {
							list(scope, true, 12),
							caption(scope, {
								LayoutOrder = 1,
								Text = entry[1],
								TextColor3 = Theme.Muted,
								Size = UDim2.new(0, 80, 1, 0),
								TextSize = 20,
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
		Size = UDim2.new(0, 320, 1, 0),
		[Children] = {
			list(scope, false, 8),
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
								Size = UDim2.new(1, 0, 0, 44),
								Font = Theme.PixelFont,
								TextSize = scope:Computed(function(use)
									return if use(state.Tight) then 28 else 40
								end),
								TextXAlignment = Enum.TextXAlignment.Center,
								Text = scope:Computed(function(use)
									return string.upper(use(state.Fields.Name))
								end),
							}),
							UI.Frame(scope, {
								Name = "SquadBadge",
								LayoutOrder = 3,
								Size = UDim2.new(1, 0, 0, 30),
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
										Size = UDim2.fromOffset(0, 28),
										TextColor3 = Theme.Muted,
										TextSize = 22,
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
				Size = UDim2.new(1, 0, 0, 52),
				[Children] = {
					list(scope, false, 8),
					UI.Frame(scope, {
						Name = "ExperienceLabels",
						LayoutOrder = 1,
						Size = UDim2.new(1, 0, 0, 26),
						[Children] = {
							list(scope, true, 8),
							caption(scope, {
								LayoutOrder = 1,
								Text = scope:Computed(function(use)
									return "LEVEL " .. use(state.Fields.Level)
								end),
								Size = UDim2.new(0, 96, 1, 0),
								TextSize = 20,
							}),
							caption(scope, {
								LayoutOrder = 2,
								Text = scope:Computed(function(use)
									return Model.FormatNumber(use(state.Fields.XP))
										.. " / "
										.. Model.FormatNumber(use(state.Fields.XPToNext))
										.. " XP"
								end),
								TextSize = 18,
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
						Size = UDim2.new(1, 0, 0, 18),
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
				Size = UDim2.new(1, 0, 0, 64),
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
		Size = scope:Computed(function(use)
			return UDim2.new(1, -8, 0, if use(state.Tight) then 72 else 76)
		end),
		BackgroundTransparency = scope:Tween(
			scope:Computed(function(use)
				return if use(focused) then 0.5 else 1
			end),
			Theme.Fast
		),
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
				Transparency = scope:Tween(
					scope:Computed(function(use)
						return if use(focused) then 0.45 else 1
					end),
					Theme.Fast
				),
			}),
			UI.Line(scope, UDim2.new(0, 0, 1, -1), UDim2.new(1, 0, 0, 1)),
			UI.Frame(scope, {
				Name = "AttributeContents",
				Size = UDim2.fromScale(1, 1),
				[Children] = {
					scope:New("UIPadding")({
						PaddingLeft = UDim.new(0, 12),
						PaddingRight = UDim.new(0, 10),
						PaddingTop = UDim.new(0, 6),
						PaddingBottom = UDim.new(0, 6),
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
							local n = if use(state.Tight) then 36 else 56
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
									return if use(state.Tight) then 24 else 32
								end),
								Size = UDim2.new(1, 0, 0, 32),
							}),
							caption(scope, {
								LayoutOrder = 2,
								Text = Model.AttributeDescriptions[name],
								TextColor3 = Theme.Muted,
								TextSize = 22,
								Size = UDim2.new(1, 0, 0, 26),
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
							return UDim2.fromOffset(if use(state.Tight) then 44 else 80, 64)
						end),
						[Children] = {
							list(scope, false, 0, Enum.VerticalAlignment.Center),
							Art.Text(scope, {
								Name = "Value",
								LayoutOrder = 1,
								Font = Theme.PixelFont,
								TextSize = scope:Computed(function(use)
									return if use(state.Tight) then 28 else 40
								end),
								TextXAlignment = Enum.TextXAlignment.Right,
								TextColor3 = scope:Computed(function(use)
									return if use(staged) > 0 then Theme.Green else Theme.Text
								end),
								Size = UDim2.new(1, 0, 0, 44),
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
								TextSize = 16,
								Size = UDim2.new(1, 0, 0, 18),
								Visible = scope:Computed(function(use)
									return use(staged) > 0
								end),
							}),
						},
					}),
					Art.Button(scope, {
						Name = "Add" .. name,
						LayoutOrder = 4,
						Size = scope:Computed(function(use)
							local side = if use(state.Tight) then 44 else 48
							return UDim2.fromOffset(side, side)
						end),
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
						TextSize = 22,
						Size = UDim2.fromScale(0, 1),
						[Children] = scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
					}),
					caption(scope, {
						LayoutOrder = 2,
						Size = UDim2.new(0, 68, 1, 0),
						TextXAlignment = Enum.TextXAlignment.Right,
						TextSize = 24,
						Font = Theme.NumberFont,
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
			return UDim2.new(1, -8, 0, if use(state.Tight) then 180 else 100)
		end),
		[Children] = {
			list(scope, false, 8),
			UI.Frame(scope, {
				Name = "SectionHeading",
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 24),
				[Children] = {
					list(scope, true, 12, Enum.VerticalAlignment.Center),
					caption(scope, {
						LayoutOrder = 1,
						Text = "COMBAT OVERVIEW",
						TextSize = 22,
						TextColor3 = Theme.Muted,
						Size = UDim2.fromOffset(190, 24),
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
					return UDim2.new(1, 0, 0, if use(state.Tight) then 136 else 64)
				end),
				[Children] = {
					scope:New("UIGridLayout")({
						SortOrder = Enum.SortOrder.LayoutOrder,
						CellSize = scope:Computed(function(use)
							return if use(state.Tight) then UDim2.new(1, 0, 0, 28) else UDim2.new(0.5, -16, 0, 28)
						end),
						CellPadding = UDim2.fromOffset(32, 8),
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
					list(scope, false, 8),
					UI.Frame(scope, {
						Name = "AttributesHeader",
						LayoutOrder = 1,
						Size = UDim2.new(1, -8, 0, 40),
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
									return UDim2.fromOffset(if use(state.Tight) then 96 else 208, 36)
								end),
								BorderColor = Theme.Gold,
								[Children] = caption(scope, {
									TextSize = scope:Computed(function(use)
										return if use(state.Tight) then 16 else 20
									end),
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
				TextSize = 20,
				TextColor3 = Theme.Muted,
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
					return UDim2.fromOffset(if use(state.Tight) then 116 else 164, 44)
				end),
				Enabled = pending,
				OnActivated = actions.Undo,
				[Children] = caption(scope, {
					Text = scope:Computed(function(use)
						return if use(state.Tight) then "RESET" else "RESET POINTS"
					end),
					TextSize = 20,
					TextXAlignment = Enum.TextXAlignment.Center,
				}),
			}),
			Art.Button(scope, {
				Name = "Apply",
				LayoutOrder = 4,
				Size = scope:Computed(function(use)
					return UDim2.fromOffset(if use(state.Tight) then 116 else 164, 44)
				end),
				Enabled = canApply,
				Visible = pending,
				Accent = Theme.Green,
				Selected = canApply,
				OnActivated = actions.Apply,
				[Children] = caption(scope, {
					Text = scope:Computed(function(use)
						return if use(state.Tight) then "APPLY" else "APPLY POINTS"
					end),
					TextSize = 20,
					TextXAlignment = Enum.TextXAlignment.Center,
				}),
			}),
		},
	})
end
