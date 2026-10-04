local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Theme = require(script.Parent.Theme)
local Model = require(script.Parent.Model)
local UI = require(script.Parent.Components)
local PageLayout = require(script.Parent.PageLayout)
local Children = Fusion.Children

local function loadout(scope, state, actions)
	local slots = {}
	for index, slot in Model.EquipmentSlots do
		local item = scope:Computed(function(use)
			return Model.Find(use(state.Fields.Inventory), use(state.Fields.Equipped)[slot])
		end)
		table.insert(
			slots,
			UI.Button(scope, {
				Name = "Equipped" .. slot,
				LayoutOrder = index,
				Variant = "Quiet",
				Size = UDim2.fromScale(0, 1),
				OnActivated = function()
					local current = Fusion.peek(item)
					if current then
						actions.SelectItem(current.Id)
					end
				end,
				[Children] = {
					UI.Text(scope, {
						Text = slot,
						TextSize = 14,
						TextColor3 = Theme.Gold,
						Position = UDim2.fromOffset(12, 8),
						Size = UDim2.new(1, -24, 0, 20),
					}),
					UI.Icon(scope, {
						Icon = scope:Computed(function(use)
							local current = use(item)
							return if current then current.Icon else "Clover"
						end),
						Color = scope:Computed(function(use)
							local current = use(item)
							return if current then Theme[current.Color] or Theme.Gold else Theme.Line
						end),
						Position = UDim2.fromOffset(12, 36),
						Size = UDim2.fromOffset(24, 24),
						Visible = scope:Computed(function(use)
							return not use(state.Tight)
						end),
					}),
					UI.Text(scope, {
						Text = scope:Computed(function(use)
							local current = use(item)
							return if current then current.Name else "Empty"
						end),
						Position = scope:Computed(function(use)
							return UDim2.fromOffset(if use(state.Tight) then 8 else 46, 32)
						end),
						Size = scope:Computed(function(use)
							return UDim2.new(1, if use(state.Tight) then -16 else -54, 0, 36)
						end),
						TextSize = 15,
						Font = Theme.StrongFont,
						TextWrapped = true,
					}),
				},
			})
		)
	end
	return UI.Frame(scope, {
		Name = "Loadout",
		Size = UDim2.new(1, 0, 0, 76),
		[Children] = {
			scope:New("UIPadding")({ PaddingRight = UDim.new(0, 6) }),
			scope:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				Padding = UDim.new(0, 6),
			}),
			slots,
		},
	})
end

local function inventory(scope, state, actions)
	return UI.Frame(scope, {
		Name = "Inventory",
		Size = scope:Computed(function(use)
			return if use(state.Compact) then UDim2.new(1, -8, 0, 504) else UDim2.new(1, -328, 1, 0)
		end),
		[Children] = {
			loadout(scope, state, actions),
			UI.Panel(scope, {
				Name = "SearchSurface",
				Position = UDim2.fromOffset(0, 88),
				Size = UDim2.new(1, -6, 0, 40),
				Color = Theme.Track,
				[Children] = scope:New("TextBox")({
					Name = "SearchItems",
					Position = UDim2.fromOffset(14, 0),
					Size = UDim2.new(1, -28, 1, 0),
					BackgroundTransparency = 1,
					Text = state.ItemQuery,
					PlaceholderText = "Search your inventory…",
					PlaceholderColor3 = Theme.Faint,
					TextColor3 = Theme.Text,
					Font = Theme.BodyFont,
					TextSize = 17,
					TextXAlignment = Enum.TextXAlignment.Left,
					ClearTextOnFocus = false,
					[Fusion.OnChange("Text")] = actions.SearchItems,
				}),
			}),
			UI.Scroll(scope, {
				Name = "ItemCategories",
				Position = UDim2.fromOffset(0, 138),
				Size = UDim2.new(1, -6, 0, 46),
				AutomaticCanvasSize = Enum.AutomaticSize.X,
				ScrollingDirection = Enum.ScrollingDirection.X,
				ScrollBarThickness = 2,
				[Children] = UI.Frame(scope, {
					Size = UDim2.fromOffset(474, 44),
					[Children] = UI.Filters(scope, Model.ItemCategories, state.ItemFilter, actions.FilterItems, 94),
				}),
			}),
			UI.Scroll(scope, {
				Name = "InventoryGrid",
				Position = UDim2.fromOffset(0, 198),
				Size = UDim2.new(1, 0, 1, -198),
				[Children] = {
					scope:New("UIGridLayout")({
						CellSize = scope:Computed(function(use)
							return UDim2.new(if use(state.Tight) then 0.5 else 1 / 3, -8, 0, 118)
						end),
						CellPadding = UDim2.fromOffset(8, 8),
						FillDirectionMaxCells = scope:Computed(function(use)
							return if use(state.Tight) then 2 else 3
						end),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					scope:Computed(function(use, inner)
						local cards = {}
						for index, item in use(state.FilteredItems) do
							local selected = inner:Computed(function(read)
								local current = read(state.SelectedItem)
								return current ~= nil and current.Id == item.Id
							end)
							local equipped = inner:Computed(function(read)
								return item.Slot ~= nil and read(state.Fields.Equipped)[item.Slot] == item.Id
							end)
							local rarity = Theme[Model.RarityColors[item.Rarity]] or Theme.Muted
							table.insert(
								cards,
								UI.Button(inner, {
									Name = item.Id,
									LayoutOrder = index,
									Selected = selected,
									Color = Theme.Panel,
									Variant = "Row",
									OnActivated = function()
										actions.SelectItem(item.Id)
									end,
									[Children] = {
										UI.Icon(inner, {
											Icon = item.Icon,
											Color = Theme[item.Color] or Theme.Gold,
											Position = UDim2.new(0.5, -20, 0, 15),
											Size = UDim2.fromOffset(40, 40),
										}),
										UI.Text(inner, {
											Text = item.Name,
											Position = UDim2.fromOffset(8, 66),
											Size = UDim2.new(1, -16, 0, 40),
											TextSize = 16,
											Font = Theme.StrongFont,
											TextWrapped = true,
											TextXAlignment = Enum.TextXAlignment.Center,
										}),
										UI.Text(inner, {
											Text = "✓",
											Visible = equipped,
											Position = UDim2.fromOffset(8, 2),
											Size = UDim2.fromOffset(18, 24),
											TextSize = 20,
											TextColor3 = Theme.Green,
										}),
										UI.Text(inner, {
											Text = if item.Count > 1 then "×" .. item.Count else "",
											Position = UDim2.new(1, -44, 0, 4),
											Size = UDim2.fromOffset(36, 20),
											Font = Theme.StrongFont,
											TextSize = 15,
											TextXAlignment = Enum.TextXAlignment.Right,
											TextColor3 = Theme.GoldLight,
										}),
										UI.Icon(inner, {
											Icon = "Lock",
											Color = Theme.Faint,
											Position = UDim2.new(1, -23, 0, 7),
											Size = UDim2.fromOffset(16, 16),
											Visible = inner:Computed(function(read)
												return read(state.Fields.Level) < item.LevelRequired
											end),
										}),
										UI.Line(inner, UDim2.new(0.5, -16, 1, -2), UDim2.fromOffset(32, 2), rarity),
									},
								})
							)
						end
						return cards
					end),
				},
			}),
			UI.Text(scope, {
				Text = "No items match your search.",
				Position = UDim2.fromOffset(0, 220),
				Size = UDim2.new(1, -8, 0, 54),
				TextSize = 17,
				TextColor3 = Theme.Muted,
				TextXAlignment = Enum.TextXAlignment.Center,
				Visible = scope:Computed(function(use)
					return #use(state.FilteredItems) == 0
				end),
			}),
		},
	})
end

local function inspector(scope, state)
	local selected = state.SelectedItem
	local comparisons = {}
	for index, attribute in Model.AttributeOrder do
		local delta = scope:Computed(function(use)
			local item = use(selected)
			return if item then Model.ItemDelta(use(state.Data), item, attribute) else 0
		end)
		table.insert(
			comparisons,
			UI.Frame(scope, {
				Name = attribute,
				LayoutOrder = index,
				Size = UDim2.new(1, 0, 0, 26),
				[Children] = {
					UI.Text(
						scope,
						{ Text = attribute, TextSize = 17, TextColor3 = Theme.Muted, Size = UDim2.new(1, -116, 1, 0) }
					),
					UI.Text(scope, {
						Text = scope:Computed(function(use)
							local item = use(selected)
							return if item then string.format("%+d", item.Bonuses[attribute] or 0) else "—"
						end),
						Position = UDim2.new(1, -116, 0, 0),
						Size = UDim2.fromOffset(48, 26),
						Font = Theme.NumberFont,
						TextSize = 18,
						TextXAlignment = Enum.TextXAlignment.Right,
					}),
					UI.Text(scope, {
						Text = scope:Computed(function(use)
							return if use(delta) == 0 then "—" else string.format("%+d", use(delta))
						end),
						Position = UDim2.new(1, -52, 0, 0),
						Size = UDim2.fromOffset(52, 26),
						TextSize = 17,
						TextXAlignment = Enum.TextXAlignment.Right,
						TextColor3 = scope:Computed(function(use)
							return if use(delta) > 0
								then Theme.Green
								elseif use(delta) < 0 then Theme.Health
								else Theme.Faint
						end),
					}),
				},
			})
		)
	end
	return UI.Frame(scope, {
		Name = "ItemInspector",
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0,
		Position = scope:Computed(function(use)
			return if use(state.Compact) then UDim2.fromOffset(0, 528) else UDim2.new(1, -300, 0, 0)
		end),
		Size = scope:Computed(function(use)
			return if use(state.Compact) then UDim2.new(1, -8, 0, 458) else UDim2.new(0, 300, 1, 0)
		end),
		[Children] = UI.Scroll(scope, {
			Name = "ItemDetails",
			Position = UDim2.fromOffset(18, 16),
			Size = UDim2.new(1, -36, 1, -32),
			[Children] = UI.Frame(scope, {
				Size = UDim2.new(1, -4, 0, 424),
				[Children] = {
					UI.Text(scope, {
						Text = scope:Computed(function(use)
							local item = use(selected)
							return if item
								then string.upper(item.Rarity) .. "  /  " .. string.upper(item.Category)
								else "YOUR INVENTORY"
						end),
						Size = UDim2.new(1, 0, 0, 20),
						TextSize = 14,
						Font = Theme.StrongFont,
						TextColor3 = scope:Computed(function(use)
							local item = use(selected)
							return if item then Theme[Model.RarityColors[item.Rarity]] or Theme.Muted else Theme.Muted
						end),
					}),
					UI.Icon(scope, {
						Icon = scope:Computed(function(use)
							local item = use(selected)
							return if item then item.Icon else "Bag"
						end),
						Color = scope:Computed(function(use)
							local item = use(selected)
							return if item then Theme[item.Color] or Theme.Gold else Theme.Line
						end),
						Position = UDim2.new(0.5, -32, 0, 36),
						Size = UDim2.fromOffset(64, 64),
					}),
					UI.Text(scope, {
						Text = scope:Computed(function(use)
							local item = use(selected)
							return if item then item.Name else "An empty satchel"
						end),
						Position = UDim2.fromOffset(0, 116),
						Size = UDim2.new(1, 0, 0, 32),
						Font = Theme.StrongFont,
						TextSize = 26,
						TextXAlignment = Enum.TextXAlignment.Center,
					}),
					UI.Text(scope, {
						Text = scope:Computed(function(use)
							local item = use(selected)
							return if item
								then item.Description
								else "Collect equipment on your journey to inspect it here."
						end),
						Position = UDim2.fromOffset(0, 160),
						Size = UDim2.new(1, 0, 0, 70),
						TextSize = 17,
						TextColor3 = Theme.Muted,
						TextWrapped = true,
						TextYAlignment = Enum.TextYAlignment.Top,
					}),
					UI.Line(scope, UDim2.fromOffset(0, 238), UDim2.new(1, 0, 0, 1)),
					UI.Text(scope, {
						Text = "ITEM BONUSES",
						Font = Theme.StrongFont,
						TextSize = 14,
						TextColor3 = Theme.Gold,
						Position = UDim2.fromOffset(0, 248),
						Size = UDim2.new(1, -82, 0, 20),
					}),
					UI.Text(scope, {
						Text = "CHANGE",
						TextSize = 14,
						Position = UDim2.new(1, -70, 0, 248),
						Size = UDim2.fromOffset(70, 20),
						TextColor3 = Theme.Faint,
						TextXAlignment = Enum.TextXAlignment.Right,
					}),
					UI.Frame(scope, {
						Name = "Comparisons",
						Position = UDim2.fromOffset(0, 275),
						Size = UDim2.new(1, 0, 0, 110),
						[Children] = {
							scope:New("UIListLayout")({
								SortOrder = Enum.SortOrder.LayoutOrder,
								Padding = UDim.new(0, 2),
							}),
							comparisons,
						},
					}),
					UI.Text(scope, {
						Text = scope:Computed(function(use)
							local item = use(selected)
							if not item then
								return "Select an item to inspect it."
							end
							if not item.Slot then
								return "Crafting material · ×" .. item.Count
							end
							if use(state.Fields.Equipped)[item.Slot] == item.Id then
								return "Currently equipped"
							end
							return "Requires level " .. item.LevelRequired
						end),
						Position = UDim2.fromOffset(0, 398),
						Size = UDim2.new(1, 0, 0, 23),
						TextSize = 16,
						TextColor3 = Theme.GoldLight,
					}),
				},
			}),
		}),
	})
end

return function(scope, state, actions)
	return PageLayout(scope, state, {
		Name = "EquipmentContent",
		Body = UI.Scroll(
			scope,
			{ Name = "EquipmentScroll", [Children] = { inventory(scope, state, actions), inspector(scope, state) } }
		),
		Footer = {
			UI.Text(scope, {
				Text = "Changes compare with your equipped item.",
				TextSize = 16,
				TextColor3 = Theme.Muted,
				Size = UDim2.new(1, -200, 1, 0),
				Visible = scope:Computed(function(use)
					return not use(state.Compact)
				end),
			}),
			UI.Button(scope, {
				Name = "EquipItem",
				Variant = "Primary",
				Size = UDim2.fromOffset(180, 44),
				Position = UDim2.new(1, -180, 0, 0),
				Text = scope:Computed(function(use)
					if use(state.Busy) then
						return "Updating…"
					end
					local item = use(state.SelectedItem)
					if not item then
						return "Select an item"
					end
					if not item.Slot then
						return "Crafting material"
					end
					if use(state.Fields.Equipped)[item.Slot] == item.Id then
						return "Unequip item"
					end
					if use(state.Fields.Level) < item.LevelRequired then
						return "Requires level " .. item.LevelRequired
					end
					return "Equip item"
				end),
				Enabled = scope:Computed(function(use)
					local item = use(state.SelectedItem)
					return item ~= nil
						and item.Slot ~= nil
						and use(state.EquipmentAvailable)
						and not use(state.Busy)
						and (
							use(state.Fields.Level) >= item.LevelRequired
							or use(state.Fields.Equipped)[item.Slot] == item.Id
						)
				end),
				OnActivated = actions.EquipSelectedItem,
			}),
		},
	})
end
