local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local UI = require(script.Parent.Components)
local Theme = require(script.Parent.Theme)
local Model = require(script.Parent.Model)
local PageLayout = require(script.Parent.PageLayout)
local Children = Fusion.Children

local function book(scope, state)
	local grimoire = state.Fields.Grimoire
	return UI.Frame(scope, {
		Name = "GrimoireIdentity",
		Size = UDim2.new(1, 0, 0, 150),
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.Panel,
		[Children] = {
			UI.Panel(scope, {
				Name = "BookCover",
				Position = UDim2.fromOffset(16, 16),
				Size = UDim2.fromOffset(72, 100),
				BorderColor = Theme.GoldDim,
				Color = Theme.GreenDark,
				[Children] = {
					UI.Line(scope, UDim2.fromOffset(7, 0), UDim2.new(0, 1, 1, 0), Theme.GoldDim),
					UI.Line(scope, UDim2.fromOffset(18, 12), UDim2.fromOffset(38, 1), Theme.Gold),
					UI.Icon(scope, {
						Icon = "Clover",
						Position = UDim2.fromOffset(22, 34),
						Size = UDim2.fromOffset(32, 32),
						Color = Theme.GoldLight,
					}),
					UI.Line(scope, UDim2.fromOffset(18, 86), UDim2.fromOffset(38, 1), Theme.Gold),
				},
			}),
			UI.Text(scope, {
				Text = scope:Computed(function(use)
					return string.upper(use(grimoire).Affinity) .. " MAGIC"
				end),
				Position = UDim2.fromOffset(104, 16),
				Size = UDim2.new(1, -116, 0, 22),
				TextSize = 14,
				Font = Theme.StrongFont,
				TextColor3 = Theme.Green,
			}),
			UI.Text(scope, {
				Text = scope:Computed(function(use)
					return use(grimoire).Name
				end),
				Position = UDim2.fromOffset(104, 42),
				Size = UDim2.new(1, -116, 0, 50),
				TextSize = 22,
				Font = Theme.StrongFont,
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),
			UI.Text(scope, {
				Text = scope:Computed(function(use)
					local leaves = use(grimoire).Leaves
					return if leaves > 0 then leaves .. "-leaf grimoire" else "Awaiting awakening"
				end),
				Position = UDim2.fromOffset(104, 92),
				Size = UDim2.new(1, -116, 0, 22),
				TextSize = 15,
				TextColor3 = Theme.Muted,
			}),
			UI.Text(scope, {
				Text = scope:Computed(function(use)
					return "Mastery " .. use(grimoire).Mastery
				end),
				Position = UDim2.fromOffset(16, 123),
				Size = UDim2.fromOffset(105, 20),
				TextSize = 14,
				TextColor3 = Theme.Green,
			}),
			UI.Frame(scope, {
				Name = "Mastery",
				Position = UDim2.fromOffset(118, 131),
				Size = UDim2.new(1, -134, 0, 4),
				BackgroundTransparency = 0,
				BackgroundColor3 = Theme.Track,
				[Children] = UI.Frame(scope, {
					Size = scope:Computed(function(use)
						local value = use(grimoire)
						return UDim2.fromScale(Model.Ratio(value.XP, value.XPToNext), 1)
					end),
					BackgroundTransparency = 0,
					BackgroundColor3 = Theme.Green,
				}),
			}),
		},
	})
end

local function details(scope, state, actions)
	local spell = state.SelectedSpell
	local available = scope:Computed(function(use)
		return Model.SpellAvailable(use(state.Data), use(spell))
	end)
	return UI.Frame(scope, {
		Name = "SpellDetails",
		Position = scope:Computed(function(use)
			return UDim2.fromOffset(0, if use(state.Compact) then 554 else 172)
		end),
		Size = UDim2.new(1, 0, 0, 280),
		[Children] = {
			UI.Text(scope, {
				Text = "SELECTED SPELL",
				TextSize = 14,
				Font = Theme.StrongFont,
				TextColor3 = Theme.Gold,
				Size = UDim2.new(1, 0, 0, 20),
			}),
			UI.Text(scope, {
				Name = "SpellName",
				Text = scope:Computed(function(use)
					local value = use(spell)
					return if value then value.Name else "Your story begins here"
				end),
				Position = UDim2.fromOffset(0, 28),
				Size = UDim2.new(1, 0, 0, 32),
				Font = Theme.StrongFont,
				TextSize = 26,
			}),
			UI.Text(scope, {
				Text = scope:Computed(function(use)
					local value = use(spell)
					return if value then value.Description else "Receive a grimoire to discover your magic."
				end),
				Position = UDim2.fromOffset(0, 68),
				Size = UDim2.new(1, 0, 0, 86),
				TextSize = 17,
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextColor3 = Theme.Muted,
			}),
			UI.Line(scope, UDim2.fromOffset(0, 160), UDim2.new(1, 0, 0, 1)),
			UI.Text(scope, {
				Text = scope:Computed(function(use)
					local value = use(spell)
					return if value then value.ManaCost .. " mana" else ""
				end),
				Position = UDim2.fromOffset(0, 173),
				Size = UDim2.new(0.5, 0, 0, 24),
				TextSize = 18,
				Font = Theme.StrongFont,
				TextColor3 = Theme.Mana,
			}),
			UI.Text(scope, {
				Text = scope:Computed(function(use)
					local value = use(spell)
					return if value then value.Cooldown .. "s cooldown" else ""
				end),
				Position = UDim2.new(0.5, 0, 0, 173),
				Size = UDim2.new(0.5, 0, 0, 24),
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
			UI.Text(scope, {
				Text = scope:Computed(function(use)
					local value = use(spell)
					if not value then
						return ""
					end
					local slot = Model.SpellSlot(use(state.Data), value.Id)
					return if slot
						then "Equipped · Slot " .. slot
						elseif use(available) then "Learned · " .. value.Type
						elseif use(state.Fields.Level) < value.LevelRequired then "Unlocks at level "
							.. value.LevelRequired
						else "Not yet learned"
				end),
				Position = UDim2.fromOffset(0, 204),
				Size = UDim2.new(1, 0, 0, 24),
				TextSize = 16,
				TextColor3 = scope:Computed(function(use)
					return if use(available) then Theme.Green else Theme.Gold
				end),
			}),
			UI.Button(scope, {
				Name = "RemoveSpell",
				Text = "Remove from hotbar",
				TextSize = 16,
				Variant = "Quiet",
				Position = UDim2.fromOffset(0, 238),
				Size = UDim2.new(1, 0, 0, 44),
				Enabled = scope:Computed(function(use)
					local value = use(spell)
					return value ~= nil
						and Model.SpellSlot(use(state.Data), value.Id) ~= nil
						and use(state.BindingAvailable)
						and not use(state.Busy)
				end),
				OnActivated = function()
					actions.BindSelectedSpell(0)
				end,
			}),
		},
	})
end

local function spellList(scope, state, actions)
	return UI.Frame(scope, {
		Name = "SpellLibrary",
		Position = scope:Computed(function(use)
			return if use(state.Compact) then UDim2.fromOffset(0, 170) else UDim2.fromOffset(338, 0)
		end),
		Size = scope:Computed(function(use)
			return if use(state.Compact) then UDim2.new(1, -8, 0, 364) else UDim2.new(1, -338, 1, 0)
		end),
		[Children] = {
			UI.Text(
				scope,
				{ Text = "Spell library", Font = Theme.StrongFont, TextSize = 24, Size = UDim2.new(1, -100, 0, 32) }
			),
			UI.Text(scope, {
				Text = scope:Computed(function(use)
					return #use(state.Fields.Spells) .. " pages"
				end),
				Position = UDim2.new(1, -90, 0, 0),
				Size = UDim2.fromOffset(82, 32),
				TextSize = 16,
				TextColor3 = Theme.Muted,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
			UI.Frame(scope, {
				Position = UDim2.fromOffset(0, 40),
				Size = UDim2.new(1, -8, 0, 44),
				[Children] = UI.Filters(scope, Model.SpellFilters, state.SpellFilter, actions.FilterSpells),
			}),
			UI.Scroll(scope, {
				Name = "Spells",
				Position = UDim2.fromOffset(0, 96),
				Size = UDim2.new(1, 0, 1, -96),
				[Children] = {
					scope:New("UIListLayout")({ Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
					scope:Computed(function(use, inner)
						local cards = {}
						for index, spell in use(state.FilteredSpells) do
							local selected = inner:Computed(function(read)
								local value = read(state.SelectedSpell)
								return value ~= nil and value.Id == spell.Id
							end)
							local available = inner:Computed(function(read)
								return Model.SpellAvailable(read(state.Data), spell)
							end)
							table.insert(
								cards,
								UI.Button(inner, {
									Name = spell.Id,
									Variant = "Row",
									LayoutOrder = index,
									Size = UDim2.new(1, -8, 0, 76),
									Selected = selected,
									Color = Theme.Ink,
									OnActivated = function()
										actions.SelectSpell(spell.Id)
									end,
									[Children] = {
										UI.Frame(inner, {
											Name = "SelectionMark",
											Size = UDim2.new(0, 2, 1, 0),
											BackgroundColor3 = Theme.Green,
											BackgroundTransparency = 0,
											Visible = selected,
										}),
										UI.Icon(inner, {
											Icon = spell.Icon,
											Color = inner:Computed(function(read)
												return if read(available)
													then Theme[spell.Color] or Theme.Green
													else Theme.Faint
											end),
											Position = UDim2.fromOffset(14, 22),
											Size = UDim2.fromOffset(32, 32),
										}),
										UI.Text(inner, {
											Text = spell.Name,
											Position = UDim2.fromOffset(62, 12),
											Size = UDim2.new(1, -138, 0, 26),
											Font = Theme.StrongFont,
											TextSize = 21,
											TextColor3 = inner:Computed(function(read)
												return if read(available) then Theme.Text else Theme.Muted
											end),
										}),
										UI.Text(inner, {
											Text = spell.Type .. " · " .. spell.ManaCost .. " mana",
											Position = UDim2.fromOffset(62, 43),
											Size = UDim2.new(1, -138, 0, 22),
											TextSize = 16,
											TextColor3 = Theme.Muted,
										}),
										UI.Text(inner, {
											Text = inner:Computed(function(read)
												local slot = Model.SpellSlot(read(state.Data), spell.Id)
												return if slot
													then "Slot " .. slot
													elseif read(available) then "Ready"
													else "Lv. " .. spell.LevelRequired
											end),
											Position = UDim2.new(1, -74, 0, 24),
											Size = UDim2.fromOffset(58, 24),
											Font = Theme.StrongFont,
											TextSize = 16,
											TextColor3 = inner:Computed(function(read)
												return if read(available) then Theme.Green else Theme.Faint
											end),
											TextXAlignment = Enum.TextXAlignment.Right,
										}),
										UI.Line(inner, UDim2.new(0, 12, 1, -1), UDim2.new(1, -24, 0, 1)),
									},
								})
							)
						end
						if #cards == 0 then
							return UI.Text(inner, {
								Text = "No spells in this category.",
								TextSize = 17,
								TextColor3 = Theme.Muted,
								Size = UDim2.new(1, -8, 0, 80),
								TextXAlignment = Enum.TextXAlignment.Center,
							})
						end
						return cards
					end),
				},
			}),
		},
	})
end

return function(scope, state, actions)
	local slots = {}
	for slot = 2, 4 do
		table.insert(
			slots,
			UI.Button(scope, {
				Name = "ChooseSlot" .. slot,
				LayoutOrder = slot,
				Text = tostring(slot),
				TextSize = 20,
				Size = UDim2.fromOffset(44, 44),
				Selected = scope:Computed(function(use)
					return use(state.SpellTargetSlot) == slot
				end),
				OnActivated = function()
					actions.SelectSpellSlot(slot)
				end,
			})
		)
	end
	return PageLayout(scope, state, {
		Name = "GrimoireContent",
		Body = UI.Scroll(scope, {
			Name = "GrimoireScroll",
			[Children] = {
				UI.Frame(scope, {
					Name = "BookAndDetails",
					Size = scope:Computed(function(use)
						return if use(state.Compact) then UDim2.new(1, -8, 0, 842) else UDim2.new(0, 310, 0, 454)
					end),
					[Children] = { book(scope, state), details(scope, state, actions) },
				}),
				spellList(scope, state, actions),
			},
		}),
		Footer = {
			UI.Frame(scope, {
				Name = "SpellSlots",
				Size = UDim2.fromOffset(144, 44),
				[Children] = {
					scope:New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 6),
					}),
					slots,
				},
			}),
			UI.Text(scope, {
				Text = "Choose a hotbar slot",
				TextSize = 16,
				TextColor3 = Theme.Muted,
				Position = UDim2.fromOffset(164, 0),
				Size = UDim2.new(1, -340, 1, 0),
				Visible = scope:Computed(function(use)
					return not use(state.Compact)
				end),
			}),
			UI.Button(scope, {
				Name = "AssignSpell",
				Text = scope:Computed(function(use)
					return if use(state.Busy) then "Assigning…" else "Assign spell"
				end),
				Variant = "Primary",
				Position = UDim2.new(1, -136, 0, 0),
				Size = UDim2.fromOffset(136, 44),
				Enabled = scope:Computed(function(use)
					return Model.SpellAvailable(use(state.Data), use(state.SelectedSpell))
						and use(state.BindingAvailable)
						and not use(state.Busy)
				end),
				OnActivated = function()
					actions.BindSelectedSpell(Fusion.peek(state.SpellTargetSlot))
				end,
			}),
		},
	})
end
