local RunService = game:GetService("RunService")

return function(character)
	assert(RunService:IsStudio() and not RunService:IsRunning(), "This preview requires Studio Edit mode")
	assert(loadstring, "Refresh the preview from Studio's plugin or command-bar context")
	local root = script.Parent
	local assets = game:GetService("ReplicatedStorage").Shared.Assets
	local cache = {}
	local loading = {}
	local function freshRequire(module)
		if typeof(module) ~= "Instance" then
			return require(module)
		end
		if not module:IsDescendantOf(root) and module ~= assets.UI and module ~= assets.IconAtlas then
			return require(module)
		end
		if cache[module] ~= nil then
			return cache[module]
		end
		assert(not loading[module], "Circular preview dependency: " .. module:GetFullName())
		loading[module] = true
		local factory, message = loadstring(module.Source, "=" .. module:GetFullName())
		assert(factory, message)
		setfenv(factory, setmetatable({ script = module, require = freshRequire }, { __index = getfenv() }))
		local result = factory()
		assert(result ~= nil, "Preview module returned nil: " .. module:GetFullName())
		cache[module] = result
		loading[module] = nil
		return result
	end
	local mount = freshRequire(root.StudioPreview)
	local old = game:GetService("CoreGui"):FindFirstChild("CloverInterfacePreview")
	if old then
		local control = old:FindFirstChild("Control")
		if control then
			control:Invoke("Destroy")
		else
			old:Destroy()
		end
	end
	return mount(character)
end
