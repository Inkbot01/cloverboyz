local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Templates = ReplicatedStorage.Shared.Assets.CustomizationTemplates
local Cosmetics = {}

Cosmetics.Hair = table.freeze({
	iron_spikes = "hair-iron-spikes-v1",
	wind_swept = "hair-wind-swept-v1",
	ember_ponytail = "hair-ember-ponytail-v1",
})

Cosmetics.Outfits = table.freeze({
	ink_knight = "outfit-ink-knight",
	forest_initiate = "outfit-forest-initiate",
})

Cosmetics.Accessories = table.freeze({
	headband = table.freeze({ "accessory-clover-headband-v1" }),
	mantle = table.freeze({ "accessory-black-mantle-v1" }),
	grimoire = table.freeze({ "accessory-grimoire-satchel-v1" }),
	knight_set = table.freeze({
		"accessory-clover-headband-v1",
		"accessory-grimoire-satchel-v1",
	}),
})

local function femaleFit(character)
	if character:GetAttribute("CosmeticBodyFit") == "female" then
		return true
	end
	for _, child in character:GetChildren() do
		if child:IsA("CharacterMesh") and child.BodyPart == Enum.BodyPart.Torso and child.MeshId == 48112070 then
			return true
		end
	end
	return false
end

function Cosmetics.Apply(character, values, hairColor)
	local previous = character:FindFirstChild("CloverCosmetics")
	if previous then
		previous:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "CloverCosmetics"
	folder.Parent = character
	local function attach(id, tint)
		local template = Templates:FindFirstChild(id)
		assert(template, "Missing cosmetic template: " .. id)
		for _, source in template:GetChildren() do
			if not source:IsA("MeshPart") then
				continue
			end
			local body = character:FindFirstChild(source:GetAttribute("BodySegment"))
			if not body or not body:IsA("BasePart") then
				continue
			end
			local ratio = body.Size / source:GetAttribute("ReferenceSize")
			local part = source:Clone()
			part.Name = id .. "_" .. body.Name
			part.Size = source.Size * ratio
			part.CFrame = body.CFrame * CFrame.new(source:GetAttribute("FitOffset") * ratio)
			part.Anchored = body.Anchored
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
			if tint then
				part.TextureID = ""
				part.Color = tint
				local surface = part:FindFirstChildOfClass("SurfaceAppearance")
				if surface then
					surface:Destroy()
				end
			end
			part.Parent = folder
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = part
			weld.Parent = part
		end
	end
	local hair = Cosmetics.Hair[values.Hair]
	if hair then
		attach(hair, hairColor)
	end
	local outfit = Cosmetics.Outfits[values.Outfit]
	if outfit then
		attach(outfit .. (if femaleFit(character) then "-female-v1" else "-v1"))
		for _, name in { "Torso", "Left Leg", "Right Leg" } do
			local body = character:FindFirstChild(name)
			if body and body:IsA("BasePart") then
				body.Transparency = 1
			end
		end
	end
	for _, id in Cosmetics.Accessories[values.Accessories] or {} do
		attach(id)
	end
	if #folder:GetChildren() == 0 then
		folder:Destroy()
	end
end

return table.freeze(Cosmetics)
