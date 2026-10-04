local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local process = require("@lune/process")
local root = "src/client/Interface/"
local modules = {}
local scope = {}
local Fusion = { Children = "__children" }

local function use(value)
	if type(value) == "table" and value.__state then
		return if value.get then value.get(use, scope) else value.value
	end
	return value
end

function scope:Value(value)
	return {
		__state = true,
		value = value,
		set = function(self, nextValue)
			self.value = nextValue
		end,
	}
end
function scope:Computed(callback)
	return { __state = true, get = callback }
end
function scope:Tween(value)
	return value
end
function scope:New(className)
	return function(props)
		return { __node = true, ClassName = className, Props = props }
	end
end
Fusion.peek = use
Fusion.OnEvent = function(name)
	return "__event_" .. name
end
Fusion.OnChange = function(name)
	return "__change_" .. name
end

local moduleNames = {
	"Theme",
	"Icons",
	"Model",
	"Layout",
	"Components",
	"HudSprites",
	"HudParts",
	"PageLayout",
	"Stats",
	"Grimoire",
	"Equipment",
	"HUD",
	"CharacterWindow",
}
local parent = {}
for _, name in moduleNames do
	parent[name] = name
end
local function import(name)
	if name == "Fusion" then
		return Fusion
	end
	if modules[name] then
		return modules[name]
	end
	local env = {
		require = import,
		script = { Parent = parent },
		game = {
			GetService = function()
				return { Packages = { Fusion = "Fusion" } }
			end,
		},
		TweenInfo = {
			new = function(...)
				return { ... }
			end,
		},
	}
	for _, kind in { "Enum", "Color3", "UDim", "UDim2", "Vector2", "Vector3", "CFrame" } do
		env[kind] = roblox[kind]
	end
	modules[name] =
		luau.load(fs.readFile(root .. name .. ".luau"), { debugName = name, environment = env, injectGlobals = true })()
	return modules[name]
end

local function encode(value)
	value = use(value)
	local kind = typeof(value)
	if kind == "Color3" then
		return {
			type = kind,
			r = math.round(value.R * 255),
			g = math.round(value.G * 255),
			b = math.round(value.B * 255),
		}
	end
	if kind == "UDim2" then
		return { type = kind, xs = value.X.Scale, xo = value.X.Offset, ys = value.Y.Scale, yo = value.Y.Offset }
	end
	if kind == "UDim" then
		return { type = kind, scale = value.Scale, offset = value.Offset }
	end
	if kind == "Vector2" then
		return { type = kind, x = value.X, y = value.Y }
	end
	if kind == "Vector3" then
		return { type = kind, x = value.X, y = value.Y, z = value.Z }
	end
	if kind == "EnumItem" then
		return value.Name
	end
	if kind == "number" or kind == "boolean" or kind == "string" then
		return value
	end
	return nil
end

local function serialize(node)
	local children = {}
	local function flatten(value)
		value = use(value)
		if type(value) ~= "table" then
			return
		end
		if value.__node then
			table.insert(children, serialize(value))
		else
			for _, item in value do
				flatten(item)
			end
		end
	end
	flatten(node.Props.__children)
	local props = {}
	for key, value in node.Props do
		if type(key) == "string" and not string.find(key, "^__") then
			props[key] = encode(value)
		end
	end
	return { class = node.ClassName, props = props, children = children }
end

local Model = import("Model")
local Layout = import("Layout")
local UI = import("Components")
local HUD = import("HUD")
local Window = import("CharacterWindow")
local data = Model.Defaults(true, "Asta")
local stress = process.args[2] == "stress"
if stress then
	data = Model.Patch(data, {
		Name = "KnightWithALongName",
		Health = 0,
		MaxHealth = 999999,
		Mana = 0,
		MaxMana = 0,
		Stamina = 3,
		MaxStamina = 100,
		Coins = 999999,
		Gems = 999999,
	})
end
local target = process.args[1] or "output/ui-previews/aligned"
fs.writeDir(target)
for _, viewport in
	{
		{ 1672, 941, false },
		{ 1440, 860, false },
		{ 1280, 720, false },
		{ 1024, 768, false },
		{ 730, 640, false },
		{ 844, 390, true },
		{ 390, 844, true },
		{ 728, 640, false, 2, 58 },
	}
do
	for _, page in (if stress then { "HUD" } else { "HUD", "Stats", "Grimoire", "Equipment" }) do
		local topInset = viewport[5] or 0
		local layout = Layout.Resolve(viewport[1], viewport[2] - topInset, viewport[3])
		local state = {
			Preview = true,
			Data = data,
			Fields = data,
			Layout = layout,
			Open = page ~= "HUD",
			Page = page,
			Compact = layout.Compact,
			Tight = layout.Tight,
			Mobile = layout.TouchControls,
			Scale = layout.Scale,
			CharacterRevision = 0,
			Heading = 0,
			Pending = {},
			PointsRemaining = 3,
			PendingCount = 0,
			CanAllocate = true,
			AllocationAvailable = true,
			BindingAvailable = true,
			EquipmentAvailable = true,
			Busy = false,
			FilteredSpells = data.Spells,
			SelectedSpell = data.Spells[1],
			SpellTargetSlot = 2,
			SpellFilter = "All",
			FilteredItems = data.Inventory,
			SelectedItem = data.Inventory[2],
			ItemFilter = "All",
			ItemQuery = "",
			SelectedSlot = if stress then 4 else 1,
			Now = 0,
			Cooldowns = if stress then { [4] = 4.2 } else {},
		}
		local actions = setmetatable({}, {
			__index = function()
				return function() end
			end,
		})
		local children = { HUD.Body(scope, state, actions) }
		if page ~= "HUD" then
			table.insert(children, Window(scope, state, actions))
		end
		local scene = UI.Frame(scope, {
			Name = "PreviewViewport",
			Size = roblox.UDim2.fromScale(1, 1),
			[Fusion.Children] = {
				UI.Frame(scope, {
					Name = "DeviceSafeArea",
					Size = roblox.UDim2.fromScale(1, 1),
					[Fusion.Children] = UI.Canvas(scope, layout.Scale, HUD.Navigation(scope, state)),
				}),
				UI.Frame(scope, {
					Name = "SafeArea",
					Position = roblox.UDim2.fromOffset(0, topInset),
					Size = roblox.UDim2.new(1, 0, 1, -topInset),
					[Fusion.Children] = UI.Canvas(scope, layout.Scale, children),
				}),
			},
		})
		local name = string.lower(page)
			.. (if viewport[4] then "-studio-" else "-")
			.. viewport[1]
			.. "x"
			.. viewport[2]
		fs.writeFile(
			target .. "/" .. name .. ".json",
			serde.encode("json", {
				name = name,
				width = viewport[1],
				height = viewport[2],
				density = viewport[4] or 1,
				topInset = topInset,
				page = page,
				touch = viewport[3],
				tree = serialize(scene),
			})
		)
		print("Exported " .. name)
	end
end
