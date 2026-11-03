local CharacterRig = {}

function CharacterRig.Apply(character, gender)
	if gender ~= "male" and gender ~= "female" then
		return
	end
	local torso = character:FindFirstChild("Torso")
	if not torso or not torso:IsA("BasePart") then
		return
	end
	for _, child in character:GetChildren() do
		if child:IsA("CharacterMesh") and child.BodyPart == Enum.BodyPart.Torso then
			child:Destroy()
		end
	end
	if gender == "female" then
		local mesh = Instance.new("CharacterMesh")
		mesh.Name = "CharacterMesh"
		mesh.BodyPart = Enum.BodyPart.Torso
		mesh.MeshId = 48112070
		mesh.Parent = character
	end
	character:SetAttribute("CosmeticBodyFit", gender)
end

return table.freeze(CharacterRig)
