local Appearance = require(script.Parent.AppearanceModel)
local Cosmetics = require(script.Parent.CharacterCosmetics)
local CharacterRig = require(script.Parent.CharacterRig)
local Images = require(game:GetService("ReplicatedStorage").Shared.Assets.CustomizationImages)
local AvatarAppearance = {}

function AvatarAppearance.Apply(character, values)
	values = Appearance.Patch(Appearance.Defaults(), values)
	CharacterRig.Apply(character, values.Gender)
	local skin = Color3.fromHex(Appearance.Option("SkinTone", values.SkinTone).Color)
	local hair = Color3.fromHex(Appearance.Option("HairColor", values.HairColor).Color)
	for _, child in character:GetChildren() do
		if child:IsA("Accessory") or child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then
			child:Destroy()
		elseif child:IsA("BodyColors") then
			for _, property in
				{ "HeadColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3", "TorsoColor3" }
			do
				child[property] = skin
			end
		elseif child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
			child.Color = skin
		end
	end
	local head = character:FindFirstChild("Head")
	if head then
		for _, face in head:GetChildren() do
			if face:IsA("Decal") and face.Face == Enum.NormalId.Front then
				face:Destroy()
			end
		end
		local face = Instance.new("Decal")
		face.Name = "face"
		face.Face = Enum.NormalId.Front
		face.Texture = Images.DeterminedEmerald
		face.Parent = head
	end
	Cosmetics.Apply(character, values, hair)
	character:ScaleTo(values.Scale)
end

return table.freeze(AvatarAppearance)
