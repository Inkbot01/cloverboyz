local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Theme = require(script.Parent.Theme)
local UI = require(script.Parent.Components)
local Art = require(script.Parent.HudParts)
local Appearance = require(script.Parent.AppearanceModel)
local AvatarAppearance = require(script.Parent.AvatarAppearance)
local Children = Fusion.Children

local function list(scope, horizontal, gap)
	return scope:New("UIListLayout")({
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, gap),
	})
end

local function padding(scope, amount)
	return scope:New("UIPadding")({
		PaddingLeft = UDim.new(0, amount),
		PaddingRight = UDim.new(0, amount),
		PaddingTop = UDim.new(0, amount),
		PaddingBottom = UDim.new(0, amount),
	})
end

local function heading(scope, title, order)
	return Art.Text(scope, {
		Name = title,
		LayoutOrder = order,
		Text = title,
		Font = Theme.CaptionFont,
		TextSize = 18,
		TextColor3 = Theme.GoldLight,
		Size = UDim2.new(1, 0, 0, 30),
	})
end

local function stepper(scope, state, actions, field, label, order)
	local editable = scope:Computed(function(use)
		return not use(state.AppearanceBusy)
	end)
	local controls = {}
	for index, direction in { -1, 1 } do
		table.insert(
			controls,
			UI.Button(scope, {
				Name = (if direction == -1 then "Previous" else "Next") .. field,
				LayoutOrder = if index == 1 then 1 else 3,
				Text = if direction == -1 then "<" else ">",
				Font = Theme.CaptionFont,
				TextSize = 24,
				Size = UDim2.fromOffset(44, 44),
				Variant = "Ghost",
				HoverColor = Theme.MenuHover,
				Enabled = scope:Computed(function(use)
					if field == "Scale" then
						local value = use(state.AppearanceDraft).Scale
						return use(editable) and (if direction < 0 then value > 0.9 else value < 1.1)
					end
					return use(editable)
				end),
				OnActivated = function()
					if field == "Scale" then
						actions.ChangeAppearance(
							"Scale",
							math.clamp(Fusion.peek(state.AppearanceDraft).Scale + direction * 0.05, 0.9, 1.1)
						)
					else
						actions.CycleAppearance(field, direction)
					end
				end,
			})
		)
	end
	return UI.Frame(scope, {
		Name = field .. "Selector",
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 76),
		[Children] = {
			list(scope, false, 6),
			Art.Text(scope, { LayoutOrder = 1, Text = label, TextSize = 19, Size = UDim2.new(1, 0, 0, 22) }),
			UI.Frame(scope, {
				Name = "Choices",
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 0, 44),
				BackgroundColor3 = Theme.MenuSurface,
				BackgroundTransparency = 0.2,
				[Children] = {
					list(scope, true, 4),
					controls,
					Art.Text(scope, {
						Name = "Selection",
						LayoutOrder = 2,
						Size = UDim2.fromScale(0, 1),
						TextSize = 18,
						TextXAlignment = Enum.TextXAlignment.Center,
						Text = scope:Computed(function(use)
							local value = use(state.AppearanceDraft)[field]
							return if field == "Scale"
								then string.format("%d%%", math.floor(value * 100 + 0.5))
								else Appearance.Option(field, value).Name
						end),
						[Children] = scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
					}),
				},
			}),
		},
	})
end

local function palette(scope, state, actions, field, title, order)
	local swatches = {}
	for index, option in Appearance.Options[field] do
		local selected = scope:Computed(function(use)
			return use(state.AppearanceDraft)[field] == option.Id
		end)
		local focused = scope:Value(false)
		table.insert(
			swatches,
			scope:New("TextButton")({
				Name = option.Name,
				LayoutOrder = index,
				Size = UDim2.fromOffset(44, 44),
				BackgroundColor3 = if option.Color then Color3.fromHex(option.Color) else Theme.MenuHover,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = if option.Color then "" else "Base",
				Font = Theme.StrongFont,
				TextSize = 15,
				TextColor3 = Theme.Text,
				Selectable = scope:Computed(function(use)
					return not use(state.AppearanceBusy)
				end),
				[Fusion.OnEvent("Activated")] = function()
					actions.ChangeAppearance(field, option.Id)
				end,
				[Fusion.OnEvent("SelectionGained")] = function()
					focused:set(true)
				end,
				[Fusion.OnEvent("SelectionLost")] = function()
					focused:set(false)
				end,
				[Fusion.OnEvent("MouseEnter")] = function()
					focused:set(true)
				end,
				[Fusion.OnEvent("MouseLeave")] = function()
					focused:set(false)
				end,
				[Children] = {
					scope:New("UIStroke")({
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Thickness = scope:Computed(function(use)
							return if use(selected) then 3 else 1
						end),
						Color = scope:Computed(function(use)
							return if use(selected) or use(focused) then Theme.HudGoldLight else Theme.GoldDim
						end),
					}),
					Art.Text(scope, {
						Text = "+",
						Font = Theme.CaptionFont,
						TextSize = 22,
						TextColor3 = Theme.Text,
						TextStrokeColor3 = Theme.HudRim,
						TextStrokeTransparency = 0,
						TextXAlignment = Enum.TextXAlignment.Center,
						Visible = scope:Computed(function(use)
							return option.Color ~= nil and use(selected)
						end),
					}),
				},
			})
		)
	end
	return UI.Frame(scope, {
		Name = field .. "Palette",
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 136),
		[Children] = {
			list(scope, false, 10),
			UI.Frame(scope, {
				Name = "LabelRow",
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 24),
				[Children] = {
					list(scope, true, 8),
					Art.Text(scope, {
						Text = title,
						TextSize = 19,
						LayoutOrder = 1,
						Size = UDim2.fromScale(0, 1),
						[Children] = scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
					}),
					Art.Text(scope, {
						LayoutOrder = 2,
						Size = UDim2.fromOffset(108, 24),
						TextSize = 16,
						TextColor3 = Theme.Muted,
						TextXAlignment = Enum.TextXAlignment.Right,
						Text = scope:Computed(function(use)
							return Appearance.Option(field, use(state.AppearanceDraft)[field]).Name
						end),
					}),
				},
			}),
			UI.Frame(scope, {
				Name = "Swatches",
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 0, 96),
				[Children] = {
					scope:New("UIGridLayout")({
						CellSize = UDim2.fromOffset(44, 44),
						CellPadding = UDim2.fromOffset(8, 8),
						FillDirectionMaxCells = 4,
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					swatches,
				},
			}),
		},
	})
end

local function options(scope, state, actions, colors)
	return UI.Scroll(scope, {
		Name = if colors then "Colors" else "Appearance",
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 3,
		[Children] = {
			padding(scope, 6),
			list(scope, false, 10),
			heading(scope, if colors then "YOUR PALETTE" else "APPEARANCE", 1),
			if colors
				then {
					palette(scope, state, actions, "SkinTone", "Skin tone", 2),
					palette(scope, state, actions, "HairColor", "Hair color", 3),
					palette(scope, state, actions, "OutfitColor", "Clothing", 4),
					Art.Text(scope, {
						LayoutOrder = 5,
						Text = "Clothing color applies to training clothes.",
						TextSize = 16,
						TextColor3 = Theme.Muted,
						TextWrapped = true,
						Size = UDim2.new(1, -8, 0, 44),
					}),
				}
				else {
					stepper(scope, state, actions, "Hair", "Hairstyle", 2),
					stepper(scope, state, actions, "Face", "Expression", 3),
					stepper(scope, state, actions, "Outfit", "Clothing", 4),
					stepper(scope, state, actions, "Accessories", "Accessories", 5),
					stepper(scope, state, actions, "Scale", "Character size", 6),
				},
		},
	})
end

local function avatar(scope, state, actions, compact)
	local rotations = {}
	for index, direction in { -1, 1 } do
		table.insert(
			rotations,
			UI.Button(scope, {
				Name = if direction < 0 then "RotateLeft" else "RotateRight",
				LayoutOrder = if index == 1 then 1 else 3,
				Size = UDim2.fromOffset(44, 44),
				Text = if direction < 0 then "<" else ">",
				TextSize = 24,
				Font = Theme.CaptionFont,
				Variant = "Ghost",
				HoverColor = Theme.MenuHover,
				OnActivated = function()
					actions.RotateAppearance(direction)
				end,
			})
		)
	end
	return UI.Frame(scope, {
		Name = "AvatarStage",
		Size = UDim2.fromScale(1, 1),
		[Children] = {
			Art.Sprite(scope, {
				Name = "CloverWatermark",
				Icon = "Clover",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.42),
				Size = UDim2.fromScale(0.72, 0.72),
				Tint = Theme.HudGold,
				Transparency = 0.94,
			}),
			UI.Frame(scope, {
				Name = "Content",
				Size = UDim2.fromScale(1, 1),
				[Children] = {
					list(scope, false, if compact then 4 else 10),
					UI.Frame(scope, {
						Name = "ViewSelector",
						LayoutOrder = 1,
						Size = UDim2.new(1, 0, 0, 44),
						[Children] = UI.Filters(scope, { "Body", "Face" }, state.PreviewFocus, function(value)
							state.PreviewFocus:set(value)
						end),
					}),
					UI.Frame(scope, {
						Name = "Character",
						LayoutOrder = 2,
						Size = UDim2.new(1, 0, 0, 0),
						[Children] = {
							scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
							UI.Avatar(scope, state, {
								ShowFallback = true,
								Appearance = state.AppearanceDraft,
								ApplyAppearance = AvatarAppearance.Apply,
								Yaw = state.PreviewRotation,
								Focus = state.PreviewFocus,
							}),
						},
					}),
					UI.Frame(scope, {
						Name = "Turntable",
						LayoutOrder = 3,
						Size = UDim2.new(1, 0, 0, 44),
						[Children] = {
							list(scope, true, 6),
							rotations,
							Art.Text(scope, {
								LayoutOrder = 2,
								Text = "ROTATE",
								Font = Theme.CaptionFont,
								TextSize = 14,
								TextColor3 = Theme.Muted,
								TextXAlignment = Enum.TextXAlignment.Center,
								Size = UDim2.fromScale(0, 1),
								[Children] = scope:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
							}),
						},
					}),
					Art.Text(scope, {
						Name = "CharacterName",
						LayoutOrder = 4,
						Text = state.Fields.Name,
						Font = Theme.PixelFont,
						TextSize = if compact then 22 else 32,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextColor3 = Theme.GoldLight,
						Size = UDim2.new(1, 0, 0, if compact then 26 else 38),
						Visible = not compact,
					}),
				},
			}),
		},
	})
end

return function(scope, state, actions)
	return UI.Frame(scope, {
		Name = "CustomizationOverlay",
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
				BackgroundTransparency = 0.24,
				BorderSizePixel = 0,
			}),
			UI.Frame(scope, {
				Name = "CustomizationDock",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				ZIndex = 2,
				Size = scope:Computed(function(use)
					local l = use(state.Layout)
					return UDim2.new(1, -l.Margin * 2, 1, -l.Margin * 2)
				end),
				[Children] = {
					scope:New("UISizeConstraint")({ MaxSize = Vector2.new(1280, 760) }),
					scope:Computed(function(use, inner)
						local l = use(state.Layout)
						local compact = l.CanvasWidth < 1000
						local portrait = compact and l.CanvasWidth < 600
						local editable = inner:Computed(function(read)
							return not read(state.AppearanceBusy)
						end)
						return Art.Panel(inner, {
							Name = "CustomizationPanel",
							Skin = "window",
							Color = Theme.MenuSurface,
							MaterialTransparency = 0.94,
							[Children] = UI.Frame(inner, {
								Name = "Content",
								Size = UDim2.fromScale(1, 1),
								Active = true,
								[Children] = {
									padding(inner, if compact then 12 else 24),
									list(inner, false, if compact then 10 else 18),
									UI.Frame(inner, {
										Name = "Header",
										LayoutOrder = 1,
										Size = UDim2.new(1, 0, 0, if compact then 44 else 72),
										[Children] = {
											list(inner, true, 16),
											Art.Sprite(inner, {
												Icon = "Clover",
												Size = UDim2.fromOffset(44, 44),
												LayoutOrder = 1,
												Visible = not compact,
											}),
											UI.Frame(inner, {
												Name = "Titles",
												LayoutOrder = 2,
												Size = UDim2.fromScale(0, 1),
												[Children] = {
													inner:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
													list(inner, false, 6),
													Art.Text(inner, {
														Text = if compact then "CUSTOMIZE" else "MAKE YOUR MARK",
														Font = Theme.PixelFont,
														TextSize = if compact then 24 else 40,
														Size = UDim2.new(1, 0, 0, if compact then 40 else 42),
														LayoutOrder = 1,
													}),
													Art.Text(inner, {
														Text = "Your story begins in the Clover Kingdom.",
														TextSize = 19,
														TextColor3 = Theme.Muted,
														Size = UDim2.new(1, 0, 0, 24),
														LayoutOrder = 2,
														Visible = not compact,
													}),
												},
											}),
											UI.Button(inner, {
												Name = "Close",
												LayoutOrder = 3,
												Size = UDim2.fromOffset(44, 44),
												Text = "X",
												TextSize = 22,
												Font = Theme.CaptionFont,
												Variant = "Ghost",
												HoverColor = Theme.MenuHover,
												OnActivated = actions.Close,
												Enabled = editable,
											}),
										},
									}),
									UI.Frame(inner, {
										Name = "Body",
										LayoutOrder = 2,
										Size = UDim2.new(1, 0, 0, 0),
										[Children] = {
											inner:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
											list(inner, not portrait, if compact then 12 else 24),
											if not compact
												then UI.Frame(inner, {
													Name = "AppearanceColumn",
													LayoutOrder = 1,
													Size = UDim2.new(0, 276, 1, 0),
													[Children] = options(inner, state, actions, false),
												})
												else nil,
											UI.Frame(inner, {
												Name = "StageColumn",
												LayoutOrder = if compact then 1 else 2,
												Size = if portrait
													then UDim2.new(1, 0, 0, if l.CanvasHeight < 650 then 180 else 264)
													elseif compact then UDim2.new(0.4, 0, 1, 0)
													else UDim2.fromScale(0, 1),
												[Children] = {
													if not compact
														then inner:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill })
														else nil,
													avatar(inner, state, actions, compact),
												},
											}),
											UI.Frame(inner, {
												Name = "DetailsColumn",
												LayoutOrder = 3,
												Size = if portrait
													then UDim2.new(1, 0, 0, 0)
													elseif compact then UDim2.fromScale(0, 1)
													else UDim2.new(0, 276, 1, 0),
												[Children] = {
													if compact
														then inner:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill })
														else nil,
													list(inner, false, 8),
													UI.Frame(inner, {
														Name = "SectionTabs",
														LayoutOrder = 1,
														Size = UDim2.new(1, 0, 0, 44),
														Visible = compact,
														[Children] = UI.Filters(
															inner,
															{ "Appearance", "Colors" },
															state.AppearanceSection,
															function(value)
																state.AppearanceSection:set(value)
															end
														),
													}),
													UI.Frame(inner, {
														Name = "Options",
														LayoutOrder = 2,
														Size = UDim2.new(1, 0, 0, 0),
														[Children] = {
															inner:New("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
															inner:Computed(function(read, content)
																return options(
																	content,
																	state,
																	actions,
																	not compact
																		or read(state.AppearanceSection) == "Colors"
																)
															end),
														},
													}),
												},
											}),
										},
									}),
									UI.Frame(inner, {
										Name = "Footer",
										LayoutOrder = 3,
										Size = UDim2.new(1, 0, 0, if compact then 44 else 56),
										[Children] = {
											list(inner, true, if compact then 8 else 12),
											UI.Button(inner, {
												Name = "ResetAppearance",
												LayoutOrder = 1,
												Size = UDim2.fromOffset(if compact then 64 else 96, 44),
												Text = "Reset",
												Variant = "Ghost",
												HoverColor = Theme.MenuHover,
												Enabled = editable,
												OnActivated = actions.ResetAppearance,
											}),
											Art.Text(inner, {
												Name = "SaveStatus",
												LayoutOrder = 2,
												Size = UDim2.fromScale(0, 1),
												TextSize = 17,
												TextColor3 = Theme.Muted,
												TextWrapped = true,
												TextTruncate = Enum.TextTruncate.AtEnd,
												Text = inner:Computed(function(read)
													local message = read(state.AppearanceMessage)
													if message ~= "" then
														return message
													end
													if compact then
														return if state.Preview then "Preview" else ""
													end
													if state.Preview then
														return "Preview only · Changes do not save to your profile."
													end
													return if read(state.AppearanceAvailable)
														then (if read(state.AppearanceDirty)
															then "Unsaved changes"
															else "Choose your appearance.")
														else "Appearance preview"
												end),
												[Children] = inner:New("UIFlexItem")({
													FlexMode = Enum.UIFlexMode.Fill,
												}),
											}),
											UI.Button(inner, {
												Name = "SaveAppearance",
												LayoutOrder = 3,
												Size = UDim2.fromOffset(if compact then 132 else 192, 44),
												Variant = "Primary",
												TextSize = if compact then 18 else 20,
												Text = inner:Computed(function(read)
													return if read(state.AppearanceBusy)
														then "Saving..."
														elseif state.Preview then "Use preview"
														elseif compact then "Save"
														else "Save appearance"
												end),
												Enabled = inner:Computed(function(read)
													return read(editable) and read(state.AppearanceAvailable)
												end),
												OnActivated = actions.SaveAppearance,
											}),
										},
									}),
								},
							}),
						})
					end),
				},
			}),
		},
	})
end
