local RunService = game:GetService("RunService")
local mount = require(script.Parent.StudioPreviewSession)
local Review = {}
local preview

function Review.Open(gender, hair, focus, rotation)
	assert(RunService:IsStudio() and not RunService:IsRunning(), "Review requires Studio Edit mode")
	preview = mount(workspace.Male)
	preview.Actions.Open("Customization")
	for field, value in
		{
			Gender = gender or "female",
			Hair = hair or "ember_ponytail",
			Face = "determined",
			Outfit = "ink_knight",
			Accessories = "hidden",
			SkinTone = "warm",
		}
	do
		preview.Actions.ChangeAppearance(field, value)
	end
	preview.State.PreviewFocus:set(focus or "Face")
	preview.State.PreviewRotation:set(rotation or 45)
	return true
end

function Review.Change(field, value)
	assert(preview, "Open the review first")
	preview.Actions.ChangeAppearance(field, value)
end

function Review.View(focus, rotation)
	assert(preview, "Open the review first")
	preview.State.PreviewFocus:set(focus)
	preview.State.PreviewRotation:set(rotation)
end

function Review.Check()
	Review.Open()
	local checked = 0
	for _, gender in { "male", "female" } do
		for _, hair in { "iron_spikes", "wind_swept", "ember_ponytail" } do
			for _, outfit in { "ink_knight", "forest_initiate" } do
				Review.Change("Gender", gender)
				Review.Change("Hair", hair)
				Review.Change("Outfit", outfit)
				task.wait()
				local target
				for _, object in game:GetService("CoreGui").CloverInterfacePreview:GetDescendants() do
					if object:IsA("Model") and object:GetAttribute("CosmeticBodyFit") == gender then
						target = object
						break
					end
				end
				assert(target, "Gender selection did not update the preview rig")
				local mesh = target:FindFirstChildOfClass("CharacterMesh")
				assert((mesh ~= nil) == (gender == "female"), "Wrong torso shape")
				assert(#target.CloverCosmetics:GetChildren() == 6, "Hair and five outfit pieces required")
				for _, part in target.CloverCosmetics:GetChildren() do
					local weld = part:FindFirstChildOfClass("WeldConstraint")
					assert(weld and weld.Part0 and weld.Part1 == part, "Missing body attachment")
					assert(part.MeshSize.Magnitude > 0, "Mesh scale metadata missing")
					if weld.Part0.Name == "Torso" then
						assert((string.find(part.Name, "female") ~= nil) == (gender == "female"), "Wrong outfit fit")
					end
				end
				checked += 1
			end
		end
	end
	return {
		Combinations = checked,
		OriginalRigsUnchanged = not workspace.Male:FindFirstChild("CloverCosmetics")
			and not workspace.Female:FindFirstChild("CloverCosmetics"),
	}
end

return Review
