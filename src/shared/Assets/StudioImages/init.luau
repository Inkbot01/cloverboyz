local RunService = game:GetService("RunService")
local AssetService = game:GetService("AssetService")
local EncodingService = game:GetService("EncodingService")
local images = {}
local failed = {}
local StudioImages = {}

function StudioImages.Get(name)
	if not RunService:IsStudio() then
		return nil
	end
	if images[name] then
		return images[name]
	end
	if failed[name] then
		return nil
	end
	local source = script:FindFirstChild(name)
	if not source then
		return nil
	end
	local ok, result = pcall(function()
		local asset = require(source)
		local compressed = EncodingService:Base64Decode(buffer.fromstring(asset.Data))
		local pixels = EncodingService:DecompressBuffer(compressed, Enum.CompressionAlgorithm.Zstd)
		assert(buffer.len(pixels) == asset.Width * asset.Height * 4, "Invalid Studio image payload")
		local image = AssetService:CreateEditableImage({ Size = Vector2.new(asset.Width, asset.Height) })
		assert(image, "Studio EditableImage memory limit reached")
		local written, problem = pcall(image.WritePixelsBuffer, image, Vector2.zero, image.Size, pixels)
		if not written then
			image:Destroy()
			error(problem)
		end
		return image
	end)
	if not ok then
		failed[name] = true
		warn("Clover Studio artwork could not load " .. name .. ": " .. tostring(result))
		return nil
	end
	images[name] = result
	return result
end

function StudioImages.Clear()
	for _, image in images do
		image:Destroy()
	end

	table.clear(images)
	table.clear(failed)
end

return table.freeze(StudioImages)
