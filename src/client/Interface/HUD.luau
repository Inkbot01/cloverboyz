local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Theme = require(script.Parent.Theme)
local Model = require(script.Parent.Model)
local UI = require(script.Parent.Components)
local Art = require(script.Parent.HudParts)
local QuickMenu = require(script.Parent.QuickMenu)
local MenuFlyout = require(script.Parent.MenuFlyout)
local Children = Fusion.Children

local function size(scope, state, name)
	return scope:Computed(function(use)
		local value = use(state.Layout)[name]
		return UDim2.fromOffset(value.Width, value.Height)
	end)
end

local function resource(scope, fields, name, color, order, compact)
	local ratio = scope:Tween(
		scope:Computed(function(use)
			return Model.Ratio(use(fields[name]), use(fields["Max" .. name]))
		end),
		Theme.BarTween
	)
	return UI.Frame(scope, {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, if compact then 24 else 54),
		[Children] = {
			scope:New("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
			UI.Frame(scope, {
				Name = "Readout",
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, if compact then 12 else 24),
				[Children] = {
					scope:New("UIPadding")({
						PaddingLeft = UDim.new(0, if compact then 4 else 8),
						PaddingRight = UDim.new(0, if compact then 4 else 8),
					}),
					scope:New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
					Art.Text(scope, {
						Name = "Label",
						LayoutOrder = 1,
						Text = string.upper(name),
						TextSize = if compact then 11 else 18,
						Font = Theme.CaptionFont,
						Size = UDim2.fromScale(0, 1),
						[Children] = scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
					}),
					Art.Text(scope, {
						Name = "Value",
						LayoutOrder = 2,
						Size = UDim2.new(0, if compact then 70 else 132, 1, 0),
						Font = Theme.NumberFont,
						TextSize = if compact then 12 else 23,
						TextXAlignment = Enum.TextXAlignment.Right,
						Text = scope:Computed(function(use)
							local maximum = use(fields["Max" .. name])
							local format = if maximum >= (if compact then 1000 else 10000)
								then Model.FormatShort
								else Model.FormatNumber
							return if maximum > 0
								then format(use(fields[name])) .. " / " .. format(maximum)
								else "— / —"
						end),
					}),
				},
			}),
			Art.Meter(scope, {
				Name = "Track",
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 0, if compact then 12 else 30),
				Skin = if compact then "slim" else "track",
				InsetY = if compact then 4 else 9,
				Color = color,
				Ratio = ratio,
			}),
		},
	})
end

local function status(scope, state)
	local fields = state.Fields
	return UI.Frame(scope, {
		Name = "Status",
		LayoutOrder = 2,
		Size = size(scope, state, "Status"),
		[Children] = scope:Computed(function(use, inner)
			local compact = use(state.Layout).CompactHUD
			local width = use(state.Layout).Status.Width
			local portraitWidth = if compact then 64 else 140
			local portraitHeight = if compact then 100 else 206
			local resourceX = portraitWidth + (if compact then 8 else 12)
			local panelY = if compact then 22 else 32
			local panelX = portraitWidth - 10
			local bars = {}
			for index, entry in
				{ { "Health", Theme.HudHealth }, { "Mana", Theme.HudMana }, { "Stamina", Theme.HudStamina } }
			do
				table.insert(bars, resource(inner, fields, entry[1], entry[2], index, compact))
			end
			return {
				inner:New("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
				UI.Frame(inner, {
					Name = "PortraitAndResources",
					LayoutOrder = 1,
					Size = UDim2.new(1, 0, 0, portraitHeight),
					[Children] = {
						Art.Panel(inner, {
							Name = "Resources",
							AnchorPoint = Vector2.new(1, 1),
							Position = UDim2.fromScale(1, 1),
							Size = UDim2.new(1, -panelX, 1, -panelY),
							Skin = if compact then "plaque" else "window",
							[Children] = UI.Frame(inner, {
								Name = "ResourceRows",
								Size = UDim2.fromScale(1, 1),
								[Children] = {
									inner:New("UIPadding")({
										PaddingLeft = UDim.new(0, resourceX - panelX),
										PaddingRight = UDim.new(0, if compact then 10 else 16),
										PaddingTop = UDim.new(0, if compact then 3 else 6),
										PaddingBottom = UDim.new(0, if compact then 3 else 6),
									}),
									inner:New("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
									bars,
								},
							}),
						}),
						UI.Frame(inner, {
							Name = "IdentityHeader",
							AnchorPoint = Vector2.new(1, 0),
							Position = UDim2.new(1, 0, 0, if compact then 1 else 0),
							Size = UDim2.new(1, -resourceX, 0, 28),
							[Children] = {
								inner:New("UIListLayout")({
									FillDirection = Enum.FillDirection.Horizontal,
									SortOrder = Enum.SortOrder.LayoutOrder,
									VerticalAlignment = Enum.VerticalAlignment.Center,
									Padding = UDim.new(0, 8),
								}),
								Art.Text(inner, {
									Name = "PlayerName",
									LayoutOrder = 1,
									Text = inner:Computed(function(read)
										return string.upper(read(fields.Name))
									end),
									AutomaticSize = Enum.AutomaticSize.X,
									Size = UDim2.fromOffset(0, 28),
									Font = Theme.PixelFont,
									TextSize = if compact then 20 else 34,
									[Children] = inner:New("UISizeConstraint")({
										MaxSize = Vector2.new(width - resourceX - 36, 28),
									}),
								}),
								UI.Icon(inner, {
									LayoutOrder = 2,
									Icon = "Clover",
									Color = Theme.HudGoldLight,
									Size = UDim2.fromOffset(24, 24),
								}),
							},
						}),
						Art.Panel(inner, {
							Name = "Portrait",
							Size = UDim2.fromOffset(portraitWidth, portraitHeight),
							Cut = if compact then 8 else 12,
							Highlight = Theme.HudGoldLight,
							[Children] = {
								UI.Avatar(inner, state, {
									Headshot = true,
									ShowFallback = false,
									Position = UDim2.fromOffset(6, 5),
									Size = UDim2.fromOffset(portraitWidth - 12, portraitHeight - 36),
								}),
								Art.Panel(inner, {
									Name = "LevelPlate",
									AnchorPoint = Vector2.new(0.5, 1),
									Position = UDim2.new(0.5, 0, 1, -5),
									Size = UDim2.fromOffset(portraitWidth - 20, 28),
									Skin = "key",
									[Children] = Art.Text(inner, {
										Name = "Level",
										Text = inner:Computed(function(read)
											return "LV. " .. read(fields.Level)
										end),
										Font = Theme.NumberFont,
										TextSize = if compact then 12 else 20,
										TextColor3 = Theme.HudGoldLight,
										TextXAlignment = Enum.TextXAlignment.Center,
									}),
								}),
							},
						}),
					},
				}),
				UI.Frame(inner, {
					Name = "ExperienceGroup",
					LayoutOrder = 2,
					Size = UDim2.new(1, 0, 0, 36),
					[Children] = {
						inner:New("UIPadding")({
							PaddingLeft = UDim.new(0, if compact then 4 else 12),
							PaddingRight = UDim.new(0, if compact then 4 else 12),
						}),
						inner:New("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }),
						Art.Meter(inner, {
							Name = "Experience",
							LayoutOrder = 1,
							Size = UDim2.new(1, 0, 0, 16),
							Skin = "slim",
							Color = Theme.HudGoldLight,
							Ratio = inner:Computed(function(read)
								return Model.Ratio(read(fields.XP), read(fields.XPToNext))
							end),
						}),
						Art.Text(inner, {
							Name = "ExperienceLabel",
							LayoutOrder = 2,
							Size = UDim2.new(1, 0, 0, 18),
							TextSize = 16,
							TextStrokeTransparency = 0.35,
							TextXAlignment = Enum.TextXAlignment.Center,
							Text = inner:Computed(function(read)
								return Model.FormatNumber(read(fields.XP))
									.. " / "
									.. Model.FormatNumber(read(fields.XPToNext))
									.. " XP"
							end),
						}),
					},
				}),
			}
		end),
	})
end

local function hotbar(scope, state, actions)
	local slots = {}
	for index = 1, 5 do
		local entry = scope:Computed(function(use)
			return use(state.Fields.Hotbar)[index]
		end)
		local selected = scope:Computed(function(use)
			return use(state.SelectedSlot) == index
		end)
		local remaining = scope:Computed(function(use)
			return math.max(0, (use(state.Cooldowns)[index] or 0) - use(state.Now))
		end)
		table.insert(
			slots,
			Art.Button(scope, {
				Name = "Slot" .. index,
				LayoutOrder = index,
				Selected = selected,
				Size = scope:Computed(function(use)
					local s = use(state.Layout).SlotSize
					return UDim2.fromOffset(s, s)
				end),
				Enabled = scope:Computed(function(use)
					return not use(state.Open)
				end),
				OnActivated = function()
					actions.ActivateSlot(index)
				end,
				[Children] = {
					Art.Text(scope, {
						Name = "SelectedAbility",
						AnchorPoint = Vector2.new(0.5, 1),
						Position = UDim2.new(0.5, 0, 0, -2),
						Size = UDim2.fromOffset(200, 24),
						Font = Theme.NumberFont,
						TextSize = 20,
						TextStrokeTransparency = 0.3,
						TextColor3 = Theme.HudGoldLight,
						TextXAlignment = Enum.TextXAlignment.Center,
						Visible = scope:Computed(function(use)
							return use(selected) and not use(state.Layout).CompactHUD
						end),
						Text = scope:Computed(function(use)
							local value = use(entry)
							return if value then string.upper(value.Name) else ""
						end),
					}),
					Art.Sprite(scope, {
						Icon = scope:Computed(function(use)
							local item = use(entry)
							if not item then
								return "Clover"
							end
							return if item.Icon == "Wind" and item.Color == "Mana"
								then "Gale"
								elseif item.Icon == "Book" then "Grimoire"
								else item.Icon
						end),
						Color = scope:Computed(function(use)
							local item = use(entry)
							return if item then Theme[item.Color] or Theme.HudGold else Theme.Line
						end),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = scope:Computed(function(use)
							local s = use(state.Layout).AbilityArt
							return UDim2.fromOffset(s, s)
						end),
					}),
					UI.Frame(scope, {
						Name = "Cooldown",
						Position = UDim2.fromOffset(4, 4),
						Size = UDim2.new(1, -8, 1, -8),
						BackgroundColor3 = Theme.HudRim,
						BackgroundTransparency = 0.3,
						Visible = scope:Computed(function(use)
							return use(remaining) > 0
						end),
						[Children] = Art.Text(scope, {
							Text = scope:Computed(function(use)
								return if use(remaining) < 10
									then string.format("%.1f", use(remaining))
									else tostring(math.ceil(use(remaining)))
							end),
							TextSize = 22,
							Font = Theme.NumberFont,
							TextXAlignment = Enum.TextXAlignment.Center,
							TextYAlignment = Enum.TextYAlignment.Bottom,
						}),
					}),
					Art.Key(scope, {
						Text = tostring(index),
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.new(0.5, 0, 1, -2),
						Color = scope:Computed(function(use)
							return if use(selected) then Theme.HudGoldLight else Theme.HudGold
						end),
					}),
				},
			})
		)
	end
	return UI.Frame(scope, {
		Name = "Hotbar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = scope:Computed(function(use)
			return UDim2.fromScale(0.5, 1)
		end),
		Size = size(scope, state, "Hotbar"),
		[Children] = {
			UI.Frame(scope, {
				Name = "AbilityRow",
				Position = UDim2.fromOffset(0, 20),
				Size = scope:Computed(function(use)
					return UDim2.new(1, 0, 0, use(state.Layout).SlotSize)
				end),
				[Children] = {
					scope:New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						Padding = scope:Computed(function(use)
							return UDim.new(0, use(state.Layout).SlotGap)
						end),
					}),
					slots,
				},
			}),
			Art.Text(scope, {
				Name = "SelectedAbility",
				Size = UDim2.new(1, 0, 0, 18),
				Visible = scope:Computed(function(use)
					return use(state.Layout).CompactHUD
				end),
				Font = Theme.NumberFont,
				TextSize = 13,
				TextColor3 = Theme.HudGoldLight,
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = scope:Computed(function(use)
					local value = use(state.Fields.Hotbar)[use(state.SelectedSlot)]
					return if value then string.upper(value.Name) else ""
				end),
			}),
			UI.Frame(scope, {
				Name = "MenuHint",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.fromOffset(94, 26),
				Visible = scope:Computed(function(use)
					return not use(state.Mobile)
				end),
				[Children] = {
					scope:New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 6),
					}),
					Art.Key(scope, { Text = "M", LayoutOrder = 1, Size = UDim2.fromOffset(30, 26) }),
					Art.Text(scope, {
						Text = "MENU",
						LayoutOrder = 2,
						Size = UDim2.fromOffset(58, 26),
						TextSize = 20,
						TextStrokeTransparency = 0.3,
					}),
				},
			}),
		},
	})
end

local function navigation(scope, state)
	local ticks = {}
	local directions = { [0] = "N", [90] = "E", [180] = "S", [270] = "W" }
	for degrees = 0, 330, 30 do
		local offset = scope:Computed(function(use)
			return (degrees - use(state.Heading) + 540) % 360 - 180
		end)
		table.insert(
			ticks,
			UI.Frame(scope, {
				Name = "Bearing" .. degrees,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = scope:Computed(function(use)
					return UDim2.new(0.5, use(offset) / 200 * (use(state.Layout).Navigation.Width - 64), 0.5, 0)
				end),
				Size = UDim2.fromOffset(40, 36),
				Visible = scope:Computed(function(use)
					return math.abs(use(offset)) <= 96
				end),
				[Children] = if directions[degrees]
					then Art.Text(scope, {
						Text = directions[degrees],
						TextSize = 28,
						Font = Theme.CaptionFont,
						TextColor3 = scope:Computed(function(use)
							return if math.abs(use(offset)) < 15 then Theme.HudGoldLight else Theme.Text
						end),
						TextXAlignment = Enum.TextXAlignment.Center,
					})
					else UI.Line(scope, UDim2.fromOffset(19, 14), UDim2.fromOffset(2, 10), Theme.HudGold),
			})
		)
	end
	return UI.Frame(scope, {
		Name = "Navigation",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = scope:Computed(function(use)
			return UDim2.new(0.5, 0, 0, use(state.Layout).Margin)
		end),
		Size = size(scope, state, "Navigation"),
		Visible = scope:Computed(function(use)
			return use(state.Layout).ShowCompass
		end),
		[Children] = {
			scope:New("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 4),
			}),
			Art.Panel(scope, {
				Name = "Compass",
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 54),
				Skin = "compass",
				[Children] = {
					ticks,
					UI.Icon(scope, {
						Name = "NorthCrest",
						Visible = scope:Computed(function(use)
							return not use(state.NavigationEnabled) or use(state.QuestHeading) == nil
						end),
						Icon = "Clover",
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.new(0.5, 0, 0, -18),
						Size = UDim2.fromOffset(32, 32),
						ZIndex = 5,
					}),
					UI.Line(scope, UDim2.new(0.5, -1, 1, -9), UDim2.fromOffset(2, 7), Theme.HudGoldLight),
					Art.Sprite(scope, {
						Name = "QuestBearing",
						Icon = "Compass",
						Size = UDim2.fromOffset(20, 24),
						AnchorPoint = Vector2.new(0.5, 0),
						Position = scope:Computed(function(use)
							local heading = use(state.QuestHeading)
							local offset = if heading then (heading - use(state.Heading) + 540) % 360 - 180 else 0
							return UDim2.new(
								0.5,
								math.clamp(offset, -96, 96) / 200 * (use(state.Layout).Navigation.Width - 64),
								0,
								-20
							)
						end),
						Visible = scope:Computed(function(use)
							return use(state.NavigationEnabled) and use(state.QuestHeading) ~= nil
						end),
						ZIndex = 6,
					}),
				},
			}),
			Art.Panel(scope, {
				Name = "Location",
				LayoutOrder = 2,
				Size = UDim2.fromOffset(300, 68),
				Skin = "plaque",
				[Children] = UI.Frame(scope, {
					Name = "LocationContent",
					Size = UDim2.fromScale(1, 1),
					[Children] = {
						scope:New("UIPadding")({
							PaddingTop = UDim.new(0, 5),
							PaddingBottom = UDim.new(0, 5),
							PaddingLeft = UDim.new(0, 16),
							PaddingRight = UDim.new(0, 16),
						}),
						scope:New("UIListLayout")({
							SortOrder = Enum.SortOrder.LayoutOrder,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							VerticalAlignment = Enum.VerticalAlignment.Center,
						}),
						Art.Text(scope, {
							Name = "VillageName",
							LayoutOrder = 1,
							Text = state.Fields.Location,
							Size = UDim2.new(1, 0, 0, 30),
							TextSize = 24,
							Font = Theme.CaptionFont,
							TextXAlignment = Enum.TextXAlignment.Center,
						}),
						UI.Frame(scope, {
							Name = "SafeZone",
							LayoutOrder = 2,
							Size = UDim2.fromOffset(150, 24),
							Visible = state.Fields.SafeZone,
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
									{ Icon = "Shield", LayoutOrder = 1, Size = UDim2.fromOffset(18, 20) }
								),
								Art.Text(scope, {
									Name = "SafeZoneLabel",
									LayoutOrder = 2,
									Text = "SAFE ZONE",
									Size = UDim2.fromOffset(112, 24),
									TextSize = 20,
									Font = Theme.CaptionFont,
									TextColor3 = Theme.Green,
								}),
							},
						}),
					},
				}),
			}),
		},
	})
end

local function body(scope, state, actions)
	return UI.Frame(scope, {
		Name = "HUD",
		Size = UDim2.fromScale(1, 1),
		[Children] = UI.Frame(scope, {
			Name = "BottomDock",
			AnchorPoint = Vector2.new(0, 1),
			Position = scope:Computed(function(use)
				local layout = use(state.Layout)
				return UDim2.new(0, layout.Margin, 1, -layout.StatusBottom)
			end),
			Size = scope:Computed(function(use)
				local layout = use(state.Layout)
				return UDim2.new(1, -layout.Margin * 2, 0, layout.HUDHeight)
			end),
			[Children] = {
				scope:New("UIListLayout")({
					FillDirection = scope:Computed(function(use)
						return if use(state.Layout).StackHUD
							then Enum.FillDirection.Vertical
							else Enum.FillDirection.Horizontal
					end),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
					Padding = scope:Computed(function(use)
						return UDim.new(0, use(state.Layout).HUDGap)
					end),
				}),
				UI.Frame(scope, {
					Name = "LeftDock",
					LayoutOrder = 1,
					Size = scope:Computed(function(use)
						local l = use(state.Layout)
						return UDim2.fromOffset(l.Status.Width, l.StatusColumnHeight)
					end),
					[Children] = {
						scope:New("UIListLayout")({
							SortOrder = Enum.SortOrder.LayoutOrder,
							VerticalAlignment = Enum.VerticalAlignment.Bottom,
							Padding = UDim.new(0, 12),
						}),
						QuickMenu(scope, state, actions),
						status(scope, state),
					},
				}),
				UI.Frame(scope, {
					Name = "AbilityDock",
					LayoutOrder = 3,
					Size = scope:Computed(function(use)
						local l = use(state.Layout)
						return if l.StackHUD then UDim2.new(1, 0, 0, l.Hotbar.Height) else UDim2.fromScale(0, 1)
					end),
					[Children] = {
						scope:New("UIFlexItem")({
							FlexMode = scope:Computed(function(use)
								return if use(state.Layout).StackHUD then Enum.UIFlexMode.None else Enum.UIFlexMode.Fill
							end),
						}),
						scope:Computed(function(use, inner)
							local l = use(state.Layout)
							local abilities = hotbar(inner, state, actions)
							abilities.LayoutOrder = 2
							return {
								abilities,
								if l.MenuAboveAbilities then MenuFlyout(inner, state, actions, true) else nil,
								if l.MenuAboveAbilities
									then inner:New("UIListLayout")({
										SortOrder = Enum.SortOrder.LayoutOrder,
										HorizontalAlignment = Enum.HorizontalAlignment.Center,
										VerticalAlignment = Enum.VerticalAlignment.Bottom,
										Padding = UDim.new(0, 8),
									})
									else nil,
							}
						end),
					},
				}),
				scope:Computed(function(use, inner)
					if not use(state.Layout).MenuBeside then
						return nil
					end
					local menu = MenuFlyout(inner, state, actions, true)
					menu.LayoutOrder = 2
					return menu
				end),
			},
		}),
	})
end

local function exploration(scope, state)
	local quest = state.Fields.Quest
	return UI.Frame(scope, {
		Name = "NavigationHUD",
		Size = UDim2.fromScale(1, 1),
		Visible = scope:Computed(function(use)
			return not use(state.Open)
		end),
		[Children] = {
			navigation(scope, state),
			UI.Frame(scope, {
				Name = "QuestDock",
				Size = UDim2.fromScale(1, 0.5),
				[Children] = {
					scope:New("UISizeConstraint")({
						MaxSize = scope:Computed(function(use)
							local layout = use(state.Layout)
							return Vector2.new(
								math.huge,
								math.max(0, layout.CanvasHeight - layout.HUDHeight - layout.StatusBottom - 24)
							)
						end),
					}),
					Art.Panel(scope, {
						Name = "QuestTracker",
						AnchorPoint = Vector2.new(0, 1),
						Position = scope:Computed(function(use)
							return UDim2.new(0, use(state.Layout).Margin, 1, 0)
						end),
						Size = size(scope, state, "Quest"),
						Skin = "window",
						Color = Theme.QuestCover,
						Visible = scope:Computed(function(use)
							return use(quest) ~= nil and use(state.Layout).ShowQuest
						end),
						[Children] = {
							Art.Sprite(scope, {
								Name = "EmbossedClover",
								Icon = "Clover",
								AnchorPoint = Vector2.new(1, 0.5),
								Position = UDim2.new(1, -18, 0.5, 0),
								Size = UDim2.fromOffset(118, 118),
								Tint = Theme.HudGold,
								Transparency = 0.94,
							}),
							UI.Frame(scope, {
								Name = "QuestContent",
								Size = UDim2.fromScale(1, 1),
								ZIndex = 2,
								[Children] = {
									scope:New("UIPadding")({
										PaddingLeft = UDim.new(0, 24),
										PaddingRight = UDim.new(0, 24),
										PaddingTop = UDim.new(0, 20),
										PaddingBottom = UDim.new(0, 20),
									}),
									scope:New("UIListLayout")({
										SortOrder = Enum.SortOrder.LayoutOrder,
										Padding = UDim.new(0, 7),
									}),
									UI.Frame(scope, {
										Name = "QuestHeading",
										LayoutOrder = 1,
										Size = UDim2.new(1, 0, 0, 24),
										[Children] = {
											scope:New("UIListLayout")({
												FillDirection = Enum.FillDirection.Horizontal,
												SortOrder = Enum.SortOrder.LayoutOrder,
												VerticalAlignment = Enum.VerticalAlignment.Center,
												Padding = UDim.new(0, 8),
											}),
											Art.Sprite(
												scope,
												{ Icon = "Clover", LayoutOrder = 1, Size = UDim2.fromOffset(24, 24) }
											),
											Art.Text(scope, {
												Name = "Category",
												LayoutOrder = 2,
												Text = "QUEST",
												Size = UDim2.fromScale(0, 1),
												Font = Theme.CaptionFont,
												TextSize = 18,
												TextColor3 = Theme.GoldLight,
												[Children] = scope:New("UIFlexItem")({
													FlexMode = Enum.UIFlexMode.Fill,
												}),
											}),
											Art.Text(scope, {
												Name = "Distance",
												LayoutOrder = 3,
												Size = UDim2.fromOffset(100, 24),
												TextSize = 22,
												Font = Theme.NumberFont,
												TextColor3 = Theme.Text,
												TextXAlignment = Enum.TextXAlignment.Right,
												Text = scope:Computed(function(use)
													local q = use(quest)
													local distance = use(state.QuestDistance)
													return if distance
														then Model.FormatShort(distance) .. " studs"
														elseif q and q.Distance then q.Distance .. " m"
														else ""
												end),
											}),
										},
									}),
									Art.Text(scope, {
										Name = "QuestTitle",
										LayoutOrder = 2,
										Size = UDim2.new(1, 0, 0, 34),
										Font = Theme.NumberFont,
										TextSize = 28,
										TextColor3 = Theme.HudGoldLight,
										Text = scope:Computed(function(use)
											local q = use(quest)
											return if q then string.upper(q.Title) else ""
										end),
									}),
									UI.Frame(scope, {
										Name = "HeadingRule",
										LayoutOrder = 3,
										Size = UDim2.new(1, 0, 0, 1),
										BackgroundTransparency = 0.3,
										BackgroundColor3 = Theme.Gold,
									}),
									Art.Text(scope, {
										Name = "Objective",
										LayoutOrder = 4,
										Size = UDim2.new(1, 0, 0, 28),
										TextSize = 24,
										Text = scope:Computed(function(use)
											local q = use(quest)
											return if q then q.Objective else ""
										end),
									}),
								},
							}),
						},
					}),
				},
			}),
		},
	})
end

return table.freeze({ Body = body, Navigation = exploration })
