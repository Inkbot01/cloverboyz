local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Theme = require(script.Parent.Theme)
local Motion = require(script.Parent.Motion)
local Assets = require(script.Parent.Assets)
local Model = require(script.Parent.Model)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Components = {}

function Components.Frame(scope, props)
	local values = { BackgroundTransparency = 1, BorderSizePixel = 0 }
	for key, value in props do
		values[key] = value
	end
	return scope:New("Frame")(values)
end

function Components.Canvas(scope, scale, children)
	return Components.Frame(scope, {
		Name = "Canvas",
		Size = scope:Computed(function(use)
			local inverse = 1 / use(scale)
			return UDim2.fromScale(inverse, inverse)
		end),
		[Children] = {
			scope:New("UIScale")({ Name = "ViewportScale", Scale = scale }),
			children,
		},
	})
end

function Components.Text(scope, props)
	local values = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Theme.BodyFont,
		TextSize = 17,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.fromScale(1, 1),
	}
	for key, value in props do
		values[key] = value
	end
	return scope:New("TextLabel")(values)
end

function Components.Line(scope, position, size, color)
	return scope:New("Frame")({
		Name = "Rule",
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Position = position,
		Size = size,
		BackgroundColor3 = color or Theme.Line,
	})
end

function Components.Panel(scope, props)
	local padding = props.Padding or 0
	return Components.Frame(scope, {
		Name = props.Name or "Panel",
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Visible = if props.Visible == nil then true else props.Visible,
		ZIndex = props.ZIndex or 1,
		BackgroundColor3 = props.Color or Theme.Ink,
		BackgroundTransparency = props.Transparency or 0,
		[Children] = {
			scope:New("UIStroke")({
				Color = props.BorderColor or Theme.Line,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Components.Frame(scope, {
				Name = "Content",
				Position = UDim2.fromOffset(padding, padding),
				Size = UDim2.new(1, -padding * 2, 1, -padding * 2),
				[Children] = props[Children],
			}),
		},
	})
end

function Components.Key(scope, props)
	return Components.Panel(scope, {
		Name = "Keycap",
		Position = props.Position,
		Size = props.Size or UDim2.fromOffset(22, 22),
		BorderColor = props.Color or Theme.GoldDim,
		Color = Theme.Track,
		Visible = props.Visible,
		[Children] = Components.Text(scope, {
			Text = props.Text,
			TextSize = 15,
			Font = Theme.StrongFont,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = props.Color or Theme.Text,
		}),
	})
end

function Components.Icon(scope, props)
	return Assets.Sprite(scope, props)
end

function Components.Button(scope, props)
	local enabled = if props.Enabled == nil then true else props.Enabled
	local interaction = Motion.Button(scope, enabled, props.OnActivated)
	local hovered = interaction.Hovered
	local selected = props.Selected or false
	local primary = props.Variant == "Primary"
	local ghost = props.Variant == "Ghost"
	local quiet = ghost or props.Variant == "Quiet" or props.Variant == "Row"
	local background = scope:Tween(
		scope:Computed(function(use)
			if use(enabled) and use(interaction.Pressed) then
				return Theme.GoldDim
			end
			if primary and use(enabled) then
				return if use(hovered) then Theme.GoldLight else Theme.Gold
			end
			if use(selected) then
				return Theme.GreenDark
			end
			return if use(hovered) and use(enabled)
				then (props.HoverColor or Theme.Raised)
				else (use(props.Color) or Theme.Panel)
		end),
		Theme.PressTween
	)
	return scope:New("TextButton")(interaction.Bind({
		Name = props.Name or "Button",
		LayoutOrder = props.LayoutOrder or 0,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = if ghost
			then scope:Tween(
				scope:Computed(function(use)
					return if use(enabled) and (use(hovered) or use(selected) or use(interaction.Pressed))
						then 0.15
						else 1
				end),
				Theme.Fast
			)
			else (if props.Variant == "Quiet" then 0.45 else 0),
		BackgroundColor3 = background,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(44, 44),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Visible = if props.Visible == nil then true else props.Visible,
		Selectable = enabled,
		SelectionOrder = props.SelectionOrder or 0,
		[Children] = {
			scope:New("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 1,
				Transparency = scope:Tween(
					scope:Computed(function(use)
						return if quiet and not use(hovered) and not use(selected) then 1 else 0
					end),
					Theme.Fast
				),
				Color = scope:Computed(function(use)
					if not use(enabled) then
						return Theme.Line
					end
					return if use(hovered)
						then Theme.GoldLight
						elseif use(selected) then Theme.Green
						else (use(props.BorderColor) or Theme.Line)
				end),
			}),
			if props.Text
				then Components.Text(scope, {
					Text = props.Text,
					Font = props.Font or Theme.StrongFont,
					TextSize = props.TextSize or 17,
					Position = UDim2.fromOffset(6, 0),
					Size = UDim2.new(1, -12, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Center,
					TextColor3 = scope:Computed(function(use)
						return if not use(enabled) then Theme.Faint elseif primary then Theme.Ink else Theme.Text
					end),
				})
				else nil,
			props[Children],
		},
	}))
end

function Components.Bar(scope, props)
	if props.Inline then
		return Components.Frame(scope, {
			Name = props.Name,
			Position = props.Position,
			Size = props.Size,
			BackgroundTransparency = 0,
			BackgroundColor3 = Theme.Track,
			[Children] = {
				Components.Frame(scope, {
					Name = "Fill",
					BackgroundTransparency = 0,
					BackgroundColor3 = props.Color:Lerp(Theme.Track, 0.36),
					Size = scope:Tween(
						scope:Computed(function(use)
							return UDim2.fromScale(Model.Ratio(use(props.Value), use(props.Maximum)), 1)
						end),
						Theme.BarTween
					),
					[Children] = Components.Line(scope, UDim2.new(), UDim2.new(1, 0, 0, 1), props.Color),
				}),
				Components.Text(scope, {
					Text = props.Label,
					Font = Theme.StrongFont,
					TextSize = 14,
					Position = UDim2.fromOffset(5, 0),
					Size = UDim2.new(0.42, -5, 1, 0),
					TextColor3 = Theme.Text,
				}),
				Components.Text(scope, {
					Name = "Value",
					Text = scope:Computed(function(use)
						local maximum = use(props.Maximum)
						return if maximum > 0
							then Model.FormatNumber(use(props.Value)) .. " / " .. Model.FormatNumber(maximum)
							else "— / —"
					end),
					Size = UDim2.new(0.58, -5, 1, 0),
					Position = UDim2.fromScale(0.42, 0),
					Font = Theme.NumberFont,
					TextSize = 15,
					TextXAlignment = Enum.TextXAlignment.Right,
				}),
			},
		})
	end
	local animated = scope:Tween(
		scope:Computed(function(use)
			return Model.Ratio(use(props.Value), use(props.Maximum))
		end),
		Theme.BarTween
	)
	return Components.Frame(scope, {
		Name = props.Name,
		Position = props.Position,
		Size = props.Size or UDim2.new(1, 0, 0, 32),
		[Children] = {
			Components.Text(scope, {
				Text = props.Label,
				Font = Theme.StrongFont,
				TextSize = 14,
				Size = UDim2.new(0.4, 0, 0, 18),
				TextColor3 = Theme.Muted,
			}),
			Components.Text(scope, {
				Name = "Value",
				Text = scope:Computed(function(use)
					local maximum = use(props.Maximum)
					return if maximum > 0
						then Model.FormatNumber(use(props.Value)) .. " / " .. Model.FormatNumber(maximum)
						else "— / —"
				end),
				Size = UDim2.new(0.6, 0, 0, 18),
				Position = UDim2.fromScale(0.4, 0),
				Font = Theme.NumberFont,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
			Components.Frame(scope, {
				Name = "Track",
				Position = UDim2.fromOffset(0, 21),
				Size = UDim2.new(1, 0, 0, if props.Name == "Health" then 10 else 7),
				BackgroundTransparency = 0,
				BackgroundColor3 = Theme.Track,
				[Children] = {
					Components.Frame(scope, {
						Name = "Fill",
						Size = scope:Computed(function(use)
							return UDim2.fromScale(use(animated), 1)
						end),
						BackgroundTransparency = 0,
						BackgroundColor3 = props.Color,
						[Children] = Components.Line(
							scope,
							UDim2.new(),
							UDim2.new(1, 0, 0, 1),
							props.Color:Lerp(Theme.Text, 0.22)
						),
					}),
				},
			}),
		},
	})
end

function Components.Avatar(scope, state, props)
	local viewportSize = scope:Value(Vector2.new(240, 320))
	local scene = scope:Computed(function(use, inner)
		use(state.CharacterRevision)
		local character = use(state.Character)
		if not character or not character.Parent then
			return nil
		end
		local oldArchivable = character.Archivable
		character.Archivable = true
		local ok, clone = pcall(function()
			return character:Clone()
		end)
		character.Archivable = oldArchivable
		if not ok or not clone then
			return nil
		end
		table.insert(inner, clone)
		for _, object in clone:GetDescendants() do
			if
				object:IsA("LuaSourceContainer")
				or object:IsA("Tool")
				or object:IsA("ParticleEmitter")
				or object:IsA("Beam")
				or object:IsA("Trail")
				or object:IsA("Light")
				or object:IsA("Highlight")
			then
				object:Destroy()
			elseif object:IsA("BasePart") then
				object.Anchored = true
				object.CanCollide = false
				object.CanTouch = false
				object.CanQuery = false
			end
		end
		for _, accessory in clone:GetChildren() do
			if accessory:IsA("Accessory") then
				local handle = accessory:FindFirstChild("Handle")
				local weld = handle and handle:FindFirstChild("AccessoryWeld")
				if handle and weld and weld:IsA("Weld") and weld.Part1 then
					handle.CFrame = weld.Part1.CFrame * weld.C1 * weld.C0:Inverse()
				elseif handle then
					local attachment = handle:FindFirstChildOfClass("Attachment")
					local targetAttachment
					if attachment then
						for _, bodyPart in clone:GetChildren() do
							if bodyPart:IsA("BasePart") then
								local match = bodyPart:FindFirstChild(attachment.Name)
								if match and match:IsA("Attachment") then
									targetAttachment = match
									break
								end
							end
						end
					end
					if targetAttachment then
						handle.CFrame = targetAttachment.WorldCFrame * attachment.CFrame:Inverse()
					else
						accessory:Destroy()
					end
				end
			end
		end
		clone:PivotTo(CFrame.Angles(0, math.pi, 0))
		local _, referenceSize = clone:GetBoundingBox()
		if props.ApplyAppearance and props.Appearance then
			props.ApplyAppearance(clone, use(props.Appearance))
			referenceSize *= 1.1
		end
		local box, size = clone:GetBoundingBox()
		local head = clone:FindFirstChild("Head")
		local camera = inner:New("Camera")({
			FieldOfView = 34,
			CFrame = inner:Computed(function(read)
				local viewport = read(viewportSize)
				local aspect = math.max(0.1, viewport.X / math.max(1, viewport.Y))
				local tangent = math.tan(math.rad(17))
				local headshot = props.Headshot or read(props.Focus) == "Face"
				local target = if headshot and head then head.Position + Vector3.new(0, 0.12, 0) else box.Position
				local framing = if props.Appearance then referenceSize else size
				local distance = if headshot
					then 3.6
					else math.max(framing.Y / (2 * tangent), framing.X / (2 * tangent * aspect)) * 1.08
						+ framing.Z * 0.35
				local angle = math.rad(read(props.Yaw) or 0)
				return CFrame.lookAt(
					target + Vector3.new(math.sin(angle) * distance, 0.12, math.cos(angle) * distance),
					target
				)
			end),
		})
		local world = inner:New("WorldModel")({ [Children] = clone })
		return { Camera = camera, World = world }
	end)
	return Components.Frame(scope, {
		Name = "Avatar",
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		[Children] = {
			Components.Icon(scope, {
				Icon = "Clover",
				Color = Theme.Line,
				Visible = scope:Computed(function(use)
					return props.ShowFallback ~= false and use(scene) == nil
				end),
				Size = UDim2.fromScale(0.7, 0.7),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
			}),
			scope:New("ViewportFrame")({
				Name = "CharacterPreview",
				ZIndex = 2,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				[Fusion.Out("AbsoluteSize")] = viewportSize,
				Ambient = Color3.fromRGB(190, 190, 190),
				LightColor = Color3.fromRGB(255, 239, 207),
				LightDirection = Vector3.new(-1, -0.5, -1),
				CurrentCamera = scope:Computed(function(use)
					local current = use(scene)
					return if current then current.Camera else nil
				end),
				[Children] = scope:Computed(function(use)
					local current = use(scene)
					return if current then { current.World, current.Camera } else nil
				end),
			}),
		},
	})
end

function Components.Scroll(scope, props)
	local values = {
		Name = "Scroll",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.GoldDim,
	}
	for key, value in props do
		values[key] = value
	end
	return scope:New("ScrollingFrame")(values)
end

function Components.Filters(scope, choices, selected, onSelect, cellWidth)
	local buttons = {}
	for index, choice in choices do
		local active = scope:Computed(function(use)
			return use(selected) == choice
		end)
		table.insert(
			buttons,
			Components.Button(scope, {
				Name = "Filter" .. choice,
				LayoutOrder = index,
				Variant = "Quiet",
				Size = UDim2.new(0, cellWidth or 0, 1, 0),
				Text = choice,
				TextSize = 16,
				OnActivated = function()
					onSelect(choice)
				end,
				[Children] = Components.Frame(scope, {
					Name = "SelectedRule",
					Position = UDim2.new(0, 12, 1, -2),
					Size = UDim2.new(1, -24, 0, 2),
					BackgroundTransparency = 0,
					BackgroundColor3 = Theme.Green,
					Visible = active,
				}),
			})
		)
	end
	return Components.Frame(scope, {
		Name = "FilterButtons",
		Size = UDim2.fromScale(1, 1),
		[Children] = {
			scope:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalFlex = if cellWidth then Enum.UIFlexAlignment.None else Enum.UIFlexAlignment.Fill,
			}),
			buttons,
		},
	})
end

return Components
