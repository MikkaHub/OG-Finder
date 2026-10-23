local t1 = {}

local obj = setmetatable({}, {
	__index = function(p1, p2)
		return p2 == "MS911" and t1 or "detected"
	end, __metatable = "Locked",
	__tostring = function()
		return "pass"
	end,
})

local function v3()
	local v4 = debug.traceback()
	if string.find(v4, "dump") or string.find(v4, "exploit") then return false end
	return true
end

local handlers = {
	function()
		return rawequal(getmetatable(obj), "Locked")
	end,
	function()
		return typeof(tostring(obj)) == "string"
	end,
	function()
		return rawget(obj, "MS911") == nil
	end,
	function()
		return debug.info(v3, "s") ~= "[C]"
	end,
	function()
		return xpcall(function()
			return true
		end, function()
			return false
		end) == true
	end,
	function()
		return not rawget(_G, "shared") or typeof(_G.shared) == "table"
	end,
	function()
		return not rawget(getfenv(), "getrenv") and not rawget(getfenv(), "getscenv")
	end,
	function()
		return obj.MS911 == t1
	end,
	function()
		return v3()
	end,
	function()
		return pcall(function()
			return obj.UnknownKey
		end)
	end,
}

local ok, result = pcall(function()
	for i = 1, #handlers do
		if handlers[i]() then continue end
		return "detected"
	end

	return "pass"
end)

if ok and result == "pass" then
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CollectionService = game:GetService("CollectionService")
	local UserInputService = game:GetService("UserInputService")
	local LocalPlayer = Players.LocalPlayer
	local u14 = true
	local u15 = false

	if type(getgenv().hitbox) ~= "number" then getgenv().hitbox = 30 end

	getgenv().hitbox = math.clamp(getgenv().hitbox, 1, 60)

	local function v16(p3, p4)
		if type(p3) == "string" and pcall(function()
			return Enum.KeyCode[p3]
		end) then
			return p3
		end
		return p4
	end

	getgenv().togglekey = v16(getgenv().togglekey, "T")
	getgenv().reduce = v16(getgenv().reduce, "Q")
	getgenv().increase = v16(getgenv().increase, "E")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild("ControlDashboard")
	if old then old:Destroy() end
	local oldRange = workspace:FindFirstChild("InteractionRange")
	if oldRange then oldRange:Destroy() end

	local colors = {
		background = Color3.fromRGB(16, 23, 33),
		card = Color3.fromRGB(25, 35, 48),
		border = Color3.fromRGB(45, 60, 77),
		text = Color3.fromRGB(237, 244, 250),
		muted = Color3.fromRGB(151, 171, 191),
		accent = Color3.fromRGB(72, 219, 191),
	}
	local function make(class, properties, parent)
		local item = Instance.new(class)
		for key, value in pairs(properties) do item[key] = value end
		item.Parent = parent
		return item
	end
	local function round(item, radius)
		make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, item)
	end
	local function label(parent, text, x, y, w, h, size, color)
		return make("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(w, h), Text = text,
			TextColor3 = color or colors.text, TextSize = size or 14,
			Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
		}, parent)
	end
	local function button(parent, text, x, y, w, h)
		local b = make("TextButton", {
			Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
			BackgroundColor3 = colors.border, BorderSizePixel = 0,
			Text = text, TextColor3 = colors.text, TextSize = 14,
			Font = Enum.Font.GothamBold, AutoButtonColor = true,
		}, parent)
		round(b, 10)
		return b
	end
	local ScreenGui = make("ScreenGui", {
		Name = "ControlDashboard", ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)
	local panel = make("Frame", {
		Name = "Dashboard", Size = UDim2.fromOffset(360, 470),
		Position = UDim2.fromOffset(24, 70),
		BackgroundColor3 = colors.background, BorderSizePixel = 0,
	}, ScreenGui)
	round(panel, 18)
	make("UIStroke", {Color = colors.border, Thickness = 1}, panel)
	local scale = make("UIScale", {Scale = 1}, panel)
	local requestedScale = math.clamp(type(getgenv().uiscale) == "number" and getgenv().uiscale or 1, 0.6, 1.4)
	local header = make("Frame", {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(292, 72), Active = true,
	}, panel)
	local title = label(header, "CONTROL CENTER", 20, 18, 260, 24, 20)
	title.Font = Enum.Font.GothamBold
	label(header, "Interaction & display", 20, 44, 260, 18, 12, colors.muted)
	local minimize = button(panel, "—", 300, 18, 40, 40)
	local tabs = {
		button(panel, "Controls", 20, 82, 156, 40),
		button(panel, "Appearance", 184, 82, 156, 40),
	}
	local pages = {}
	for i = 1, 2 do
		pages[i] = make("Frame", {
			Size = UDim2.fromOffset(320, 280), Position = UDim2.fromOffset(20, 138),
			BackgroundTransparency = 1, Visible = i == 1,
		}, panel)
	end
	local function card(parent, y, height)
		local f = make("Frame", {
			Size = UDim2.fromOffset(320, height), Position = UDim2.fromOffset(0, y),
			BackgroundColor3 = colors.card, BorderSizePixel = 0,
		}, parent)
		round(f)
		return f
	end
	local radiusCard = card(pages[1], 0, 130)
	label(radiusCard, "INTERACTION RADIUS", 16, 12, 280, 20, 11, colors.muted)
	local radiusValue = label(radiusCard, "", 72, 40, 176, 42, 28)
	radiusValue.Font = Enum.Font.GothamBold
	radiusValue.TextXAlignment = Enum.TextXAlignment.Center
	local minus = button(radiusCard, "−", 16, 42, 44, 44)
	local plus = button(radiusCard, "+", 260, 42, 44, 44)
	local track = make("Frame", {
		Position = UDim2.fromOffset(16, 105), Size = UDim2.fromOffset(288, 5),
		BackgroundColor3 = colors.border, BorderSizePixel = 0,
	}, radiusCard)
	round(track)
	local fill = make("Frame", {
		Size = UDim2.fromScale(0.5, 1), BackgroundColor3 = colors.accent, BorderSizePixel = 0,
	}, track)
	round(fill)
	local interactionCard = card(pages[1], 142, 62)
	label(interactionCard, "Hitbox", 16, 10, 190, 20, 15)
	label(interactionCard, "Enable interaction adjustment", 16, 32, 210, 16, 10, colors.muted)
	local toggle = button(interactionCard, "", 238, 9, 66, 44)
	local rangeCard = card(pages[1], 216, 62)
	label(rangeCard, "Range preview", 16, 10, 190, 20, 15)
	label(rangeCard, "Show the radius around you", 16, 32, 210, 16, 10, colors.muted)
	local rangeToggle = button(rangeCard, "", 238, 9, 66, 44)
	local scaleCard = card(pages[2], 0, 116)
	label(scaleCard, "INTERFACE SCALE", 16, 12, 280, 20, 11, colors.muted)
	local scaleMinus = button(scaleCard, "−", 16, 48, 44, 44)
	local scalePlus = button(scaleCard, "+", 260, 48, 44, 44)
	local scaleValue = label(scaleCard, "", 70, 48, 180, 44, 24)
	scaleValue.TextXAlignment = Enum.TextXAlignment.Center
	local shortcuts = card(pages[2], 128, 150)
	label(shortcuts, "KEYBOARD SHORTCUTS", 16, 12, 280, 20, 11, colors.muted)
	label(shortcuts, getgenv().togglekey .. "   Toggle hitbox", 16, 44, 288, 22, 14)
	label(shortcuts, getgenv().reduce .. "   Decrease radius", 16, 76, 288, 22, 14)
	label(shortcuts, getgenv().increase .. "   Increase radius", 16, 108, 288, 22, 14)
	local status = label(panel, "Ready", 20, 432, 320, 20, 11, colors.muted)
	local launcher = button(ScreenGui, "Controls", 16, 16, 100, 42)
	launcher.Visible = false
	local function setOpen(open)
		panel.Visible = open
		launcher.Visible = not open
	end
	minimize.Activated:Connect(function() setOpen(false) end)
	launcher.Activated:Connect(function() setOpen(true) end)
	local function selectTab(index)
		for i, tab in ipairs(tabs) do
			pages[i].Visible = i == index
			tab.BackgroundColor3 = i == index and colors.accent or colors.card
			tab.TextColor3 = i == index and colors.background or colors.muted
		end
	end
	tabs[1].Activated:Connect(function() selectTab(1) end)
	tabs[2].Activated:Connect(function() selectTab(2) end)
	selectTab(1)

	local Part = make("Part", {
		Name = "InteractionRange", Shape = Enum.PartType.Ball, Anchored = true,
		CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
		Material = Enum.Material.ForceField, Color = colors.accent, Transparency = 1,
	}, workspace)
	local renderConnection = RunService.RenderStepped:Connect(function()
		if Part.Transparency < 1 then
			local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if root then
				Part.Size = Vector3.one * (getgenv().hitbox * 2)
				Part.Position = root.Position
			end
		end
	end)
	local function switchState(b, on)
		b.Text = on and "ON" or "OFF"
		b.BackgroundColor3 = on and colors.accent or colors.border
		b.TextColor3 = on and colors.background or colors.muted
	end
	local function refresh()
		radiusValue.Text = tostring(getgenv().hitbox) .. " studs"
		fill.Size = UDim2.fromScale((getgenv().hitbox - 1) / 59, 1)
		switchState(toggle, u14)
		switchState(rangeToggle, Part.Transparency < 1)
	end
	local function fit()
		local viewport = ScreenGui.AbsoluteSize
		scale.Scale = math.min(requestedScale, math.max(0.1, (viewport.X - 24) / 360), math.max(0.1, (viewport.Y - 24) / 470))
		local x = math.clamp(panel.Position.X.Offset, 12, math.max(12, viewport.X - 360 * scale.Scale - 12))
		local y = math.clamp(panel.Position.Y.Offset, 12, math.max(12, viewport.Y - 470 * scale.Scale - 12))
		panel.Position = UDim2.fromOffset(x, y)
		scaleValue.Text = math.floor(scale.Scale * 100 + 0.5) .. "%"
	end
	local function v59(delta)
		getgenv().hitbox = math.clamp(getgenv().hitbox + delta, 1, 60)
		refresh()
		status.Text = "Radius updated · " .. getgenv().hitbox .. " studs"
	end
	local function v60()
		u14 = not u14
		refresh()
		status.Text = u14 and "Hitbox enabled" or "Hitbox disabled"
	end
	local function changeScale(delta)
		requestedScale = math.clamp(requestedScale + delta, 0.6, 1.4)
		getgenv().uiscale = requestedScale
		fit()
	end
	minus.Activated:Connect(function() v59(-5) end)
	plus.Activated:Connect(function() v59(5) end)
	toggle.Activated:Connect(v60)
	rangeToggle.Activated:Connect(function()
		Part.Transparency = Part.Transparency < 1 and 1 or 0.75
		refresh()
	end)
	scaleMinus.Activated:Connect(function() changeScale(-0.1) end)
	scalePlus.Activated:Connect(function() changeScale(0.1) end)
	local dragInput, dragStart, panelStart
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragInput, dragStart, panelStart = input, input.Position, panel.Position
		end
	end)
	local dragConnection = UserInputService.InputChanged:Connect(function(input)
		if not dragInput then return end
		if input == dragInput or (dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
			local delta = input.Position - dragStart
			panel.Position = UDim2.fromOffset(panelStart.X.Offset + delta.X, panelStart.Y.Offset + delta.Y)
			fit()
		end
	end)
	local endConnection = UserInputService.InputEnded:Connect(function(input)
		if input == dragInput then dragInput = nil end
	end)
	ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	ScreenGui.Destroying:Connect(function()
		renderConnection:Disconnect()
		dragConnection:Disconnect()
		endConnection:Disconnect()
		Part:Destroy()
	end)
	refresh()
	task.defer(fit)
	local Physics = require(ReplicatedStorage.Common.Physics)
	local canInteract = Physics.canInteract

	Physics.canInteract = function(p19, p20, p21)
		if not u14 then return canInteract(p19, p20, p21) end

		if not p19 or not p19.Parent or not p19.Character or not p19.Character.Parent then return false end

		if not Physics.isPointOnTeamSide(p19, p21, p20) then return false end

		if getgenv().hitbox <= p19:DistanceFromCharacter(p21) then return false end
		local Gamemode = require(ReplicatedStorage.Configuration.Gamemode)
		local v72 = require(ReplicatedStorage.Configuration.Place)()
		local Game = require(ReplicatedStorage.Configuration.Game)
		if Gamemode.Current() == Gamemode.Types.Training or v72.Current == v72.Seasonal then return true end

		if p19.Team and ReplicatedStorage:GetAttribute("LastHitTeam") == p19.Team.Name then
			local v74 = (ReplicatedStorage:GetAttribute("LastHitTimestamp") or 0) + Game.Ball.Debounce

			if workspace:GetServerTimeNow() < v74 then
				if (p21 - (ReplicatedStorage:GetAttribute("LastHitPosition") or Vector3.new())).Magnitude < Game.Ball.DebounceDistance then
					return false
				end
			end
		end

		local attribute = ReplicatedStorage:GetAttribute("ServedByTeam")
		if attribute and (p20 == "Block" or p20 == "Spike" or p19.Team and p19.Team.Name == attribute) then
			return false
		end
		return true
	end

	local tagged = CollectionService:GetTagged("Ball")

	CollectionService:GetInstanceAddedSignal("Ball"):Connect(function(p22)
		tagged[#tagged + 1] = p22
	end)

	CollectionService:GetInstanceRemovedSignal("Ball"):Connect(function(p23)
		for i = #tagged, 1, -1 do
			if tagged[i] == p23 then table.remove(tagged, i) end
		end
	end)

	local v78

	v78 = hookmetamethod(game, "__namecall", newcclosure(function(p24, ...)
		if u15 then return v78(p24, ...) end

		if not (getnamecallmethod() == "GetPartsInPart" and p24 == workspace and u14) then return v78(p24, ...) end
		u15 = true
		local t3 = { v78(p24, ...) }
		local v80 = t3[1] or {}
		if type(v80) == "table" and #v80 > 0 then
			u15 = false
			return unpack(t3)
		end
		local v81 = ({ ... })[1]

		if v81 and typeof(v81) == "Instance" and v81:IsA("BasePart") then
			for _, v in ipairs(tagged) do
				if typeof(v) == "Instance" and v:IsA("Model") and v.PrimaryPart and (v.PrimaryPart.Position - v81.Position).Magnitude <= getgenv().hitbox then
					v80[#v80 + 1] = v.PrimaryPart
					u15 = false
					return v80
				end
			end
		end

		u15 = false
		return v80
	end))

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode[getgenv().togglekey] then
			v60()
		elseif input.KeyCode == Enum.KeyCode[getgenv().increase] then
			v59(5)
		elseif input.KeyCode == Enum.KeyCode[getgenv().reduce] then
			v59(-5)
		end
	end)

else
	print("detected")
end

