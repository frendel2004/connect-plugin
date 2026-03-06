local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

local Context = {}

local function isCodeRelevant(instance: Instance): boolean
	return instance:IsA("LuaSourceContainer")
		or instance:IsA("Folder")
		or instance:IsA("RemoteEvent")
		or instance:IsA("RemoteFunction")
		or instance:IsA("BindableEvent")
		or instance:IsA("BindableFunction")
end

local function serializeCode(instance: Instance): {[string]: any}?
	if not isCodeRelevant(instance) then
		return nil
	end

	local data: {[string]: any} = {
		Name = instance.Name,
		ClassName = instance.ClassName,
		Path = instance:GetFullName(),
		Children = {},
	}

	if instance:IsA("LuaSourceContainer") then
		if instance:IsA("BaseScript") then
			data.Enabled = (instance :: BaseScript).Enabled
		end
	end

	for _, child in ipairs(instance:GetChildren()) do
		local childData = serializeCode(child)
		if childData then
			table.insert(data.Children, childData)
		end
	end

	return data
end

local function colorToHex(color: Color3): string
	return string.format("#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5))
end

local function serializeUI(instance: Instance): {[string]: any}
	local data: {[string]: any} = {
		Name = instance.Name,
		ClassName = instance.ClassName,
		Children = {},
	}

	-- ScreenGui properties (not a GuiObject)
	if instance:IsA("ScreenGui") then
		local sg = instance :: ScreenGui
		data.DisplayOrder = sg.DisplayOrder
		data.ResetOnSpawn = sg.ResetOnSpawn
		data.ScreenInsets = sg.ScreenInsets.Name
	end

	-- GuiObject: structural + visual properties
	if instance:IsA("GuiObject") then
		local gui = instance :: GuiObject
		data.Size = {
			XScale = gui.Size.X.Scale, XOffset = gui.Size.X.Offset,
			YScale = gui.Size.Y.Scale, YOffset = gui.Size.Y.Offset,
		}
		data.Position = {
			XScale = gui.Position.X.Scale, XOffset = gui.Position.X.Offset,
			YScale = gui.Position.Y.Scale, YOffset = gui.Position.Y.Offset,
		}
		data.Visible = gui.Visible
		if gui.BackgroundTransparency < 1 then
			data.BackgroundColor3 = colorToHex(gui.BackgroundColor3)
		end
		if gui.AnchorPoint.X ~= 0 or gui.AnchorPoint.Y ~= 0 then
			data.AnchorPoint = {X = gui.AnchorPoint.X, Y = gui.AnchorPoint.Y}
		end
		if gui.BackgroundTransparency > 0 then
			data.BackgroundTransparency = gui.BackgroundTransparency
		end
		if gui.AutomaticSize ~= Enum.AutomaticSize.None then
			data.AutomaticSize = gui.AutomaticSize.Name
		end
		if gui.LayoutOrder ~= 0 then
			data.LayoutOrder = gui.LayoutOrder
		end
		if gui.ZIndex ~= 1 then
			data.ZIndex = gui.ZIndex
		end
		if gui.ClipsDescendants then
			data.ClipsDescendants = true
		end
	end

	-- Text elements: content + typography
	if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
		local text = instance :: TextLabel
		data.Text = text.Text
		data.TextColor3 = colorToHex(text.TextColor3)
		data.TextSize = text.TextSize
		data.Font = text.Font.Name
		if text.TextXAlignment ~= Enum.TextXAlignment.Center then
			data.TextXAlignment = text.TextXAlignment.Name
		end
	end

	-- Image elements
	if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
		local img = instance :: ImageLabel
		if img.Image ~= "" then
			data.Image = img.Image
		end
		if img.ImageTransparency > 0 then
			data.ImageTransparency = img.ImageTransparency
		end
		local ic = img.ImageColor3
		if ic.R < 0.99 or ic.G < 0.99 or ic.B < 0.99 then
			data.ImageColor3 = colorToHex(ic)
		end
	end

	-- UI Modifiers
	if instance:IsA("UICorner") then
		local corner = instance :: UICorner
		data.CornerRadius = {Scale = corner.CornerRadius.Scale, Offset = corner.CornerRadius.Offset}
	end

	if instance:IsA("UIStroke") then
		local stroke = instance :: UIStroke
		data.Color = colorToHex(stroke.Color)
		data.Thickness = stroke.Thickness
		if stroke.Transparency > 0 then
			data.Transparency = stroke.Transparency
		end
	end

	if instance:IsA("UIGradient") then
		local grad = instance :: UIGradient
		data.Rotation = grad.Rotation
		local keypoints = {}
		for _, kp in ipairs(grad.Color.Keypoints) do
			table.insert(keypoints, {Time = kp.Time, Color = colorToHex(kp.Value)})
		end
		data.Color = keypoints
	end

	-- Layout modifiers
	if instance:IsA("UIListLayout") then
		local layout = instance :: UIListLayout
		data.FillDirection = layout.FillDirection.Name
		data.SortOrder = layout.SortOrder.Name
		data.Padding = {Scale = layout.Padding.Scale, Offset = layout.Padding.Offset}
		data.HorizontalAlignment = layout.HorizontalAlignment.Name
		data.VerticalAlignment = layout.VerticalAlignment.Name
	end

	if instance:IsA("UIGridLayout") then
		local grid = instance :: UIGridLayout
		data.CellSize = {
			XScale = grid.CellSize.X.Scale, XOffset = grid.CellSize.X.Offset,
			YScale = grid.CellSize.Y.Scale, YOffset = grid.CellSize.Y.Offset,
		}
		data.CellPadding = {
			XScale = grid.CellPadding.X.Scale, XOffset = grid.CellPadding.X.Offset,
			YScale = grid.CellPadding.Y.Scale, YOffset = grid.CellPadding.Y.Offset,
		}
		data.FillDirection = grid.FillDirection.Name
		data.SortOrder = grid.SortOrder.Name
	end

	if instance:IsA("UIPadding") then
		local pad = instance :: UIPadding
		data.PaddingTop = {Scale = pad.PaddingTop.Scale, Offset = pad.PaddingTop.Offset}
		data.PaddingBottom = {Scale = pad.PaddingBottom.Scale, Offset = pad.PaddingBottom.Offset}
		data.PaddingLeft = {Scale = pad.PaddingLeft.Scale, Offset = pad.PaddingLeft.Offset}
		data.PaddingRight = {Scale = pad.PaddingRight.Scale, Offset = pad.PaddingRight.Offset}
	end

	-- Constraints
	if instance:IsA("UIAspectRatioConstraint") then
		data.AspectRatio = (instance :: UIAspectRatioConstraint).AspectRatio
	end

	for _, child in ipairs(instance:GetChildren()) do
		if child:IsA("GuiBase2d") or child:IsA("GuiObject") or child:IsA("UIBase") then
			table.insert(data.Children, serializeUI(child))
		end
	end

	return data
end

function Context.getContext(scope: string?): {[string]: any}
	local s = scope or "all"
	local result: {[string]: any} = {}

	local codeServices = {
		{name = "ServerScriptService", instance = ServerScriptService},
		{name = "ReplicatedStorage", instance = ReplicatedStorage},
		{name = "StarterGui", instance = StarterGui},
		{name = "StarterPlayerScripts", instance = StarterPlayer:FindFirstChild("StarterPlayerScripts")},
		{name = "StarterCharacterScripts", instance = StarterPlayer:FindFirstChild("StarterCharacterScripts")},
	}

	if s == "all" or s == "hierarchy" then
		local hierarchy = {}
		for _, service in ipairs(codeServices) do
			if service.instance then
				local serviceData = {
					Name = service.name,
					ClassName = service.instance.ClassName,
					Path = service.instance:GetFullName(),
					Children = {},
				}

				for _, child in ipairs(service.instance:GetChildren()) do
					local childData = serializeCode(child)
					if childData then
						table.insert(serviceData.Children, childData)
					end
				end

				table.insert(hierarchy, serviceData)
			end
		end
		result.hierarchy = hierarchy
	end

	if s == "all" or s == "scripts" then
		local scripts = {}
		for _, service in ipairs(codeServices) do
			if service.instance then
				for _, desc in ipairs(service.instance:GetDescendants()) do
					if desc:IsA("LuaSourceContainer") then
						table.insert(scripts, {
							Name = desc.Name,
							ClassName = desc.ClassName,
							Path = desc:GetFullName(),
							Enabled = desc:IsA("BaseScript") and (desc :: BaseScript).Enabled or nil,
							Tags = desc:GetTags(),
						})
					end
				end
			end
		end
		result.scripts = scripts
	end

	if s == "all" or s == "ui" then
		local uis = {}
		for _, gui in ipairs(StarterGui:GetChildren()) do
			if gui:IsA("ScreenGui") or gui:IsA("GuiBase2d") then
				table.insert(uis, serializeUI(gui))
			end
		end
		result.uis = uis
	end

	return result
end

return Context
