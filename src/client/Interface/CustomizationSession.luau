local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Appearance = require(script.Parent.AppearanceModel)

return function(scope, state, actions, getSaveHandler)
	local alive = true
	local revision = 0
	local session = {}
	state.Appearance = scope:Value(Appearance.Defaults())
	state.AppearanceDraft = scope:Value(Appearance.Defaults())
	state.AppearanceBusy = scope:Value(false)
	state.AppearanceAvailable = scope:Value(state.Preview or getSaveHandler() ~= nil)
	state.AppearanceMessage = scope:Value("")
	state.AppearanceSection = scope:Value("Appearance")
	state.PreviewRotation = scope:Value(0)
	state.PreviewFocus = scope:Value("Body")
	state.AppearanceDirty = scope:Computed(function(use)
		return not Appearance.Equal(use(state.Appearance), use(state.AppearanceDraft))
	end)
	table.insert(scope, function()
		alive = false
	end)
	function session.Replace(values)
		revision += 1
		local nextAppearance = Appearance.Patch(Fusion.peek(state.Appearance), values)
		state.Appearance:set(nextAppearance)
		state.AppearanceDraft:set(table.clone(nextAppearance))
		state.AppearanceBusy:set(false)
	end
	function session.Begin()
		if not Fusion.peek(state.AppearanceBusy) then
			state.AppearanceDraft:set(table.clone(Fusion.peek(state.Appearance)))
			state.AppearanceMessage:set("")
			state.PreviewRotation:set(0)
		end
	end
	function actions.ChangeAppearance(field, value)
		if not Fusion.peek(state.AppearanceBusy) then
			state.AppearanceDraft:set(Appearance.Patch(Fusion.peek(state.AppearanceDraft), { [field] = value }))
			state.AppearanceMessage:set("")
		end
	end
	function actions.CycleAppearance(field, direction)
		if not Fusion.peek(state.AppearanceBusy) then
			state.AppearanceDraft:set(Appearance.Cycle(Fusion.peek(state.AppearanceDraft), field, direction))
			state.AppearanceMessage:set("")
		end
	end
	function actions.ResetAppearance()
		if not Fusion.peek(state.AppearanceBusy) then
			state.AppearanceDraft:set(table.clone(Fusion.peek(state.Appearance)))
			state.AppearanceMessage:set("")
		end
	end
	function actions.RotateAppearance(direction)
		state.PreviewRotation:set((Fusion.peek(state.PreviewRotation) + direction * 45) % 360)
	end
	function actions.SaveAppearance()
		if Fusion.peek(state.AppearanceBusy) or not Fusion.peek(state.AppearanceAvailable) then
			return
		end
		local draft = table.clone(Fusion.peek(state.AppearanceDraft))
		if state.Preview then
			session.Replace(draft)
			actions.Close()
			return
		end
		local handler = getSaveHandler()
		if not handler then
			return
		end
		state.AppearanceBusy:set(true)
		state.AppearanceMessage:set("")
		local requestRevision = revision
		task.spawn(function()
			local ok, accepted, result = pcall(handler, table.freeze(draft))
			if not alive or revision ~= requestRevision then
				return
			end
			state.AppearanceBusy:set(false)
			if ok and accepted == true and type(result) == "table" then
				session.Replace(result)
				if Fusion.peek(state.Open) and Fusion.peek(state.Page) == "Customization" then
					actions.Close()
				end
			else
				local message = if ok and type(result) == "string" then result else "Unable to save. Please try again."
				state.AppearanceMessage:set(message)
				actions.Notify(message)
			end
		end)
	end
	return session
end
