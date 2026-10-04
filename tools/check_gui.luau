local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local process = require("@lune/process")
local directory = process.args[1] or "output/ui-previews/aligned"
local checked = 0
local properties = 0
local layoutGroups = 0
local enumNames = {
	Font = "Font",
	TextXAlignment = "TextXAlignment",
	TextYAlignment = "TextYAlignment",
	TextTruncate = "TextTruncate",
	AutomaticSize = "AutomaticSize",
	AutomaticCanvasSize = "AutomaticSize",
	ScrollingDirection = "ScrollingDirection",
	FillDirection = "FillDirection",
	SortOrder = "SortOrder",
	HorizontalAlignment = "HorizontalAlignment",
	VerticalAlignment = "VerticalAlignment",
	HorizontalFlex = "UIFlexAlignment",
	VerticalFlex = "UIFlexAlignment",
	FlexMode = "UIFlexMode",
	ApplyStrokeMode = "ApplyStrokeMode",
	ScaleType = "ScaleType",
	ResampleMode = "ResamplerMode",
}

local function decode(key, value)
	if type(value) == "table" then
		if value.type == "Color3" then
			return roblox.Color3.fromRGB(value.r, value.g, value.b)
		end
		if value.type == "UDim2" then
			return roblox.UDim2.new(value.xs, value.xo, value.ys, value.yo)
		end
		if value.type == "UDim" then
			return roblox.UDim.new(value.scale, value.offset)
		end
		if value.type == "Vector2" then
			return roblox.Vector2.new(value.x, value.y)
		end
		if value.type == "Vector3" then
			return roblox.Vector3.new(value.x, value.y, value.z)
		end
		error("Unknown serialized type: " .. tostring(value.type))
	end
	if enumNames[key] then
		return roblox.Enum[enumNames[key]][value]
	end
	return value
end

local function instantiate(node, parent)
	local instance = roblox.Instance.new(node.class)
	for key, value in node.props do
		local ok, problem = pcall(function()
			instance[key] = decode(key, value)
		end)
		assert(ok, node.class .. "." .. key .. ": " .. tostring(problem))
		properties += 1
	end
	instance.Parent = parent
	if instance:IsA("GuiObject") then
		assert(
			parent:IsA("GuiObject") or parent:IsA("LayerCollector"),
			"GuiObject has an invalid UI parent: " .. instance:GetFullName()
		)
	elseif instance:IsA("UIComponent") then
		assert(parent:IsA("GuiObject"), "UIComponent must belong to a GuiObject")
	end
	for _, child in node.children do
		instantiate(child, instance)
	end
	local layout = nil
	for _, child in instance:GetChildren() do
		if child:IsA("UIGridStyleLayout") then
			assert(layout == nil, "Multiple layouts compete in " .. instance:GetFullName())
			layout = child
		end
	end
	if layout then
		local orders = {}
		for _, child in instance:GetChildren() do
			if child:IsA("GuiObject") and child.Visible then
				assert(
					child.Position == roblox.UDim2.new(),
					"Layout child has a manual position: " .. child:GetFullName()
				)
				if layout.SortOrder == roblox.Enum.SortOrder.LayoutOrder then
					assert(not orders[child.LayoutOrder], "Ambiguous layout order in " .. instance:GetFullName())
					orders[child.LayoutOrder] = true
				end
			end
		end
		layoutGroups += 1
	end
	checked += 1
	return instance
end

local screens = 0
for _, file in fs.readDir(directory) do
	if file:match("%.json$") and not file:match("%.figma%.json$") then
		local snapshot = serde.decode("json", fs.readFile(directory .. "/" .. file))
		if snapshot.tree then
			local screen = roblox.Instance.new("ScreenGui")
			screen.Name = snapshot.name
			screen.ResetOnSpawn = false
			screen.ZIndexBehavior = roblox.Enum.ZIndexBehavior.Sibling
			screen.ScreenInsets = roblox.Enum.ScreenInsets.CoreUISafeInsets
			instantiate(snapshot.tree, screen)
			screen:Destroy()
			screens += 1
		end
	end
end

local viewport = roblox.Instance.new("ViewportFrame")
local navigationScreen = roblox.Instance.new("ScreenGui")
navigationScreen.Name = "CloverNavigation"
navigationScreen.ScreenInsets = roblox.Enum.ScreenInsets.DeviceSafeInsets
navigationScreen.ResetOnSpawn = false
navigationScreen.DisplayOrder = 19
navigationScreen.ZIndexBehavior = roblox.Enum.ZIndexBehavior.Sibling
navigationScreen:Destroy()
local world = roblox.Instance.new("WorldModel")
local camera = roblox.Instance.new("Camera")
local character = roblox.Instance.new("Model")
local head = roblox.Instance.new("Part")
world.Parent = viewport
camera.Parent = viewport
character.Parent = world
head.Name = "Head"
head.Parent = character
camera.FieldOfView = 32
camera.CFrame = roblox.CFrame.lookAt(roblox.Vector3.new(0, 1, 5), roblox.Vector3.new(0, 1, 0))
viewport.CurrentCamera = camera
assert(camera.Parent == viewport and world.Parent == viewport and character.Parent == world)
viewport:Destroy()
print(
	string.format(
		"Validated %d snapshots: %d Roblox instances, %d property assignments, %d native layout groups, GUI parents and portrait hierarchy",
		screens,
		checked,
		properties,
		layoutGroups
	)
)
