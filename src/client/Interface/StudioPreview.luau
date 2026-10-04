local RunService = game:GetService("RunService")
local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Model = require(script.Parent.Model)
local Layout = require(script.Parent.Layout)
local UI = require(script.Parent.Components)
local HUD = require(script.Parent.HUD)
local QuestNavigation = require(script.Parent.QuestNavigation)
local CharacterWindow = require(script.Parent.CharacterWindow)
local CustomizationSession = require(script.Parent.CustomizationSession)
local Children = Fusion.Children

return function(character)
	assert(RunService:IsStudio() and not RunService:IsRunning(), "This preview requires Studio Edit mode")
	local scope = Fusion:scoped()
	local data = Model.Defaults(true, "Asta")
	data.Health = 840
	data.MaxHealth = 1000
	data.Hotbar[1].Name = "Demon-Slayer"
	data.Hotbar[3].Icon = "Grimoire"
	data.Quest.TargetPosition = Vector3.new(0, 4, -142)
	local state = {
		Preview = true,
		Data = scope:Value(data),
		Fields = {},
		Open = scope:Value(false),
		MenuOpen = scope:Value(false),
		NavigationEnabled = scope:Value(false),
		QuestHeading = scope:Value(nil),
		QuestDistance = scope:Value(nil),
		Page = scope:Value("Stats"),
		Pending = scope:Value({}),
		Busy = scope:Value(false),
		AllocationAvailable = scope:Value(true),
		BindingAvailable = scope:Value(true),
		EquipmentAvailable = scope:Value(true),
		SpellFilter = scope:Value("All"),
		SelectedSpellId = scope:Value("wind_cutter"),
		SpellTargetSlot = scope:Value(2),
		ItemFilter = scope:Value("All"),
		ItemQuery = scope:Value(""),
		SelectedItemId = scope:Value("gale_saber"),
		SelectedSlot = scope:Value(1),
		Cooldowns = scope:Value({ [4] = 4.2 }),
		Now = scope:Value(0),
		Heading = scope:Value(0),
		Viewport = scope:Value(Vector2.new(1440, 860)),
		Character = scope:Value(character),
		CharacterRevision = scope:Value(0),
		FocusedAttribute = scope:Value("Magic"),
	}
	for name, value in data do
		state.Fields[name] = scope:Value(value)
	end
	state.Layout = scope:Computed(function(use)
		local size = use(state.Viewport)
		return Layout.Resolve(size.X, size.Y, false, use(state.MenuOpen))
	end)
	for _, name in { "Scale", "Compact", "Tight", "TouchControls" } do
		state[if name == "TouchControls" then "Mobile" else name] = scope:Computed(function(use)
			return use(state.Layout)[name]
		end)
	end
	state.PendingCount = scope:Computed(function(use)
		return Model.CountPending(use(state.Pending))
	end)
	state.PointsRemaining = scope:Computed(function(use)
		return math.max(0, use(state.Fields.UnspentPoints) - use(state.PendingCount))
	end)
	state.CanAllocate = scope:Computed(function(use)
		return use(state.Fields.UnspentPoints) > 0
	end)
	state.FilteredSpells = scope:Computed(function(use)
		return Model.FilterSpells(use(state.Data), use(state.SpellFilter))
	end)
	state.SelectedSpell = scope:Computed(function(use)
		return Model.Find(use(state.FilteredSpells), use(state.SelectedSpellId)) or use(state.FilteredSpells)[1]
	end)
	state.FilteredItems = scope:Computed(function(use)
		return Model.FilterItems(use(state.Data), use(state.ItemFilter), use(state.ItemQuery))
	end)
	state.SelectedItem = scope:Computed(function(use)
		return Model.Find(use(state.FilteredItems), use(state.SelectedItemId)) or use(state.FilteredItems)[1]
	end)
	local actions = {}
	local function publish(nextData)
		if not nextData then
			return
		end
		state.Data:set(nextData)
		for name, value in nextData do
			state.Fields[name]:set(value)
		end
	end
	local appearance = CustomizationSession(scope, state, actions, function()
		return nil
	end)
	function actions.Open(page)
		if page == "Customization" then
			appearance.Begin()
		end
		state.MenuOpen:set(false)
		state.Page:set(page or "Stats")
		state.Open:set(true)
	end
	function actions.Close()
		state.Open:set(false)
	end
	function actions.Toggle(page)
		if Fusion.peek(state.Open) and Fusion.peek(state.Page) == page then
			actions.Close()
		else
			actions.Open(page)
		end
	end
	function actions.ToggleMenu()
		state.Open:set(false)
		state.MenuOpen:set(not Fusion.peek(state.MenuOpen))
	end
	function actions.ToggleNavigation()
		state.NavigationEnabled:set(not Fusion.peek(state.NavigationEnabled))
	end

	function actions.Stage(name)
		state.Pending:set(Model.Stage(Fusion.peek(state.Data), Fusion.peek(state.Pending), name))
	end
	function actions.Undo()
		state.Pending:set({})
	end
	function actions.Apply()
		publish(Model.Allocate(Fusion.peek(state.Data), Fusion.peek(state.Pending)))
		state.Pending:set({})
	end
	function actions.ActivateSlot(index)
		state.SelectedSlot:set(index)
	end
	function actions.FilterSpells(value)
		state.SpellFilter:set(value)
	end
	function actions.SelectSpell(value)
		state.SelectedSpellId:set(value)
	end
	function actions.SelectSpellSlot(value)
		state.SpellTargetSlot:set(value)
	end
	function actions.FilterItems(value)
		state.ItemFilter:set(value)
	end
	function actions.SearchItems(value)
		state.ItemQuery:set(value)
	end
	function actions.SelectItem(value)
		state.SelectedItemId:set(value)
	end
	function actions.BindSelectedSpell(slot)
		local spell = Fusion.peek(state.SelectedSpell)
		if spell then
			publish(Model.BindSpell(Fusion.peek(state.Data), spell.Id, slot))
		end
	end
	function actions.EquipSelectedItem()
		local item = Fusion.peek(state.SelectedItem)
		if item then
			publish(Model.EquipItem(Fusion.peek(state.Data), item.Id))
		end
	end
	QuestNavigation(scope, state, game:GetService("CoreGui"))
	local gui = scope:New("ScreenGui")({
		Name = "CloverInterfacePreview",
		Parent = game:GetService("CoreGui"),
		ResetOnSpawn = false,
		DisplayOrder = 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ClipToDeviceSafeArea = true,
		[Children] = UI.Frame(scope, {
			Name = "SafeArea",
			Size = UDim2.fromScale(1, 1),
			[Fusion.Out("AbsoluteSize")] = state.Viewport,
			[Children] = UI.Canvas(
				scope,
				state.Scale,
				{ HUD.Body(scope, state, actions), CharacterWindow(scope, state, actions) }
			),
		}),
	})
	scope:New("ScreenGui")({
		Name = "CloverNavigationPreview",
		Parent = game:GetService("CoreGui"),
		ResetOnSpawn = false,
		DisplayOrder = 99,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ClipToDeviceSafeArea = true,
		[Children] = UI.Canvas(scope, state.Scale, HUD.Navigation(scope, state)),
	})
	table.insert(
		scope,
		RunService.Heartbeat:Connect(function()
			if RunService:IsRunning() then
				scope:doCleanup()
			end
		end)
	)
	local control = scope:New("BindableFunction")({ Name = "Control", Parent = gui })
	control.OnInvoke = function(command, argument)
		if command == "HUD" then
			actions.Close()
		elseif command == "Menu" then
			actions.ToggleMenu()
		elseif command == "Navigation" then
			actions.ToggleNavigation()
		elseif command == "Page" then
			actions.Open(argument or "Stats")
		elseif command == "Stage" then
			actions.Stage(argument)
		elseif command == "Undo" then
			actions.Undo()
		elseif command == "Apply" then
			actions.Apply()
		elseif command == "Destroy" then
			scope:doCleanup()
		end
		return true
	end
	return {
		State = state,
		Actions = actions,
		Destroy = function()
			scope:doCleanup()
		end,
	}
end
