local Model = require("../src/client/Interface/Model")
local Layout = require("../src/client/Interface/Layout")
local Appearance = require("../src/client/Interface/AppearanceModel")
local passed = 0

local function check(condition, message)
	assert(condition, message)
	passed += 1
end

local preview = Model.Defaults(true, "Test Knight")
local live = Model.Defaults(false, "Test Knight")
local originalAppearance = Appearance.Defaults()
local recolored = Appearance.Patch(
	originalAppearance,
	{ SkinTone = "copper", HairColor = "silver", Outfit = "training", Scale = 1.05 }
)
check(recolored.SkinTone == "copper" and recolored.Scale == 1.05, "Valid appearance choices must reach the preview")
check(
	originalAppearance.SkinTone == "original" and originalAppearance.Scale == 1,
	"Draft appearance changes must not mutate the saved snapshot"
)
check(not Appearance.Equal(originalAppearance, recolored), "Appearance changes must be marked unsaved")
check(
	Appearance.Equal(originalAppearance, Appearance.Defaults()),
	"Identical appearance snapshots must not be marked unsaved"
)
for _, patch in
	{
		{ SkinTone = "unknown" },
		{ HairColor = {} },
		{ Face = false },
		{ Scale = 0 / 0 },
		{ Scale = math.huge },
		{ Scale = -1 },
		{ Scale = 10 },
		{ UnlockedRace = "Elf" },
		{ ShirtAssetId = "123" },
	}
do
	local result = Appearance.Patch(originalAppearance, patch)
	check(
		Appearance.Equal(originalAppearance, result) and result.UnlockedRace == nil and result.ShirtAssetId == nil,
		"Unknown cosmetics and invalid scale values must be rejected"
	)
end
check(
	Appearance.Cycle(originalAppearance, "Face", -1).Face == "blank",
	"Previous appearance selection must wrap to the last option"
)
check(
	Appearance.Cycle(Appearance.Patch(originalAppearance, { Face = "blank" }), "Face", 1).Face == "original",
	"Next appearance selection must wrap to the first option"
)
check(
	Appearance.Equal(Appearance.Cycle(originalAppearance, "Face", 1000), originalAppearance),
	"Unexpected selector directions must not change appearance"
)
check(
	Appearance.Patch(recolored, { Face = "classic" }).SkinTone == "copper",
	"Partial authoritative appearance updates must preserve other fields"
)
check(
	live.UnspentPoints == 0 and live.Quest == nil and next(live.Hotbar) == nil,
	"Live mode must not fabricate progression or abilities"
)
local pending = {}
for _ = 1, 10 do
	pending = Model.Stage(preview, pending, "Magic")
end
check(Model.CountPending(pending) == 3, "Repeated clicks must not overspend")
check(preview.Attributes.Magic == 32 and preview.UnspentPoints == 3, "Staging must not mutate the snapshot")
check(Model.Stage(preview, {}, "Unknown").Unknown == nil, "Unknown attributes cannot be staged")
local allocated = Model.Allocate(preview, pending)
check(
	allocated.Attributes.Magic == 35 and allocated.UnspentPoints == 0,
	"Apply must spend the staged points exactly once"
)
check(preview.Attributes.Magic == 32, "Apply must not mutate the previous snapshot")
check(Model.Allocate(allocated, pending) == nil, "The same allocation cannot be applied twice")
for _, invalid in { { Magic = -1 }, { Magic = 0.5 }, { Magic = math.huge }, { Magic = 0 / 0 }, { Unknown = 1 }, {} } do
	check(Model.Allocate(preview, invalid) == nil, "Invalid allocations must be rejected")
end
check(
	Model.Allocate(Model.Patch(preview, { UnspentPoints = 1 }), pending) == nil,
	"An authoritative point reduction must invalidate an oversized allocation"
)
local patched = Model.Patch(
	preview,
	{ Health = -5, Mana = math.huge, XP = 0 / 0, Attributes = { Magic = 50, Defense = -1 }, Unexpected = "ignored" }
)
check(
	patched.Health == 0 and patched.Mana == preview.Mana and patched.XP == preview.XP,
	"Numeric patches must remain finite and nonnegative"
)
check(
	patched.Attributes.Magic == 50 and patched.Attributes.Defense == 0 and patched.Attributes.Strength == 18,
	"Partial attribute patches must preserve other attributes"
)
check(
	preview.Attributes.Magic == 32 and patched.Unexpected == nil,
	"Patches must be immutable and reject unknown fields"
)
check(Model.Patch(preview, { Quest = false }).Quest == nil, "Completed quests can be cleared")
local Vector3 = require("@lune/roblox").Vector3
local target = Vector3.new(12, 4, -140)
local quest = Model.Patch(
	preview,
	{ Quest = { Title = "Reach the elder", Objective = "Speak to the elder", TargetPosition = target } }
).Quest
check(quest.TargetPosition == target, "Quest destinations survive validated snapshots")
local changedQuest = Model.Patch(
	{ Quest = quest },
	{ Quest = { Title = "Next quest", Objective = "Find a grimoire", TargetPosition = Vector3.new(120, 4, 80) } }
).Quest
check(
	changedQuest.TargetPosition ~= target and quest.TargetPosition == target,
	"The next quest replaces its destination without mutating the previous quest"
)
for _, invalid in { Vector3.new(0 / 0, 0, 0), Vector3.new(0, math.huge, 0), "village", { X = 1, Y = 2, Z = 3 } } do
	local result = Model.Patch(preview, { Quest = { Title = "Quest", Objective = "Travel", TargetPosition = invalid } })
	check(result.Quest.TargetPosition == nil, "Invalid quest positions must not reach the world marker")
end
local slots = Model.Patch(live, { Hotbar = { [3] = { Name = "Wind Cutter", Icon = "Wind" } } }).Hotbar
check(slots[1] == nil and slots[3].Name == "Wind Cutter", "Sparse hotbars must preserve slot positions")
check(
	Model.Ratio(120, 100) == 1 and Model.Ratio(-10, 100) == 0 and Model.Ratio(10, 0) == 0,
	"Bars must stay within their bounds"
)
check(
	Model.FormatNumber(1234567) == "1,234,567" and Model.FormatNumber(0) == "0",
	"Numbers must have consistent grouping"
)
check(#live.Spells == 0 and #live.Inventory == 0 and next(live.Equipped) == nil, "Live collections must start empty")
check(
	#Model.FilterSpells(preview, "Learned") == 3 and #Model.FilterSpells(preview, "Locked") == 3,
	"Spell filters must honor learning and level requirements"
)
check(
	#Model.FilterSpells(Model.Patch(preview, { Level = 1 }), "Learned") == 1,
	"Spells above the player's level must remain locked"
)
check(Model.BindSpell(preview, "wind_guard", 2) == nil, "A locked spell cannot be bound")
check(Model.BindSpell(preview, "missing", 2) == nil, "An unknown spell cannot be bound")
for _, slot in { -1, 1, 5, 2.5, math.huge, 0 / 0, "2" } do
	check(Model.BindSpell(preview, "wind_cutter", slot) == nil, "Only reserved spell slots can be assigned")
end
local rebound = Model.BindSpell(preview, "wind_cutter", 3)
check(
	rebound.SpellSlots[2] == nil and rebound.SpellSlots[3] == "wind_cutter",
	"Moving a spell must remove its previous binding"
)
check(
	rebound.Hotbar[2] == nil and rebound.Hotbar[3].Name == "WIND CUTTER",
	"The hotbar must match preview spell bindings"
)
check(
	preview.SpellSlots[2] == "wind_cutter" and preview.SpellSlots[3] == "gale_step",
	"Binding must not mutate the previous snapshot"
)
check(
	rebound.Hotbar[1] == preview.Hotbar[1] and rebound.Hotbar[5] == preview.Hotbar[5],
	"Spell binding must preserve weapon and consumable slots"
)
local unbound = Model.BindSpell(rebound, "wind_cutter", 0)
check(
	Model.SpellSlot(unbound, "wind_cutter") == nil and unbound.Hotbar[3] == nil,
	"Removing a spell must clear its hotbar slot"
)
check(
	Model.EquipItem(preview, "mana_crystal") == nil and Model.EquipItem(preview, "missing") == nil,
	"Materials and unowned items cannot be equipped"
)
check(Model.EquipItem(preview, "dusk_blade") == nil, "Gear level requirements must be enforced in preview")
local equipped = Model.EquipItem(preview, "gale_saber")
check(
	equipped.Equipped.Weapon == "gale_saber" and equipped.Hotbar[1].Name == "GALE SABER",
	"Equipping a weapon must update the loadout and weapon slot"
)
check(
	preview.Equipped.Weapon == "iron_blade" and equipped.Equipped.Armor == preview.Equipped.Armor,
	"Equip must preserve the original snapshot and other slots"
)
local unequipped = Model.EquipItem(equipped, "gale_saber")
check(
	unequipped.Equipped.Weapon == nil and unequipped.Hotbar[1] == nil,
	"Unequip must clear only the corresponding slot"
)
local saber = Model.Find(preview.Inventory, "gale_saber")
check(
	Model.ItemDelta(preview, saber, "Strength") == 4 and Model.ItemDelta(preview, saber, "Magic") == 6,
	"Comparison must use the currently equipped item in the same slot"
)
check(Model.ItemDelta(equipped, saber, "Strength") == 0, "An equipped item must compare to itself as zero")
check(
	#Model.FilterItems(preview, "Weapons", "sAbEr") == 1,
	"Filtering must combine category and case-insensitive search"
)
check(#Model.FilterItems(preview, "Armor", "saber") == 0, "Search results cannot leak from other categories")
check(#Model.FilterItems(preview, "All", "[") == 0, "Search text must be matched literally")
local sanitized = Model.Patch(live, {
	Inventory = {
		{
			Id = "ore",
			Name = "Ore",
			Category = "Materials",
			Slot = "Weapon",
			Count = 4,
			Bonuses = { Strength = math.huge },
		},
		{ Id = "ore", Name = "Duplicate", Count = 1 },
		{ Id = "empty", Count = 0 },
	},
	Spells = { { Id = "test", Name = "Test", Learned = true, ManaCost = -1, Cooldown = 0 / 0 }, { Id = "test" } },
	SpellSlots = { [1] = "test", [2] = "test", [3] = "test" },
})
check(
	#sanitized.Inventory == 1 and sanitized.Inventory[1].Slot == nil,
	"Inventory normalization must remove duplicates, empty stacks, and invalid equipment slots"
)
check(sanitized.Inventory[1].Bonuses.Strength == nil, "Invalid item bonuses must not reach the UI")
check(
	#sanitized.Spells == 1 and sanitized.Spells[1].ManaCost == 0 and sanitized.Spells[1].Cooldown == 0,
	"Spell records must be unique and numerically valid"
)
check(
	sanitized.SpellSlots[1] == nil and sanitized.SpellSlots[2] == "test" and sanitized.SpellSlots[3] == nil,
	"Replicated bindings must keep reserved slots and uniqueness"
)
local cleared = Model.Patch(preview, { Spells = {}, SpellSlots = {}, Inventory = {}, Equipped = {} })
check(
	#cleared.Inventory == 0 and #cleared.Spells == 0 and next(cleared.Equipped) == nil,
	"Authoritative empty snapshots must clear collections"
)
check(Model.FormatShort(999) == "999", "Small numbers should retain their exact value")
check(Model.FormatShort(1250) == "1.2K", "Compact numbers must not round above the actual amount")
check(Model.FormatShort(1e6) == "1M", "Millions need a readable compact label")
local initializing = Layout.Resolve(0, 0, false)
check(
	initializing.Panel.Width > 0 and initializing.Panel.Height > 0,
	"The initial zero-size ScreenGui must not create negative sizes"
)
for _, viewport in
	{
		{ 1672, 941, false },
		{ 1440, 860, false },
		{ 1280, 720, false },
		{ 1024, 768, false },
		{ 730, 640, false },
		{ 728, 582, false },
		{ 729, 582, false },
		{ 720, 640, false },
		{ 560, 640, false },
		{ 844, 390, true },
		{ 844, 332, true },
		{ 667, 317, true },
		{ 700, 332, true },
		{ 812, 317, true },
		{ 568, 320, true },
		{ 390, 844, true },
		{ 320, 568, true },
		{ 320, 510, true },
		{ 320, 480, true },
	}
do
	local width, height, touch = table.unpack(viewport)
	for _, menuOpen in { false, true } do
		local layout = Layout.Resolve(width, height, touch, menuOpen)
		local canvasWidth = layout.CanvasWidth
		local canvasHeight = layout.CanvasHeight
		check(math.abs(canvasWidth * layout.Scale - width) < 0.01, "The scaled canvas must fill the safe-area width")
		check(math.abs(canvasHeight * layout.Scale - height) < 0.01, "The scaled canvas must fill the safe-area height")
		local panel = layout.Panel
		check(
			panel.Width > 0 and panel.Height > 0 and panel.X >= 0 and panel.Y >= 0,
			"The character panel must fit the viewport"
		)
		check(math.abs(panel.X + panel.Width / 2 - canvasWidth / 2) < 0.01, "The character panel must remain centered")
		check(
			layout.HUDHeight + layout.StatusBottom <= canvasHeight,
			"The bottom HUD must fit above its reserved inset"
		)
		if layout.StackHUD then
			check(
				math.max(layout.Status.Width, layout.Hotbar.Width) <= canvasWidth - layout.Margin * 2,
				"Stacked HUD components must fit the safe width"
			)
		else
			check(
				layout.Status.Width
						+ layout.HUDGap
						+ layout.Hotbar.Width
						+ (if layout.MenuBeside then Layout.Menu(true).Width + layout.HUDGap else 0)
					<= canvasWidth - layout.Margin * 2,
				"The native bottom row must have enough space for both docks"
			)
		end
		if touch then
			check(layout.SlotSize >= 44 and layout.MenuButton >= 44, "Touch controls must retain usable targets")
		else
			check(layout.StatusBottom == layout.Margin, "Desktop status must remain at the bottom margin")
		end
		if menuOpen then
			check(
				Layout.Menu(layout.CompactHUD).Width <= canvasWidth - layout.Margin * 2,
				"The expanded menu must fit inside the safe area"
			)
		end
		if layout.ShowQuest then
			check(
				canvasHeight - layout.HUDHeight - layout.StatusBottom - 24 >= layout.Quest.Height + layout.Margin,
				"The quest must have a clear gap above both menu states"
			)
		end
	end
end
print("Interface checks passed: " .. passed)
