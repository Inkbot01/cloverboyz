local Appearance = {}

Appearance.Options = {
	Gender = {
		{ Id = "male", Name = "Male" },
		{ Id = "female", Name = "Female" },
	},
	Hair = {
		{ Id = "iron_spikes", Name = "Iron spikes" },
		{ Id = "wind_swept", Name = "Wind swept" },
		{ Id = "ember_ponytail", Name = "Ember ponytail" },
	},
	Face = {
		{ Id = "determined", Name = "Emerald resolve" },
	},
	Outfit = {
		{ Id = "ink_knight", Name = "Black Bulls" },
		{ Id = "forest_initiate", Name = "Golden Dawn" },
	},
	Accessories = {
		{ Id = "hidden", Name = "None" },
		{ Id = "headband", Name = "Clover headband" },
		{ Id = "grimoire", Name = "Grimoire satchel" },
		{ Id = "knight_set", Name = "Headband & grimoire" },
	},
	SkinTone = {
		{ Id = "porcelain", Name = "Porcelain", Color = "F2D8BF" },
		{ Id = "sand", Name = "Sand", Color = "DDBA94" },
		{ Id = "warm", Name = "Warm tan", Color = "C7966C" },
		{ Id = "amber", Name = "Amber", Color = "AD7953" },
		{ Id = "copper", Name = "Copper", Color = "8B5B3C" },
		{ Id = "umber", Name = "Umber", Color = "67432F" },
		{ Id = "ebony", Name = "Ebony", Color = "422D26" },
	},
	HairColor = {
		{ Id = "ink", Name = "Ink", Color = "242329" },
		{ Id = "chestnut", Name = "Chestnut", Color = "664638" },
		{ Id = "auburn", Name = "Auburn", Color = "994F35" },
		{ Id = "wheat", Name = "Wheat", Color = "D2B677" },
		{ Id = "silver", Name = "Silver", Color = "D8DBDA" },
		{ Id = "sage", Name = "Sage", Color = "788D72" },
		{ Id = "plum", Name = "Plum", Color = "685473" },
	},
}

function Appearance.Defaults()
	return {
		Gender = "male",
		Hair = "iron_spikes",
		Face = "determined",
		Outfit = "ink_knight",
		Accessories = "hidden",
		SkinTone = "warm",
		HairColor = "silver",
		Scale = 1,
	}
end

function Appearance.Option(field, id)
	for _, option in Appearance.Options[field] or {} do
		if option.Id == id then
			return option
		end
	end
	return nil
end

function Appearance.Patch(current, patch)
	local result = table.clone(current)
	if type(patch) ~= "table" then
		return result
	end
	for field, value in patch do
		if Appearance.Option(field, value) then
			result[field] = value
		elseif field == "Scale" and type(value) == "number" and value == value and value >= 0.9 and value <= 1.1 then
			result.Scale = math.clamp(math.floor(value * 100 + 0.5) / 100, 0.9, 1.1)
		end
	end
	return result
end

function Appearance.Cycle(current, field, direction)
	local choices = Appearance.Options[field]
	if not choices or (direction ~= 1 and direction ~= -1) then
		return table.clone(current)
	end
	local index = 1
	for order, option in choices do
		if option.Id == current[field] then
			index = order
			break
		end
	end
	return Appearance.Patch(current, { [field] = choices[(index - 1 + direction) % #choices + 1].Id })
end

function Appearance.Equal(a, b)
	for field, value in Appearance.Defaults() do
		if (a[field] or value) ~= (b[field] or value) then
			return false
		end
	end
	return true
end

for _, options in Appearance.Options do
	for _, option in options do
		table.freeze(option)
	end
	table.freeze(options)
end
table.freeze(Appearance.Options)

return table.freeze(Appearance)
