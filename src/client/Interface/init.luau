local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local Fusion = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Fusion"))
local Config = require(script.Config)
local Theme = require(script.Theme)
local Model = require(script.Model)
local Layout = require(script.Layout)
local UI = require(script.Components)
local HUD = require(script.HUD)
local QuestNavigation = require(script.QuestNavigation)
local CharacterWindow = require(script.CharacterWindow)
local CustomizationSession = require(script.CustomizationSession)

local Children = Fusion.Children
local Interface = {}
local handlers = {}
local active = nil
local queuedData = {}
local queuedAppearance = {}
local fields = {
	"Name",
	"Level",
	"XP",
	"XPToNext",
	"Health",
	"MaxHealth",
	"Mana",
	"MaxMana",
	"Stamina",
	"MaxStamina",
	"Coins",
	"Gems",
	"UnspentPoints",
	"MagicPower",
	"Rank",
	"Squad",
	"Location",
	"SafeZone",
	"Quest",
	"Attributes",
	"Hotbar",
	"Grimoire",
	"Spells",
	"SpellSlots",
	"Inventory",
	"Equipped",
}

function Interface.Configure(options)
	assert(type(options) == "table", "Interface.Configure expects a table")
	for _, name in { "AllocatePoints", "ActivateSlot", "BindSpell", "EquipItem", "SaveAppearance" } do
		if options[name] ~= nil then
			assert(type(options[name]) == "function", name .. " must be a function")
			handlers[name] = options[name]
		end
	end
	if active then
		active.State.AllocationAvailable:set(active.State.Preview or handlers.AllocatePoints ~= nil)
		active.State.BindingAvailable:set(active.State.Preview or handlers.BindSpell ~= nil)
		active.State.EquipmentAvailable:set(active.State.Preview or handlers.EquipItem ~= nil)
		active.State.AppearanceAvailable:set(active.State.Preview or handlers.SaveAppearance ~= nil)
	end
end

function Interface.SetAppearance(values)
	assert(type(values) == "table", "Interface.SetAppearance expects a table")
	if active then
		active.SetAppearance(values)
	else
		for field, value in values do
			queuedAppearance[field] = value
		end
	end
end

function Interface.SetData(patch)
	assert(type(patch) == "table", "Interface.SetData expects a table")
	if active then
		active.SetData(patch)
	else
		for key, value in patch do
			queuedData[key] = value
		end
	end
end

function Interface.SetCooldown(slot, duration)
	if not active or type(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > 5 then
		return
	end
	if type(duration) ~= "number" or duration ~= duration or math.abs(duration) == math.huge then
		return
	end
	local nextCooldowns = table.clone(Fusion.peek(active.State.Cooldowns))
	nextCooldowns[slot] = if duration > 0 then os.clock() + duration else nil
	active.State.Now:set(os.clock())
	active.State.Cooldowns:set(nextCooldowns)
end

function Interface.Open(page)
	if active then
		active.Actions.Open(page)
	end
end

function Interface.Close()
	if active then
		active.Actions.Close()
	end
end

function Interface.Destroy()
	if active then
		active.Destroy()
	end
end

function Interface:OnStart()
	if active or not RunService:IsClient() then
		return
	end
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local preview = RunService:IsStudio() and Config.PreviewInStudio
	local scope = Fusion:scoped()
	local alive = true
	local state = {
		Preview = preview,
		Data = scope:Value(Model.Patch(Model.Defaults(preview, player.DisplayName), queuedData)),
		Open = scope:Value(Config.OpenStatsOnStart),
		MenuOpen = scope:Value(false),
		NavigationEnabled = scope:Value(false),
		QuestHeading = scope:Value(nil),
		QuestDistance = scope:Value(nil),
		Page = scope:Value(if table.find(Model.Pages, Config.StartPage) then Config.StartPage else "Stats"),
		Pending = scope:Value({}),
		Busy = scope:Value(false),
		AllocationAvailable = scope:Value(preview or handlers.AllocatePoints ~= nil),
		BindingAvailable = scope:Value(preview or handlers.BindSpell ~= nil),
		EquipmentAvailable = scope:Value(preview or handlers.EquipItem ~= nil),
		SpellFilter = scope:Value("All"),
		SelectedSpellId = scope:Value("wind_cutter"),
		SpellTargetSlot = scope:Value(2),
		ItemFilter = scope:Value("All"),
		ItemQuery = scope:Value(""),
		SelectedItemId = scope:Value("gale_saber"),
		SelectedSlot = scope:Value(1),
		Cooldowns = scope:Value({}),
		Now = scope:Value(os.clock()),
		Heading = scope:Value(0),
		Viewport = scope:Value(Vector2.new(1440, 860)),
		Character = scope:Value(nil),
		CharacterRevision = scope:Value(0),
		Toast = scope:Value(nil),
		Fields = {},
	}
	if preview and queuedData.Quest == nil then
		local fixture = Fusion.peek(state.Data)
		if fixture.Quest and not fixture.Quest.TargetPosition then
			fixture.Quest.TargetPosition = Vector3.new(0, 4, -142)
		end
	end
	queuedData = {}
	for _, name in fields do
		state.Fields[name] = scope:Value(Fusion.peek(state.Data)[name])
	end
	state.FilteredSpells = scope:Computed(function(use)
		return Model.FilterSpells(
			{ Spells = use(state.Fields.Spells), Level = use(state.Fields.Level) },
			use(state.SpellFilter)
		)
	end)
	state.SelectedSpell = scope:Computed(function(use)
		local entries = use(state.FilteredSpells)
		return Model.Find(entries, use(state.SelectedSpellId)) or entries[1]
	end)
	state.FilteredItems = scope:Computed(function(use)
		return Model.FilterItems(
			{ Inventory = use(state.Fields.Inventory) },
			use(state.ItemFilter),
			use(state.ItemQuery)
		)
	end)
	state.SelectedItem = scope:Computed(function(use)
		local entries = use(state.FilteredItems)
		return Model.Find(entries, use(state.SelectedItemId)) or entries[1]
	end)
	state.Layout = scope:Computed(function(use)
		local size = use(state.Viewport)
		return Layout.Resolve(size.X, size.Y, UserInputService.TouchEnabled, use(state.MenuOpen))
	end)
	state.Scale = scope:Computed(function(use)
		return use(state.Layout).Scale
	end)
	state.Mobile = scope:Computed(function(use)
		return use(state.Layout).TouchControls
	end)
	state.Compact = scope:Computed(function(use)
		return use(state.Layout).Compact
	end)
	state.Tight = scope:Computed(function(use)
		return use(state.Layout).Tight
	end)
	state.PendingCount = scope:Computed(function(use)
		return Model.CountPending(use(state.Pending))
	end)
	state.PointsRemaining = scope:Computed(function(use)
		return math.max(0, use(state.Fields.UnspentPoints) - use(state.PendingCount))
	end)
	state.CanAllocate = scope:Computed(function(use)
		return use(state.AllocationAvailable) and use(state.Fields.UnspentPoints) > 0
	end)
	local actions = {}
	local gui
	local previousSelection
	local toastSerial = 0
	local allocationRevision = 0
	local collectionRevision = 0

	local function publish(data)
		local previous = Fusion.peek(state.Data)
		state.Data:set(data)
		for _, name in fields do
			if previous[name] ~= data[name] then
				state.Fields[name]:set(data[name])
			end
		end
	end

	local function setData(patch)
		if not alive then
			return
		end
		publish(Model.Patch(Fusion.peek(state.Data), patch))
		if patch.Attributes or patch.UnspentPoints ~= nil then
			allocationRevision += 1
			state.Pending:set({})
		end
		if patch.Spells or patch.SpellSlots or patch.Inventory or patch.Equipped then
			collectionRevision += 1
		end
	end

	function actions.Notify(message, title)
		if not alive then
			return
		end
		toastSerial += 1
		local serial = toastSerial
		state.Toast:set({ Title = title or "CLOVER KINGDOM", Body = message })
		task.delay(3.5, function()
			if alive and serial == toastSerial then
				state.Toast:set(nil)
			end
		end)
	end

	local appearance = CustomizationSession(scope, state, actions, function()
		return handlers.SaveAppearance
	end)
	appearance.Replace(queuedAppearance)
	queuedAppearance = {}

	function actions.Open(page)
		local target = page or "Stats"
		if not table.find(Model.Pages, target) then
			return
		end
		if Fusion.peek(state.Open) and Fusion.peek(state.Page) == target then
			return
		end
		local wasOpen = Fusion.peek(state.Open)
		if target == "Customization" then
			appearance.Begin()
		end
		state.MenuOpen:set(false)
		state.Page:set(target)
		state.Open:set(true)
		if string.find(UserInputService:GetLastInputType().Name, "Gamepad") and gui then
			if not wasOpen then
				previousSelection = GuiService.SelectedObject
			end
			task.defer(function()
				if alive and Fusion.peek(state.Open) then
					GuiService.SelectedObject = gui:FindFirstChild("Close", true)
				end
			end)
		end
	end

	function actions.Close()
		state.Open:set(false)
		if gui and GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui) then
			GuiService.SelectedObject = if previousSelection and previousSelection.Parent
				then previousSelection
				else nil
		end
	end

	function actions.Toggle(page)
		local target = page or "Stats"
		if Fusion.peek(state.Open) and Fusion.peek(state.Page) == target then
			actions.Close()
		else
			actions.Open(target)
		end
	end

	function actions.ToggleMenu()
		if Fusion.peek(state.Open) then
			actions.Close()
		end
		local expanded = not Fusion.peek(state.MenuOpen)
		state.MenuOpen:set(expanded)
		if string.find(UserInputService:GetLastInputType().Name, "Gamepad") and gui then
			task.defer(function()
				if alive then
					local menu = gui:FindFirstChild("Menu", true)
					GuiService.SelectedObject = menu
						and menu:FindFirstChild(if expanded then "Stats" else "MenuToggle", true)
				end
			end)
		end
	end

	function actions.ToggleNavigation()
		local quest = Fusion.peek(state.Fields.Quest)
		if not Fusion.peek(state.NavigationEnabled) and (not quest or not quest.TargetPosition) then
			actions.Notify(
				if quest then "This quest has no destination yet." else "You have no active quest.",
				"QUEST NAVIGATION"
			)
			return
		end
		state.NavigationEnabled:set(not Fusion.peek(state.NavigationEnabled))
	end

	function actions.Stage(name)
		if not Fusion.peek(state.CanAllocate) or Fusion.peek(state.Busy) then
			return
		end
		state.Pending:set(Model.Stage(Fusion.peek(state.Data), Fusion.peek(state.Pending), name))
	end

	function actions.Undo()
		if not Fusion.peek(state.Busy) then
			state.Pending:set({})
		end
	end

	function actions.Apply()
		if Fusion.peek(state.Busy) or not Fusion.peek(state.CanAllocate) then
			return
		end
		local allocation = table.clone(Fusion.peek(state.Pending))
		local nextData = Model.Allocate(Fusion.peek(state.Data), allocation)
		if not nextData then
			return
		end
		if preview then
			publish(nextData)
			state.Pending:set({})
			actions.Notify("Attributes updated for this preview.", "POINTS ALLOCATED")
			return
		end
		local allocate = handlers.AllocatePoints
		if not allocate then
			return
		end
		state.Busy:set(true)
		local revision = allocationRevision
		task.spawn(function()
			local ok, accepted, response = pcall(allocate, allocation)
			if not alive then
				return
			end
			state.Busy:set(false)
			if not ok or accepted ~= true then
				actions.Notify(
					if ok and type(response) == "string"
						then response
						else "Couldn't allocate points. Please try again.",
					"ALLOCATION FAILED"
				)
				return
			end
			state.Pending:set({})
			if type(response) == "table" and revision == allocationRevision then
				setData(response)
			end
			actions.Notify("Your attributes have been updated.", "POINTS ALLOCATED")
		end)
	end

	function actions.FilterSpells(filter)
		if table.find(Model.SpellFilters, filter) then
			state.SpellFilter:set(filter)
		end
	end

	function actions.SelectSpell(id)
		if Model.Find(Fusion.peek(state.Fields.Spells), id) then
			state.SelectedSpellId:set(id)
		end
	end

	function actions.SelectSpellSlot(slot)
		if slot == 2 or slot == 3 or slot == 4 then
			state.SpellTargetSlot:set(slot)
		end
	end

	function actions.FilterItems(filter)
		if table.find(Model.ItemCategories, filter) then
			state.ItemFilter:set(filter)
		end
	end

	function actions.SearchItems(query)
		state.ItemQuery:set(string.sub(query, 1, 80))
	end

	function actions.SelectItem(id, reveal)
		if not Model.Find(Fusion.peek(state.Fields.Inventory), id) then
			return
		end
		if reveal then
			state.ItemFilter:set("All")
			state.ItemQuery:set("")
		end
		state.SelectedItemId:set(id)
	end

	local function updateCollection(nextData, handlerName, arguments, message)
		if not nextData or Fusion.peek(state.Busy) then
			return
		end
		if preview then
			publish(nextData)
			actions.Notify(message, "LOADOUT UPDATED")
			return
		end
		local handler = handlers[handlerName]
		if not handler then
			return
		end
		state.Busy:set(true)
		local revision = collectionRevision
		task.spawn(function()
			local ok, accepted, response = pcall(handler, table.unpack(arguments))
			if not alive then
				return
			end
			state.Busy:set(false)
			if not ok or accepted ~= true then
				actions.Notify(
					if ok and type(response) == "string"
						then response
						else "The loadout could not be updated. Try again.",
					"UPDATE FAILED"
				)
				return
			end
			if type(response) == "table" and revision == collectionRevision then
				setData(response)
			end
			actions.Notify(message, "LOADOUT UPDATED")
		end)
	end

	function actions.BindSelectedSpell(slot)
		local spell = Fusion.peek(state.SelectedSpell)
		if not spell or not Fusion.peek(state.BindingAvailable) or Fusion.peek(state.Busy) then
			return
		end
		local updated, reason = Model.BindSpell(Fusion.peek(state.Data), spell.Id, slot)
		if not updated then
			actions.Notify(reason, "SPELL UNAVAILABLE")
			return
		end
		updateCollection(
			updated,
			"BindSpell",
			{ spell.Id, slot },
			if slot == 0 then "Spell removed from the hotbar." else spell.Name .. " assigned to slot " .. slot .. "."
		)
	end

	function actions.EquipSelectedItem()
		local item = Fusion.peek(state.SelectedItem)
		if not item or not Fusion.peek(state.EquipmentAvailable) or Fusion.peek(state.Busy) then
			return
		end
		local data = Fusion.peek(state.Data)
		local updated, reason = Model.EquipItem(data, item.Id)
		if not updated then
			actions.Notify(reason, "ITEM UNAVAILABLE")
			return
		end
		local equipping = data.Equipped[item.Slot] ~= item.Id
		updateCollection(
			updated,
			"EquipItem",
			{ item.Id, equipping },
			item.Name .. (if equipping then " equipped." else " unequipped.")
		)
	end

	function actions.ActivateSlot(index)
		if Fusion.peek(state.Open) then
			return
		end
		local data = Fusion.peek(state.Data)
		local entry = data.Hotbar[index]
		if not entry or (Fusion.peek(state.Cooldowns)[index] or 0) > os.clock() then
			return
		end
		state.SelectedSlot:set(index)
		if handlers.ActivateSlot then
			task.spawn(function()
				local ok, err = pcall(handlers.ActivateSlot, index)
				if not ok and alive then
					warn("[Interface] ActivateSlot failed: " .. tostring(err))
					actions.Notify("This ability couldn't be used.")
				end
			end)
		elseif preview then
			Interface.SetCooldown(index, if index == 1 then 0.7 else 3)
		end
	end

	QuestNavigation(scope, state, playerGui)
	gui = scope:New("ScreenGui")({
		Name = "CloverInterface",
		Parent = playerGui,
		ResetOnSpawn = false,
		DisplayOrder = Config.DisplayOrder,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ClipToDeviceSafeArea = true,
		[Children] = UI.Frame(scope, {
			Name = "SafeArea",
			Size = UDim2.fromScale(1, 1),
			[Fusion.Out("AbsoluteSize")] = state.Viewport,
			[Children] = UI.Canvas(scope, state.Scale, {
				HUD.Body(scope, state, actions),
				CharacterWindow(scope, state, actions),
				UI.Panel(scope, {
					Name = "Notification",
					Padding = 12,
					Position = UDim2.new(0.5, 0, 0, 108),
					AnchorPoint = Vector2.new(0.5, 0),
					Size = scope:Computed(function(use)
						return UDim2.fromOffset(math.min(420, math.max(280, use(state.Viewport).X - 32)), 78)
					end),
					Visible = scope:Computed(function(use)
						return use(state.Toast) ~= nil
					end),
					ZIndex = 20,
					BorderColor = Theme.GoldDim,
					[Children] = {
						UI.Icon(scope, {
							Icon = "Clover",
							Color = Theme.Green,
							Position = UDim2.fromOffset(8, 13),
							Size = UDim2.fromOffset(28, 28),
						}),
						UI.Text(scope, {
							Position = UDim2.fromOffset(49, 6),
							Size = UDim2.new(1, -59, 0, 18),
							Font = Theme.PixelFont,
							TextSize = 14,
							TextColor3 = Theme.GoldLight,
							Text = scope:Computed(function(use)
								local value = use(state.Toast)
								return if value then value.Title else ""
							end),
						}),
						UI.Text(scope, {
							Position = UDim2.fromOffset(49, 27),
							Size = UDim2.new(1, -59, 0, 31),
							TextSize = 16,
							TextWrapped = true,
							Text = scope:Computed(function(use)
								local value = use(state.Toast)
								return if value then value.Body else ""
							end),
						}),
					},
				}),
			}),
		}),
	})
	scope:New("ScreenGui")({
		Name = "CloverNavigation",
		Parent = playerGui,
		ResetOnSpawn = false,
		DisplayOrder = Config.DisplayOrder - 1,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ClipToDeviceSafeArea = true,
		[Children] = UI.Canvas(scope, state.Scale, HUD.Navigation(scope, state)),
	})

	local coreHealthEnabled = true
	pcall(function()
		coreHealthEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	end)
	table.insert(scope, function()
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, coreHealthEnabled)
		end)
	end)

	local characterScope
	local characterSerial = 0
	local function bindCharacter(character)
		characterSerial += 1
		local serial = characterSerial
		if characterScope then
			characterScope:doCleanup()
		end
		characterScope = scope:innerScope()
		local bindingScope = characterScope
		state.Character:set(character)
		task.spawn(function()
			local humanoid = character:WaitForChild("Humanoid", 10)
			if not humanoid or not alive or serial ~= characterSerial then
				return
			end
			local function updateHealth()
				setData({ Health = humanoid.Health, MaxHealth = humanoid.MaxHealth })
			end
			updateHealth()
			table.insert(bindingScope, humanoid.HealthChanged:Connect(updateHealth))
			table.insert(bindingScope, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth))
			character:WaitForChild("Head", 5)
			if not alive or serial ~= characterSerial then
				return
			end
			state.CharacterRevision:set(Fusion.peek(state.CharacterRevision) + 1)
		end)
	end
	table.insert(scope, player.CharacterAdded:Connect(bindCharacter))
	table.insert(
		scope,
		player.CharacterRemoving:Connect(function()
			characterSerial += 1
			if characterScope then
				characterScope:doCleanup()
				characterScope = nil
			end
			state.Character:set(nil)
		end)
	)
	table.insert(
		scope,
		player.CharacterAppearanceLoaded:Connect(function(character)
			if character == player.Character then
				state.CharacterRevision:set(Fusion.peek(state.CharacterRevision) + 1)
			end
		end)
	)
	if player.Character then
		bindCharacter(player.Character)
	end

	local numericKeys = {
		[Enum.KeyCode.One] = 1,
		[Enum.KeyCode.Two] = 2,
		[Enum.KeyCode.Three] = 3,
		[Enum.KeyCode.Four] = 4,
		[Enum.KeyCode.Five] = 5,
	}
	table.insert(
		scope,
		UserInputService.InputBegan:Connect(function(input, processed)
			if input.KeyCode == Enum.KeyCode.ButtonB and (Fusion.peek(state.Open) or Fusion.peek(state.MenuOpen)) then
				actions.Close()
				state.MenuOpen:set(false)
				return
			end
			if processed or UserInputService:GetFocusedTextBox() then
				return
			end
			local key = input.KeyCode
			if key == Enum.KeyCode.M or key == Enum.KeyCode.ButtonY then
				actions.ToggleMenu()
			elseif
				(key == Enum.KeyCode.Escape or key == Enum.KeyCode.ButtonB)
				and (Fusion.peek(state.Open) or Fusion.peek(state.MenuOpen))
			then
				actions.Close()
				state.MenuOpen:set(false)
			elseif numericKeys[key] then
				actions.ActivateSlot(numericKeys[key])
			end
		end)
	)

	local elapsed = 0
	table.insert(
		scope,
		RunService.RenderStepped:Connect(function(delta)
			elapsed += delta
			if elapsed < 0.075 then
				return
			end
			elapsed = 0
			if next(Fusion.peek(state.Cooldowns)) then
				local now = os.clock()
				state.Now:set(now)
				local cooldowns = table.clone(Fusion.peek(state.Cooldowns))
				local changed = false
				for slot, deadline in cooldowns do
					if deadline <= now then
						cooldowns[slot] = nil
						changed = true
					end
				end
				if changed then
					state.Cooldowns:set(cooldowns)
				end
			end
		end)
	)

	active = { State = state, Actions = actions, SetData = setData, SetAppearance = appearance.Replace }
	function active.Destroy()
		if not alive then
			return
		end
		actions.Close()
		alive = false
		active = nil
		scope:doCleanup()
		require(ReplicatedStorage.Shared.Assets.StudioImages).Clear()
	end
	table.insert(
		scope,
		script.Destroying:Connect(function()
			Interface.Destroy()
		end)
	)
	local notificationModule = script.Parent:FindFirstChild("Notifications")
	if notificationModule then
		task.spawn(function()
			local ok, notifications = pcall(require, notificationModule)
			if not ok or not alive then
				return
			end
			local connection = notifications.OnNotification:Connect(function(notification)
				actions.Notify(notification.Body, notification.Title)
			end)
			table.insert(scope, function()
				connection:Disconnect()
			end)
		end)
	end
end

return Interface
