local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Theme = require(script.Parent.Theme)
local Motion = {}

function Motion.Presence(scope, open)
	local ready = scope:Value(false)
	local alive = true
	local progress = scope:Tween(
		scope:Computed(function(use)
			return if use(ready) and use(open) then 1 else 0
		end),
		Theme.WindowTween
	)
	table.insert(scope, function()
		alive = false
	end)
	task.defer(function()
		if alive then
			ready:set(true)
		end
	end)
	return {
		Progress = progress,
		Transparency = scope:Computed(function(use)
			return 1 - use(progress)
		end),
		Visible = scope:Computed(function(use)
			return use(open) or use(progress) > 0.001
		end),
	}
end

function Motion.Button(scope, enabled, activate)
	local hovered = scope:Value(false)
	local pressed = scope:Value(false)
	local function primary(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA
	end
	local function leave()
		hovered:set(false)
		pressed:set(false)
	end
	return {
		Hovered = hovered,
		Pressed = pressed,
		Bind = function(props)
			props[Fusion.OnEvent("MouseEnter")] = function()
				hovered:set(true)
			end
			props[Fusion.OnEvent("SelectionGained")] = function()
				hovered:set(true)
			end
			props[Fusion.OnEvent("MouseLeave")] = leave
			props[Fusion.OnEvent("SelectionLost")] = leave
			props[Fusion.OnEvent("InputBegan")] = function(input)
				if primary(input) and Fusion.peek(enabled) then
					pressed:set(true)
				end
			end
			props[Fusion.OnEvent("InputEnded")] = function(input)
				if primary(input) then
					pressed:set(false)
				end
			end
			props[Fusion.OnEvent("Activated")] = function()
				pressed:set(false)
				if Fusion.peek(enabled) and activate then
					activate()
				end
			end
			return props
		end,
	}
end

return table.freeze(Motion)
