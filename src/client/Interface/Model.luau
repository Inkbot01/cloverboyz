local Model = {}

Model.Pages = { "Stats", "Grimoire", "Equipment", "Customization" }
Model.EquipmentSlots = { "Weapon", "Armor", "Accessory" }
Model.ItemCategories = { "All", "Weapons", "Armor", "Accessories", "Materials" }
Model.SpellFilters = { "All", "Learned", "Locked" }
Model.RarityColors = { Common = "Muted", Uncommon = "Green", Rare = "Mana", Epic = "Violet", Legendary = "GoldLight" }

Model.AttributeOrder = { "Vitality", "Strength", "Magic", "Defense" }
Model.AttributeDescriptions = {
	Vitality = "Maximum health",
	Strength = "Physical damage",
	Magic = "Spell power and mana",
	Defense = "Damage resistance",
}

local numericFields = {
	Level = true,
	XP = true,
	XPToNext = true,
	Health = true,
	MaxHealth = true,
	Mana = true,
	MaxMana = true,
	Stamina = true,
	MaxStamina = true,
	Coins = true,
	Gems = true,
	UnspentPoints = true,
	MagicPower = true,
}
local stringFields = { Name = true, Rank = true, Squad = true, Location = true }

local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function Model.Defaults(preview, name)
	return {
		Name = name or "MAGIC KNIGHT",
		Level = if preview then 12 else 1,
		XP = if preview then 2450 else 0,
		XPToNext = if preview then 3200 else 0,
		Health = 100,
		MaxHealth = 100,
		Mana = if preview then 360 else 0,
		MaxMana = if preview then 500 else 0,
		Stamina = if preview then 95 else 0,
		MaxStamina = if preview then 100 else 0,
		Coins = if preview then 1250 else 0,
		Gems = if preview then 24 else 0,
		UnspentPoints = if preview then 3 else 0,
		MagicPower = if preview then 128 else 0,
		Rank = if preview then "Junior Knight" else "Unranked",
		Squad = if preview then "Black Bulls" else "No squad",
		Location = if preview then "HAGE VILLAGE" else "CLOVER KINGDOM",
		SafeZone = preview,
		Grimoire = {
			Name = if preview then "Grimoire of Gales" else "Unbound Grimoire",
			Affinity = if preview then "Wind" else "Unknown",
			Leaves = if preview then 3 else 0,
			Mastery = if preview then 7 else 0,
			XP = if preview then 420 else 0,
			XPToNext = if preview then 600 else 0,
		},
		Spells = if preview
			then {
				{
					Id = "wind_cutter",
					Name = "Wind Cutter",
					Icon = "Wind",
					Color = "Green",
					LevelRequired = 1,
					Learned = true,
					ManaCost = 25,
					Cooldown = 4,
					Type = "Offense",
					Description = "Send a crescent of compressed wind toward your target. A fast, precise spell for keeping your distance.",
				},
				{
					Id = "gale_step",
					Name = "Gale Step",
					Icon = "Wind",
					Color = "Mana",
					LevelRequired = 5,
					Learned = true,
					ManaCost = 35,
					Cooldown = 7,
					Type = "Mobility",
					Description = "Ride a sudden current of wind to reposition. A quick escape from danger, or an opening to close the gap.",
				},
				{
					Id = "tornado",
					Name = "Towering Tornado",
					Icon = "Magic",
					Color = "Green",
					LevelRequired = 10,
					Learned = true,
					ManaCost = 60,
					Cooldown = 12,
					Type = "Area",
					Description = "Gather spiraling winds into a towering vortex. Control the battlefield with a wide burst of wind magic.",
				},
				{
					Id = "wind_guard",
					Name = "Wind Guard",
					Icon = "Shield",
					Color = "Stamina",
					LevelRequired = 15,
					Learned = false,
					ManaCost = 45,
					Cooldown = 10,
					Type = "Defense",
					Description = "Wrap yourself in a shell of circling air. This defensive page becomes available as your magic develops.",
				},
				{
					Id = "sky_blade",
					Name = "Skyward Blade",
					Icon = "Sword",
					Color = "Mana",
					LevelRequired = 20,
					Learned = false,
					ManaCost = 80,
					Cooldown = 16,
					Type = "Offense",
					Description = "Shape the wind into a sweeping blade. A powerful spell reserved for a more experienced Magic Knight.",
				},
				{
					Id = "spirit_dive",
					Name = "Spirit's Embrace",
					Icon = "Clover",
					Color = "GoldLight",
					LevelRequired = 35,
					Learned = false,
					ManaCost = 120,
					Cooldown = 30,
					Type = "Enhancement",
					Description = "Surround yourself with a mantle of concentrated wind. The final page of this preview grimoire.",
				},
			}
			else {},
		SpellSlots = if preview then { [2] = "wind_cutter", [3] = "gale_step", [4] = "tornado" } else {},
		Inventory = if preview
			then {
				{
					Id = "iron_blade",
					Name = "Iron Longsword",
					Icon = "Sword",
					Color = "Muted",
					Category = "Weapons",
					Slot = "Weapon",
					Rarity = "Common",
					LevelRequired = 1,
					Count = 1,
					Description = "A dependable blade issued to aspiring knights. Worn at the grip, but carefully balanced.",
					Bonuses = { Strength = 8 },
				},
				{
					Id = "gale_saber",
					Name = "Gale Saber",
					Icon = "Sword",
					Color = "Green",
					Category = "Weapons",
					Slot = "Weapon",
					Rarity = "Rare",
					LevelRequired = 10,
					Count = 1,
					Description = "A light saber etched with wind runes. Its edge seems to hum whenever mana gathers nearby.",
					Bonuses = { Strength = 12, Magic = 6 },
				},
				{
					Id = "dusk_blade",
					Name = "Dusk Greatsword",
					Icon = "Sword",
					Color = "Violet",
					Category = "Weapons",
					Slot = "Weapon",
					Rarity = "Epic",
					LevelRequired = 20,
					Count = 1,
					Description = "A heavy blade forged from dark steel. It demands a steady hand and the strength to wield it.",
					Bonuses = { Strength = 24, Defense = 4 },
				},
				{
					Id = "knight_robe",
					Name = "Knight's Robe",
					Icon = "Robe",
					Color = "Gold",
					Category = "Armor",
					Slot = "Armor",
					Rarity = "Uncommon",
					LevelRequired = 1,
					Count = 1,
					Description = "A dark robe finished with the gold trim of a Magic Knight. Light enough to move freely in battle.",
					Bonuses = { Defense = 8, Vitality = 4 },
				},
				{
					Id = "travel_cloak",
					Name = "Traveler's Cloak",
					Icon = "Robe",
					Color = "Green",
					Category = "Armor",
					Slot = "Armor",
					Rarity = "Common",
					LevelRequired = 1,
					Count = 1,
					Description = "A weathered cloak made for long journeys between villages. Practical, comfortable, and easy to repair.",
					Bonuses = { Defense = 4, Vitality = 6 },
				},
				{
					Id = "clover_charm",
					Name = "Clover Charm",
					Icon = "Clover",
					Color = "GoldLight",
					Category = "Accessories",
					Slot = "Accessory",
					Rarity = "Rare",
					LevelRequired = 5,
					Count = 1,
					Description = "A small clover carried for good fortune. A quiet reserve of mana rests within its leaves.",
					Bonuses = { Magic = 5, Vitality = 2 },
				},
				{
					Id = "mana_pendant",
					Name = "Mana Pendant",
					Icon = "Gem",
					Color = "Mana",
					Category = "Accessories",
					Slot = "Accessory",
					Rarity = "Uncommon",
					LevelRequired = 8,
					Count = 1,
					Description = "A polished crystal hung from a silver chain. The stone glows softly when held by a mage.",
					Bonuses = { Magic = 8 },
				},
				{
					Id = "mana_crystal",
					Name = "Mana Crystal",
					Icon = "Gem",
					Color = "Green",
					Category = "Materials",
					Rarity = "Uncommon",
					LevelRequired = 0,
					Count = 12,
					Description = "A fragment of crystallized mana. Keep it for future crafting and equipment upgrades.",
					Bonuses = {},
				},
				{
					Id = "iron_ore",
					Name = "Iron Ore",
					Icon = "Ore",
					Color = "Muted",
					Category = "Materials",
					Rarity = "Common",
					LevelRequired = 0,
					Count = 8,
					Description = "A rough piece of ore from the kingdom's mines. A basic material used by local blacksmiths.",
					Bonuses = {},
				},
			}
			else {},
		Equipped = if preview then { Weapon = "iron_blade", Armor = "knight_robe", Accessory = "clover_charm" } else {},
		Quest = if preview
			then { Title = "A KNIGHT'S BEGINNING", Objective = "Speak to the village elder", Distance = 142 }
			else nil,
		Attributes = if preview
			then { Vitality = 24, Strength = 18, Magic = 32, Defense = 16 }
			else { Vitality = 0, Strength = 0, Magic = 0, Defense = 0 },
		Hotbar = if preview
			then {
				{ Name = "IRON LONGSWORD", Icon = "Sword", Color = "Muted" },
				{ Name = "WIND CUTTER", Icon = "Wind", Color = "Green" },
				{ Name = "GALE STEP", Icon = "Wind", Color = "Mana" },
				{ Name = "TOWERING TORNADO", Icon = "Magic", Color = "Green" },
				{ Name = "HEALTH POTION", Icon = "Potion", Color = "Health" },
			}
			else {},
	}
end

local function cleanString(value, fallback, limit)
	return if type(value) == "string" then string.sub(value, 1, limit or 160) else fallback
end

local function cleanNumber(value, fallback)
	return if finite(value) then math.max(0, math.floor(value)) else fallback
end

local function cleanRecords(records, spells)
	local result, seen = {}, {}
	for index = 1, math.min(#records, 300) do
		local record = records[index]
		if type(record) ~= "table" or type(record.Id) ~= "string" or record.Id == "" then
			continue
		end
		local id = cleanString(record.Id, "", 64)
		if seen[id] then
			continue
		end
		seen[id] = true
		local value = {
			Id = id,
			Name = cleanString(record.Name, "Unnamed", 48),
			Description = cleanString(record.Description, "", 600),
			Icon = cleanString(record.Icon, if spells then "Magic" else "Bag", 32),
			Color = cleanString(record.Color, "Gold", 32),
			LevelRequired = cleanNumber(record.LevelRequired, 1),
		}
		if spells then
			value.Learned = record.Learned == true
			value.ManaCost = cleanNumber(record.ManaCost, 0)
			value.Cooldown = if finite(record.Cooldown) then math.max(0, record.Cooldown) else 0
			value.Type = cleanString(record.Type, "Spell", 32)
		else
			value.Category = if table.find(Model.ItemCategories, record.Category) and record.Category ~= "All"
				then record.Category
				else "Materials"
			local categorySlots = { Weapons = "Weapon", Armor = "Armor", Accessories = "Accessory" }
			value.Slot = categorySlots[value.Category]
			value.Rarity = if Model.RarityColors[record.Rarity] then record.Rarity else "Common"
			value.Count = cleanNumber(record.Count, 1)
			if value.Count == 0 then
				continue
			end
			value.Bonuses = {}
			if type(record.Bonuses) == "table" then
				for _, attribute in Model.AttributeOrder do
					if finite(record.Bonuses[attribute]) then
						value.Bonuses[attribute] = math.floor(record.Bonuses[attribute])
					end
				end
			end
		end
		table.insert(result, value)
	end
	return result
end

function Model.Find(records, id)
	for _, record in records do
		if record.Id == id then
			return record
		end
	end
	return nil
end

function Model.SpellAvailable(data, spell)
	return spell ~= nil and spell.Learned and data.Level >= spell.LevelRequired
end

function Model.SpellSlot(data, id)
	for slot = 2, 4 do
		if data.SpellSlots[slot] == id then
			return slot
		end
	end
	return nil
end

function Model.FilterItems(data, category, query)
	local result = {}
	local search = string.lower(query or "")
	for _, item in data.Inventory do
		if
			(category == "All" or item.Category == category) and string.find(string.lower(item.Name), search, 1, true)
		then
			table.insert(result, item)
		end
	end
	return result
end

function Model.FilterSpells(data, filter)
	local result = {}
	for _, spell in data.Spells do
		local available = Model.SpellAvailable(data, spell)
		if filter == "All" or (filter == "Learned" and available) or (filter == "Locked" and not available) then
			table.insert(result, spell)
		end
	end
	return result
end

function Model.ItemDelta(data, item, attribute)
	local equipped = if item.Slot then Model.Find(data.Inventory, data.Equipped[item.Slot]) else nil
	return (item.Bonuses[attribute] or 0) - (if equipped then equipped.Bonuses[attribute] or 0 else 0)
end

function Model.BindSpell(data, id, slot)
	local spell = Model.Find(data.Spells, id)
	if not spell then
		return nil, "Choose a spell first."
	end
	if slot ~= 0 and (type(slot) ~= "number" or slot % 1 ~= 0 or slot < 2 or slot > 4) then
		return nil, "Choose spell slot 2, 3, or 4."
	end
	if slot ~= 0 and not Model.SpellAvailable(data, spell) then
		return nil, "This spell is still locked."
	end
	local updated = table.clone(data)
	updated.SpellSlots = table.clone(data.SpellSlots)
	updated.Hotbar = table.clone(data.Hotbar)
	for index = 2, 4 do
		if updated.SpellSlots[index] == id then
			updated.SpellSlots[index] = nil
			updated.Hotbar[index] = nil
		end
	end
	if slot ~= 0 then
		updated.SpellSlots[slot] = id
		updated.Hotbar[slot] = { Name = string.upper(spell.Name), Icon = spell.Icon, Color = spell.Color }
	end
	return updated
end

function Model.EquipItem(data, id)
	local item = Model.Find(data.Inventory, id)
	if not item or not item.Slot then
		return nil, "This item cannot be equipped."
	end
	local removing = data.Equipped[item.Slot] == id
	if not removing and data.Level < item.LevelRequired then
		return nil, "Your level is too low for this item."
	end
	local updated = table.clone(data)
	updated.Equipped = table.clone(data.Equipped)
	updated.Equipped[item.Slot] = if removing then nil else id
	if item.Slot == "Weapon" then
		updated.Hotbar = table.clone(data.Hotbar)
		updated.Hotbar[1] = if removing
			then nil
			else { Name = string.upper(item.Name), Icon = item.Icon, Color = item.Color }
	end
	return updated
end

function Model.Patch(current, patch)
	local nextData = table.clone(current)
	for key, value in patch do
		if numericFields[key] and finite(value) then
			nextData[key] = math.max(0, math.floor(value))
		elseif stringFields[key] and type(value) == "string" then
			nextData[key] = string.sub(value, 1, 80)
		elseif key == "Grimoire" and type(value) == "table" then
			local book = table.clone(current.Grimoire)
			for _, field in { "Name", "Affinity" } do
				book[field] = cleanString(value[field], book[field], 48)
			end
			for _, field in { "Leaves", "Mastery", "XP", "XPToNext" } do
				book[field] = cleanNumber(value[field], book[field])
			end
			nextData.Grimoire = book
		elseif (key == "Spells" or key == "Inventory") and type(value) == "table" then
			nextData[key] = cleanRecords(value, key == "Spells")
		elseif key == "Equipped" and type(value) == "table" then
			nextData.Equipped = {}
			for _, slot in Model.EquipmentSlots do
				if type(value[slot]) == "string" then
					nextData.Equipped[slot] = cleanString(value[slot], "", 64)
				end
			end
		elseif key == "SpellSlots" and type(value) == "table" then
			nextData.SpellSlots = {}
			local seen = {}
			for slot = 2, 4 do
				local id = if type(value[slot]) == "string" then cleanString(value[slot], "", 64) else nil
				if id and not seen[id] then
					nextData.SpellSlots[slot] = id
					seen[id] = true
				end
			end
		elseif key == "SafeZone" and type(value) == "boolean" then
			nextData.SafeZone = value
		elseif key == "Attributes" and type(value) == "table" then
			local attributes = table.clone(current.Attributes)
			for _, attribute in Model.AttributeOrder do
				if finite(value[attribute]) then
					attributes[attribute] = math.max(0, math.floor(value[attribute]))
				end
			end
			nextData.Attributes = attributes
		elseif key == "Quest" then
			if value == false then
				nextData.Quest = nil
			elseif type(value) == "table" and type(value.Title) == "string" and type(value.Objective) == "string" then
				nextData.Quest = {
					Title = string.sub(value.Title, 1, 60),
					Objective = string.sub(value.Objective, 1, 120),
					Distance = if finite(value.Distance) then math.max(0, math.floor(value.Distance)) else nil,
					TargetPosition = if typeof(value.TargetPosition) == "Vector3"
							and finite(value.TargetPosition.X)
							and finite(value.TargetPosition.Y)
							and finite(value.TargetPosition.Z)
						then value.TargetPosition
						else nil,
				}
			end
		elseif key == "Hotbar" and type(value) == "table" then
			local entries = {}
			for index = 1, 5 do
				local entry = value[index]
				if type(entry) == "table" and type(entry.Name) == "string" then
					entries[index] = {
						Name = string.sub(entry.Name, 1, 40),
						Icon = if type(entry.Icon) == "string" then entry.Icon else "Magic",
						Color = if type(entry.Color) == "string" then entry.Color else "Gold",
					}
				end
			end
			nextData.Hotbar = entries
		end
	end
	return nextData
end

function Model.CountPending(pending)
	local total = 0
	for _, name in Model.AttributeOrder do
		total += pending[name] or 0
	end
	return total
end

function Model.Stage(data, pending, attribute)
	if not table.find(Model.AttributeOrder, attribute) or Model.CountPending(pending) >= data.UnspentPoints then
		return pending
	end
	local nextPending = table.clone(pending)
	nextPending[attribute] = (nextPending[attribute] or 0) + 1
	return nextPending
end

function Model.Allocate(data, pending)
	for name, count in pending do
		if not table.find(Model.AttributeOrder, name) or not finite(count) or count < 0 or count % 1 ~= 0 then
			return nil, "Invalid allocation"
		end
	end
	local count = Model.CountPending(pending)
	if count <= 0 or count > data.UnspentPoints then
		return nil, "Not enough available points"
	end
	local nextData = table.clone(data)
	nextData.Attributes = table.clone(data.Attributes)
	nextData.UnspentPoints -= count
	for name, amount in pending do
		nextData.Attributes[name] += amount
	end
	return nextData
end

function Model.FormatNumber(value)
	local text = tostring(math.floor(math.max(0, value)))
	local grouped = string.reverse(text):gsub("(%d%d%d)", "%1,")
	return string.reverse(grouped):gsub("^,", "")
end

function Model.FormatShort(value)
	local amount = math.max(0, value)
	for _, unit in { { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } } do
		if amount >= unit[1] then
			local rounded = math.floor(amount / unit[1] * 10) / 10
			return (
				if rounded >= 10 then tostring(math.floor(rounded)) else string.format("%.1f", rounded):gsub("%.0$", "")
			) .. unit[2]
		end
	end
	return Model.FormatNumber(amount)
end

function Model.Ratio(current, maximum)
	return if maximum > 0 then math.clamp(current / maximum, 0, 1) else 0
end

return Model
