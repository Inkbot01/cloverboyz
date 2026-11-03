local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local Appearance = require("../src/client/Interface/AppearanceModel")
local library = roblox.deserializeModel(fs.readFile("src/shared/Assets/CustomizationTemplates.rbxmx"))[1]
local published = serde.decode("json", fs.readFile("assets/interface/customization/v1/published.json"))
local updated = serde.decode("json", fs.readFile("assets/interface/customization/v2/published.json"))
local squad = serde.decode("json", fs.readFile("assets/interface/customization/v3/published.json"))
local xml = fs.readFile("src/shared/Assets/CustomizationTemplates.rbxmx")
for _, part in updated.parts do
	assert(string.find(xml, part.mesh, 1, true), "Rebuilt hairstyle must replace the rejected mesh")
end
for _, part in published.parts do
	assert(string.match(part.mesh, "^rbxassetid://%d+$"), "Mesh must have a published asset ID")
	assert(string.match(part.texture, "^rbxassetid://%d+$"), "Palette must have a published asset ID")
end
for _, part in squad.parts do
	assert(string.find(xml, part.mesh, 1, true), "Squad outfit must replace the rejected generic mesh")
end
assert(#library:GetChildren() == 10, "All ten cosmetic templates must be present")
local count = 0
for _, model in library:GetChildren() do
	for _, part in model:GetChildren() do
		assert(part.ClassName == "MeshPart", "Cosmetics must contain imported mesh geometry")
		assert(part.InitialSize.Magnitude > 10, "Imported mesh scale metadata must survive serialization")
		assert(part.Size.Magnitude < 6, "Templates must be normalized to rig scale")
		assert(part:GetAttribute("FitOffset").Magnitude < 2, "Fitting offset must be relative to its body part")
		assert(part:GetAttribute("ReferenceSize").Magnitude > 0, "Fitting requires body dimensions")
		assert(not part.CanCollide and part.Massless, "Cosmetics must not interfere with character physics")
		count += 1
	end
end
assert(count == 26, "All 26 imported parts must be available")
for field, choices in
	{
		Gender = { "male", "female" },
		Hair = { "iron_spikes", "wind_swept", "ember_ponytail" },
		Outfit = { "ink_knight", "forest_initiate" },
		Accessories = { "headband", "grimoire", "knight_set" },
		Face = { "determined" },
	}
do
	for _, id in choices do
		assert(Appearance.Patch(Appearance.Defaults(), { [field] = id })[field] == id, "Catalog rejects " .. id)
	end
end
print("Customization templates passed: 10 models, 26 published meshes, fitting metadata and catalog")
