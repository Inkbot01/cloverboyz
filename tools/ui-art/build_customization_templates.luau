local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local root = "assets/interface/customization/v1"
local published = serde.decode("json", fs.readFile(root .. "/published.json"))
local fittings = serde.decode("json", fs.readFile(root .. "/fitting.json"))
for _, version in { "v2", "v3" } do
	local revision = "assets/interface/customization/" .. version
	if not fs.isFile(revision .. "/published.json") then
		continue
	end
	local replacement = serde.decode("json", fs.readFile(revision .. "/published.json"))
	local updatedFits = serde.decode("json", fs.readFile(revision .. "/fitting.json"))
	for _, part in replacement.parts do
		for index, previous in published.parts do
			if previous.name == part.name then
				published.parts[index] = part
				break
			end
		end
	end
	for id, fit in updatedFits do
		fittings[id] = fit
	end
end
local library = roblox.Instance.new("Folder")
library.Name = "CustomizationTemplates"
local models = {}
for _, source in published.parts do
	local id, segment = string.match(source.name, "^(.-)__(.+)$")
	assert(id and segment, "Unexpected imported part name")
	local model = models[id]
	if not model then
		model = roblox.Instance.new("Model")
		model.Name = id
		model.Parent = library
		models[id] = model
	end
	local transfer = fittings[id]
	segment = string.gsub(segment, "_", " ")
	if segment == "Handle" then
		segment = transfer.parts[1].segment
	end
	local fit
	for _, candidate in transfer.parts do
		if candidate.segment == segment then
			fit = candidate
			break
		end
	end
	assert(fit, "Missing fitting data")
	local part = roblox.Instance.new("MeshPart")
	part.Name = segment
	part.MeshId = source.mesh
	part.MeshSize = roblox.Vector3.new(table.unpack(source.size))
	part.TextureID = source.texture
	part.Size = roblox.Vector3.new(table.unpack(fit.size))
	part.Color = roblox.Color3.new(1, 1, 1)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.DoubleSided = true
	part.CastShadow = false
	part:SetAttribute("BodySegment", segment)
	part:SetAttribute("FitOffset", roblox.Vector3.new(-fit.offset[1], fit.offset[2], fit.offset[3]))
	part:SetAttribute("ReferenceSize", roblox.Vector3.new(table.unpack(fit.referenceSize)))
	part.Parent = model
	model:SetAttribute("Category", transfer.category)
end
local xml = string.gsub(roblox.serializeModel({ library }, true), 'name="MeshSize"', 'name="InitialSize"')
fs.writeFile("src/shared/Assets/CustomizationTemplates.rbxmx", xml)
fs.writeFile(
	"src/shared/Assets/CustomizationImages.luau",
	'return table.freeze({\n\tDeterminedEmerald = "' .. published.face .. '",\n})\n'
)
print("Installed 10 cosmetic templates, 26 MeshParts and face ID")
