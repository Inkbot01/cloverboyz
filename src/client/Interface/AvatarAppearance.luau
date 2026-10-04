local Appearance = require(script.Parent.AppearanceModel)
local AvatarAppearance = {}

local function color(field, id)
	local option = Appearance.Option(field, id)
	return if option and option.Color then Color3.fromHex(option.Color) else nil
end

function AvatarAppearance.Apply(character, values)
	local skin = color("SkinTone", values.SkinTone)
	local hair = color("HairColor", values.HairColor)
	local outfit = color("OutfitColor", values.OutfitColor)
	local training = values.Outfit == "training"
	for _, child in character:GetChildren() do
		if child:IsA("Accessory") then
			local isHair = child.AccessoryType == Enum.AccessoryType.Hair
			if (isHair and values.Hair == "none") or (not isHair and (values.Accessories == "hidden" or training)) then
				child:Destroy()
			elseif isHair and hair then
				for _, part in child:GetDescendants() do
					if part:IsA("BasePart") then
						part.Color = hair
						if part:IsA("MeshPart") then
							part.TextureID = ""
						end
					elseif part:IsA("SpecialMesh") then
						part.TextureId = ""
					elseif part:IsA("SurfaceAppearance") then
						part:Destroy()
					end
				end
			end
		elseif training and (child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic")) then
			child:Destroy()
		elseif child:IsA("BodyColors") and skin then
			for _, property in
				{ "HeadColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3", "TorsoColor3" }
			do
				child[property] = skin
			end
		end
	end
	for _, part in character:GetChildren() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			if skin then
				part.Color = skin
			end
			if training and string.find(part.Name, "Torso") then
				part.Color = outfit
			elseif training and (string.find(part.Name, "Leg") or string.find(part.Name, "Foot")) then
				part.Color = Color3.fromRGB(30, 32, 36)
			end
		end
	end
	local head = character:FindFirstChild("Head")
	if head and values.Face ~= "original" then
		for _, face in head:GetChildren() do
			if face:IsA("Decal") and face.Face == Enum.NormalId.Front then
				face:Destroy()
			end
		end
		if values.Face == "classic" then
			local face = Instance.new("Decal")
			face.Name = "face"
			face.Face = Enum.NormalId.Front
			face.Texture = "rbxasset://textures/face.png"
			face.Parent = head
		end
	end
	character:ScaleTo(values.Scale)
end

return table.freeze(AvatarAppearance)
