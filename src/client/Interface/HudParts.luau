local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Theme = require(script.Parent.Theme)
local UI = require(script.Parent.Components)
local Assets = require(script.Parent.Assets)
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Parts = {}

function Parts.Panel(scope, props)
	local cut = props.Cut or 4
	local skin = props.Skin or (if cut <= 2 then "track" elseif cut >= 8 then "portrait" else "control")
	return UI.Frame(scope, {
		Name = props.Name or "PixelPanel",
		LayoutOrder = props.LayoutOrder or 0,
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Visible = if props.Visible == nil then true else props.Visible,
		ZIndex = props.ZIndex or 1,
		[Children] = {
			Assets.Skin(scope, skin, "fill", props.Color or Theme.HudInk, props.MaterialTransparency),
			Assets.Skin(scope, skin, "trim", props.BorderColor or Theme.HudGold),
			props[Children],
		},
	})
end

function Parts.Text(scope, props)
	local values = { Font = Theme.StrongFont, TextSize = 16, TextColor3 = Theme.Text, TextStrokeTransparency = 1 }
	for key, value in props do
		values[key] = value
	end
	return UI.Text(scope, values)
end

Parts.Sprite = Assets.Sprite

function Parts.Meter(scope, props)
	local slim = props.Skin == "slim"
	local insetX = if slim then 12 else 28
	local insetY = props.InsetY or (if slim then 5 else 9)
	return Parts.Panel(scope, {
		Name = props.Name or "Track",
		LayoutOrder = props.LayoutOrder,
		Size = props.Size,
		Skin = if slim then "slim" else "track",
		Color = Theme.Track,
		[Children] = UI.Frame(scope, {
			Name = "ProgressClip",
			Position = UDim2.fromOffset(insetX, insetY),
			Size = UDim2.new(1, -insetX * 2, 1, -insetY * 2),
			ClipsDescendants = true,
			BackgroundTransparency = 0,
			BackgroundColor3 = Theme.Track,
			[Children] = UI.Frame(scope, {
				Name = "Fill",
				Size = scope:Computed(function(use)
					return UDim2.fromScale(math.clamp(use(props.Ratio), 0, 1), 1)
				end),
				BackgroundTransparency = 0,
				BackgroundColor3 = props.Color,
				[Children] = {
					scope:New("UIGradient")({
						Rotation = 90,
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
							ColorSequenceKeypoint.new(0.45, Color3.new(0.94, 0.94, 0.94)),
							ColorSequenceKeypoint.new(1, Color3.new(0.65, 0.65, 0.65)),
						}),
					}),
					UI.Line(scope, UDim2.new(), UDim2.new(1, 0, 0, 1), props.Color:Lerp(Theme.Text, 0.42)),
				},
			}),
		}),
	})
end

function Parts.Key(scope, props)
	return Parts.Panel(scope, {
		Name = "Keycap",
		LayoutOrder = props.LayoutOrder,
		AnchorPoint = props.AnchorPoint,
		Size = props.Size or UDim2.fromOffset(30, 26),
		Position = props.Position,
		Visible = props.Visible,
		Skin = "key",
		BorderColor = props.Color or Theme.HudGold,
		[Children] = Parts.Text(
			scope,
			{ Text = props.Text, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center }
		),
	})
end

function Parts.Button(scope, props)
	local hovered = scope:Value(false)
	local selected = props.Selected or false
	local enabled = if props.Enabled == nil then true else props.Enabled
	local surfaceColor = scope:Computed(function(use)
		return if use(enabled) and (use(hovered) or use(selected)) then Theme.Panel else Theme.HudInk
	end)
	local border = scope:Computed(function(use)
		if not use(enabled) then
			return Theme.GoldDim
		end
		if use(hovered) or use(selected) then
			return props.Accent or Theme.HudGoldLight
		end
		return props.BorderColor or Theme.HudGold
	end)
	return scope:New("TextButton")({
		Name = props.Name or "HudButton",
		LayoutOrder = props.LayoutOrder or 0,
		Text = "",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Selectable = enabled,
		SelectionOrder = props.SelectionOrder or 0,
		Position = props.Position or UDim2.new(),
		Size = props.Size or UDim2.fromOffset(56, 56),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Visible = if props.Visible == nil then true else props.Visible,
		[OnEvent("MouseEnter")] = function()
			hovered:set(true)
		end,
		[OnEvent("MouseLeave")] = function()
			hovered:set(false)
		end,
		[OnEvent("SelectionGained")] = function()
			hovered:set(true)
		end,
		[OnEvent("SelectionLost")] = function()
			hovered:set(false)
		end,
		[OnEvent("Activated")] = function()
			if Fusion.peek(enabled) and props.OnActivated then
				props.OnActivated()
			end
		end,
		[Children] = {
			scope:Computed(function(use, inner)
				local dimensions = use(props.Size) or UDim2.fromOffset(56, 56)
				local small = dimensions.Y.Scale == 0 and dimensions.Y.Offset < 54
				local skin = props.Skin or (if small then "plaque" else "control")
				return {
					Assets.Skin(inner, skin, "fill", surfaceColor),
					Assets.Skin(inner, skin, "trim", border),
				}
			end),
			props[Children],
			if props.Tooltip
				then Parts.Text(scope, {
					Name = "Tooltip",
					Text = props.Tooltip,
					TextSize = 14,
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 0, -6),
					Size = UDim2.fromOffset(120, 20),
					TextXAlignment = Enum.TextXAlignment.Center,
					Visible = hovered,
					TextStrokeTransparency = 0.15,
					TextStrokeColor3 = Theme.HudRim,
				})
				else nil,
		},
	})
end

return table.freeze(Parts)
