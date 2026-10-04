local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Published = require(game:GetService("ReplicatedStorage").Shared.Assets.UI)
local StudioImages = require(game:GetService("ReplicatedStorage").Shared.Assets.StudioImages)
local Theme = require(script.Parent.Theme)
local Config = require(script.Parent.Config)
local studioArtwork = game:GetService("RunService"):IsStudio() and Config.UseStudioArtwork
local Assets = {}
local icons = {
	Sword = 1,
	Wind = 2,
	Grimoire = 3,
	CrossedBlades = 4,
	Potion = 5,
	Coin = 6,
	Gem = 7,
	Character = 8,
	Person = 8,
	Book = 9,
	Bag = 10,
	Heart = 11,
	Strength = 12,
	Magic = 13,
	Shield = 14,
	Clover = 15,
	Bull = 16,
	Gale = 13,
	Armor = 14,
	Boots = 14,
	Ring = 7,
	Ore = 7,
	Crystal = 7,
}
local rectangles = {
	{ 36, 47, 293, 325 },
	{ 347, 65, 603, 318 },
	{ 666, 65, 914, 323 },
	{ 972, 65, 1206, 312 },
	{ 89, 363, 251, 598 },
	{ 367, 376, 577, 596 },
	{ 711, 363, 848, 608 },
	{ 997, 376, 1180, 584 },
	{ 33, 686, 305, 892 },
	{ 370, 666, 597, 885 },
	{ 685, 691, 889, 874 },
	{ 986, 667, 1199, 886 },
	{ 70, 962, 267, 1182 },
	{ 381, 949, 563, 1193 },
	{ 680, 957, 891, 1186 },
	{ 961, 935, 1219, 1196 },
}
local skins = {
	control = {
		Fill = "control",
		Art = "ornate-frame-v2",
		Slice = Rect.new(192, 192, 320, 317),
		Scale = 0.14,
		Inset = 5,
	},
	portrait = {
		Fill = "portrait",
		Art = "ornate-frame-v2",
		Slice = Rect.new(192, 192, 320, 317),
		Scale = 0.20,
		Inset = 7,
	},
	window = { Fill = "window", Art = "ornate-frame-v2", Slice = Rect.new(192, 192, 320, 317), Scale = 0.20, Inset = 7 },
	plaque = {
		Fill = "control",
		Art = "ornate-frame-v2",
		Slice = Rect.new(192, 192, 320, 317),
		Scale = 0.10,
		Inset = 4,
	},
	compass = {
		Fill = "control",
		Art = "ornate-frame-v2",
		Slice = Rect.new(192, 192, 320, 317),
		Scale = 0.13,
		Inset = 5,
	},
	well = { Fill = "control", Art = "ornate-frame-v2", Slice = Rect.new(192, 192, 320, 317), Scale = 0.06, Inset = 2 },
	key = { Fill = "track", Art = "ornate-frame-v2", Slice = Rect.new(192, 192, 320, 317), Scale = 0.04, Inset = 2 },
	track = { Fill = "track", Art = "ornate-meter-v2", Slice = Rect.new(160, 70, 864, 110), Scale = 0.16, Inset = 4 },
	slim = { Fill = "track", Art = "ornate-meter-v2", Slice = Rect.new(160, 70, 864, 110), Scale = 0.075, Inset = 2 },
	meter = { Fill = "track", Art = "ornate-meter-v2", Slice = Rect.new(160, 70, 864, 110), Scale = 0.16, Inset = 4 },
}
local fillSlices = {
	control = Rect.new(6, 6, 26, 26),
	portrait = Rect.new(24, 24, 72, 72),
	window = Rect.new(24, 24, 72, 72),
	track = Rect.new(3, 3, 13, 13),
}

local function editorImages()
	local module = script.Parent:FindFirstChild("EditorImages")
	if module and game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning() then
		return require(module)
	end
	return nil
end

function Assets.Source(name)
	local images = editorImages()
	if images and images[name] then
		return Content.fromObject(images[name])
	end
	local image = if studioArtwork or not Published[name] then StudioImages.Get(name) else nil
	if image then
		return Content.fromObject(image)
	end
	return if Published[name] then Content.fromUri(Published[name]) else Content.none
end

function Assets.Sprite(scope, props)
	local rectangle = scope:Computed(function(use)
		if use(props.Icon) == "Compass" then
			return { Content = Assets.Source("compass-icon-v1"), Offset = Vector2.zero, Size = Vector2.zero }
		end
		local index = (icons[use(props.Icon)] or 15) - 1
		local images = editorImages()
		local preview = (images and images["icon-" .. (index + 1)])
			or (
				if studioArtwork or not Published["clover-icons-v1"]
					then StudioImages.Get("icon-" .. (index + 1))
					else nil
			)
		if preview then
			return { Content = Content.fromObject(preview), Offset = Vector2.zero, Size = Vector2.zero }
		end
		local rect = rectangles[index + 1]
		return {
			Content = Assets.Source("clover-icons-v1"),
			Offset = Vector2.new(rect[1], rect[2]),
			Size = Vector2.new(rect[3] - rect[1], rect[4] - rect[2]),
		}
	end)
	return scope:New("ImageLabel")({
		Name = props.Name or "Icon",
		LayoutOrder = props.LayoutOrder or 0,
		Size = props.Size or UDim2.fromOffset(32, 32),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ImageContent = scope:Computed(function(use)
			return use(rectangle).Content
		end),
		ImageRectOffset = scope:Computed(function(use)
			return use(rectangle).Offset
		end),
		ImageRectSize = scope:Computed(function(use)
			return use(rectangle).Size
		end),
		ScaleType = Enum.ScaleType.Fit,
		ResampleMode = Enum.ResamplerMode.Pixelated,
		ImageColor3 = props.Tint or Color3.new(1, 1, 1),
		ImageTransparency = props.Transparency or 0,
		Visible = if props.Visible == nil then true else props.Visible,
		ZIndex = props.ZIndex or 1,
		[Fusion.Children] = props[Fusion.Children],
	})
end

function Assets.Skin(scope, skin, layer, color, materialTransparency)
	local definition = assert(skins[skin], "Unknown interface skin")
	local trim = layer == "trim"
	local inset = if trim then 0 else definition.Inset
	local material = not trim and definition.Art == "ornate-frame-v2" and skin ~= "key"
	local textureInset = if skin == "portrait" then 16 elseif skin == "window" then 8 else 4
	return scope:New("ImageLabel")({
		Name = if trim then "Trim" else "Surface",
		Position = UDim2.fromOffset(inset, inset),
		Size = UDim2.new(1, -inset * 2, 1, -inset * 2),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ImageContent = Assets.Source(if trim then definition.Art else definition.Fill .. "-fill"),
		ImageColor3 = if trim
			then scope:Computed(function(use)
				local tint = use(color)
				if tint == Theme.Green then
					return Color3.fromRGB(172, 255, 194)
				end
				if tint == Theme.HudRim then
					return Color3.fromRGB(18, 22, 24)
				end
				if tint == Theme.GoldDim or tint == Theme.HudGoldShade then
					return Color3.fromRGB(170, 174, 169)
				end
				return if tint == Theme.HudGoldLight or tint == Theme.GoldLight
					then Color3.new(1, 1, 1)
					else Color3.fromRGB(224, 226, 222)
			end)
			else color,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = if trim then definition.Slice else fillSlices[definition.Fill],
		SliceScale = if trim then definition.Scale else 1,
		ResampleMode = Enum.ResamplerMode.Pixelated,
		ZIndex = if trim then 4 else 0,
		[Fusion.Children] = if material
			then {
				scope:New("UIGradient")({
					Rotation = 90,
					Color = ColorSequence.new(Color3.new(1, 1, 0.96), Color3.new(0.52, 0.62, 0.60)),
				}),
				scope:New("ImageLabel")({
					Name = "GrimoireLeather",
					Position = UDim2.fromOffset(textureInset, textureInset),
					Size = UDim2.new(1, -textureInset * 2, 1, -textureInset * 2),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ImageContent = Assets.Source("grimoire-leather-v1"),
					ImageColor3 = scope:Computed(function(use)
						return use(color):Lerp(Color3.new(1, 1, 1), 0.18)
					end),
					ImageTransparency = materialTransparency or 0.68,
					ScaleType = Enum.ScaleType.Tile,
					TileSize = UDim2.fromOffset(160, 160),
					ResampleMode = Enum.ResamplerMode.Pixelated,
					ZIndex = 0,
					Visible = scope:Computed(function(use)
						return use(color) ~= Theme.HudRim
					end),
					[Fusion.Children] = scope:New("UIGradient")({
						Rotation = 90,
						Color = ColorSequence.new(Color3.new(1, 1, 0.96), Color3.new(0.52, 0.62, 0.60)),
					}),
				}),
			}
			else nil,
	})
end

return table.freeze(Assets)
