local RunService = game:GetService("RunService")
local AvatarAppearance = require(script.Parent.AvatarAppearance)

return function()
	assert(RunService:IsStudio() and not RunService:IsRunning(), "Showcase requires Studio Edit mode")
	local previous = workspace:FindFirstChild("CloverCustomizationShowcase")
	if previous then
		previous:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "CloverCustomizationShowcase"
	folder.Parent = workspace
	local presets = {
		{ "Male", "Black Bulls Male", "iron_spikes", "ink_knight", "knight_set", -7.5 },
		{ "Male", "Golden Dawn Male", "wind_swept", "forest_initiate", "grimoire", -2.5 },
		{ "Female", "Black Bulls Female", "ember_ponytail", "ink_knight", "knight_set", 2.5 },
		{ "Female", "Golden Dawn Female", "wind_swept", "forest_initiate", "hidden", 7.5 },
	}
	local origin = workspace.Male:GetPivot().Position + Vector3.new(-2.5, 0, -12)
	for _, preset in presets do
		local character = workspace[preset[1]]:Clone()
		character.Name = preset[2]
		for _, child in character:GetDescendants() do
			if child:IsA("LuaSourceContainer") then
				child:Destroy()
			elseif child:IsA("BasePart") then
				child.Anchored = true
				child.CanCollide = false
			end
		end
		AvatarAppearance.Apply(character, {
			Gender = string.lower(preset[1]),
			Hair = preset[3],
			HairColor = if preset[3] == "iron_spikes"
				then "silver"
				elseif preset[3] == "ember_ponytail" then "auburn"
				else "ink",
			Outfit = preset[4],
			Accessories = preset[5],
			Face = "determined",
			SkinTone = "warm",
			Scale = 1,
		})
		character:PivotTo(CFrame.new(origin + Vector3.new(preset[6], 0, 0)))
		character.Parent = folder
	end
	return folder
end
