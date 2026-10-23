-- discord.gg/syncrypt
getgenv()._ = "this script was made by 2zvh. https://2zvh.xyz/"
-- rest of the script below
pcall(setclipboard, "https://discord.gg/xgmxFtCEVt")
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

	if LocalPlayer.PlayerGui:FindFirstChild("2zvhNotify") then LocalPlayer.PlayerGui["2zvhNotify"]:Destroy() end

	if workspace:FindFirstChild("2zvhRange") then workspace["2zvhRange"]:Destroy() end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "2zvhNotify"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = LocalPlayer.PlayerGui
	local Frame = Instance.new("Frame")
	Frame.Name = "Container"
	Frame.AnchorPoint = Vector2.new(1, 1)
	Frame.Size = UDim2.new(0, 280, 1, -40)
	Frame.Position = UDim2.new(1, -20, 1, -20)
	Frame.BackgroundTransparency = 1
	Frame.Parent = ScreenGui
	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0, 8)
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	UIListLayout.Parent = Frame

	local function v21(p5, p6, p7, p8)
		local v22 = p8 or 3.5
		local color3 = p7 or Color3.fromRGB(130, 80, 255)
		local t2 = {}

		for _, child in ipairs(Frame:GetChildren()) do
			if child:IsA("Frame") then t2[#t2 + 1] = child end
		end

		if #t2 >= 4 then t2[1]:Destroy() end

		local Frame2 = Instance.new("Frame")
		Frame2.Size = UDim2.new(0, 280, 0, 0)
		Frame2.BackgroundTransparency = 1
		Frame2.Parent = Frame
		local CanvasGroup = Instance.new("CanvasGroup")
		CanvasGroup.Size = UDim2.new(1, 0, 0, 54)
		CanvasGroup.Position = UDim2.new(1, 300, 0, 0)
		CanvasGroup.GroupTransparency = 1
		CanvasGroup.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
		CanvasGroup.BorderSizePixel = 0
		CanvasGroup.Parent = Frame2
		local UICorner = Instance.new("UICorner")
		UICorner.CornerRadius = UDim.new(0, 8)
		UICorner.Parent = CanvasGroup
		local UIStroke = Instance.new("UIStroke")
		UIStroke.Color = Color3.fromRGB(45, 45, 58)
		UIStroke.Thickness = 1
		UIStroke.Parent = CanvasGroup
		local Frame3 = Instance.new("Frame")
		Frame3.Size = UDim2.new(0, 3, 1, -16)
		Frame3.Position = UDim2.new(0, 8, 0, 8)
		Frame3.BackgroundColor3 = color3
		Frame3.BorderSizePixel = 0
		Frame3.Parent = CanvasGroup
		local UICorner2 = Instance.new("UICorner")
		UICorner2.CornerRadius = UDim.new(1, 0)
		UICorner2.Parent = Frame3
		local TextLabel = Instance.new("TextLabel")
		TextLabel.Size = UDim2.new(1, -32, 0, 14)
		TextLabel.Position = UDim2.new(0, 20, 0, 10)
		TextLabel.BackgroundTransparency = 1
		TextLabel.Text = p5
		TextLabel.TextColor3 = color3
		TextLabel.TextSize = 13
		TextLabel.Font = Enum.Font.GothamBold
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left
		TextLabel.Parent = CanvasGroup
		local TextLabel2 = Instance.new("TextLabel")
		TextLabel2.Size = UDim2.new(1, -32, 0, 13)
		TextLabel2.Position = UDim2.new(0, 20, 0, 27)
		TextLabel2.BackgroundTransparency = 1
		TextLabel2.Text = p6
		TextLabel2.TextColor3 = Color3.fromRGB(175, 175, 190)
		TextLabel2.TextSize = 12
		TextLabel2.Font = Enum.Font.Gotham
		TextLabel2.TextXAlignment = Enum.TextXAlignment.Left
		TextLabel2.Parent = CanvasGroup
		local Frame4 = Instance.new("Frame")
		Frame4.Size = UDim2.new(1, 0, 0, 2)
		Frame4.Position = UDim2.new(0, 0, 1, -2)
		Frame4.BackgroundColor3 = color3
		Frame4.BackgroundTransparency = 0.15
		Frame4.BorderSizePixel = 0
		Frame4.Parent = CanvasGroup
		TweenService:Create(Frame2, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { Size = UDim2.new(0, 280, 0, 54) }):Play()
		TweenService:Create(CanvasGroup, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0 }):Play()
		TweenService:Create(Frame4, TweenInfo.new(v22, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
		task.wait(v22)
		TweenService:Create(CanvasGroup, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Position = UDim2.new(1, 300, 0, 0), GroupTransparency = 1 }):Play()
		task.wait(0.35)
		TweenService:Create(Frame2, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { Size = UDim2.new(0, 280, 0, 0) }):Play()
		task.wait(0.2)
		Frame2:Destroy()
	end

	local visible = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

	local function v37(p9, p10)
		local UICorner = Instance.new("UICorner")
		UICorner.CornerRadius = UDim.new(0, p10)
		UICorner.Parent = p9
	end

	local function v39(p11)
		local UIStroke = Instance.new("UIStroke")
		UIStroke.Color = Color3.fromRGB(45, 45, 58)
		UIStroke.Thickness = 1
		UIStroke.Parent = p11
	end

	local function createTextButton(p12, p13, p14, p15)
		local TextButton = Instance.new("TextButton")
		TextButton.Size = p13
		TextButton.Position = p14
		TextButton.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
		TextButton.Text = p12
		TextButton.TextColor3 = Color3.fromRGB(244, 244, 252)
		TextButton.TextSize = 14
		TextButton.Font = Enum.Font.GothamBold
		TextButton.BorderSizePixel = 0
		TextButton.Parent = p15
		v37(TextButton, 6)
		v39(TextButton)
		return TextButton
	end

	local UIScale = Instance.new("UIScale")
	UIScale.Scale = math.clamp(type(getgenv().uiscale) == "number" and getgenv().uiscale or 1, 0.6, 1.4)
	UIScale.Parent = ScreenGui
	local RunService = game:GetService("RunService")
	local Part = Instance.new("Part")
	Part.Name = "2zvhRange"
	Part.Shape = Enum.PartType.Ball
	Part.Anchored = true
	Part.CanCollide = false
	Part.CanQuery = false
	Part.CanTouch = false
	Part.CastShadow = false
	Part.Material = Enum.Material.ForceField
	Part.Color = Color3.fromRGB(130, 80, 255)
	Part.Transparency = 1
	Part.Parent = workspace

	RunService.RenderStepped:Connect(function()
		if Part.Transparency < 1 then
			local HumanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

			if HumanoidRootPart then
				Part.Size = Vector3.one * (getgenv().hitbox * 2)
				Part.Position = HumanoidRootPart.Position
			end
		end
	end)

	local Frame2 = Instance.new("Frame")
	Frame2.Name = "Panel"
	Frame2.AnchorPoint = Vector2.new(0, 1)
	Frame2.Size = UDim2.new(0, 170, 0, 182)
	Frame2.Position = UDim2.new(0, 20, 1, -66)
	Frame2.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	Frame2.BorderSizePixel = 0
	Frame2.Visible = visible
	Frame2.Parent = ScreenGui
	v37(Frame2, 8)
	v39(Frame2)
	local TextLabel = Instance.new("TextLabel")
	TextLabel.Size = UDim2.new(1, -24, 0, 14)
	TextLabel.Position = UDim2.new(0, 12, 0, 8)
	TextLabel.BackgroundTransparency = 1
	TextLabel.Text = "2zvh"
	TextLabel.TextColor3 = Color3.fromRGB(130, 80, 255)
	TextLabel.TextSize = 13
	TextLabel.Font = Enum.Font.GothamBold
	TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	TextLabel.Parent = Frame2
	local v49 = createTextButton("−", UDim2.new(0, 32, 0, 32), UDim2.new(0, 12, 0, 28), Frame2)
	local v50 = createTextButton("+", UDim2.new(0, 32, 0, 32), UDim2.new(0, 126, 0, 28), Frame2)
	local TextLabel2 = Instance.new("TextLabel")
	TextLabel2.Size = UDim2.new(0, 74, 0, 32)
	TextLabel2.Position = UDim2.new(0, 48, 0, 28)
	TextLabel2.BackgroundTransparency = 1
	TextLabel2.Text = getgenv().hitbox .. " studs"
	TextLabel2.TextColor3 = Color3.fromRGB(244, 244, 252)
	TextLabel2.TextSize = 12
	TextLabel2.Font = Enum.Font.Gotham
	TextLabel2.Parent = Frame2
	local v52 = createTextButton("−", UDim2.new(0, 32, 0, 32), UDim2.new(0, 12, 0, 66), Frame2)
	local v53 = createTextButton("+", UDim2.new(0, 32, 0, 32), UDim2.new(0, 126, 0, 66), Frame2)
	local TextLabel3 = Instance.new("TextLabel")
	TextLabel3.Size = UDim2.new(0, 74, 0, 32)
	TextLabel3.Position = UDim2.new(0, 48, 0, 66)
	TextLabel3.BackgroundTransparency = 1
	TextLabel3.Text = "UI: " .. math.floor(UIScale.Scale * 100 + 0.5) .. "%"
	TextLabel3.TextColor3 = Color3.fromRGB(244, 244, 252)
	TextLabel3.TextSize = 12
	TextLabel3.Font = Enum.Font.Gotham
	TextLabel3.Parent = Frame2
	local v55 = createTextButton("hitbox: ON", UDim2.new(1, -24, 0, 32), UDim2.new(0, 12, 0, 104), Frame2)
	v55.TextColor3 = Color3.fromRGB(70, 230, 140)
	local v56 = createTextButton("range: OFF", UDim2.new(1, -24, 0, 32), UDim2.new(0, 12, 0, 142), Frame2)
	v56.TextColor3 = Color3.fromRGB(255, 80, 100)
	local v57 = createTextButton("≡", UDim2.new(0, 36, 0, 36), UDim2.new(0, 20, 1, -20), ScreenGui)
	v57.AnchorPoint = Vector2.new(0, 1)
	v57.TextSize = 18
	local v58 = createTextButton("made by 2zvh | discord.gg/xgmxFtCEVt", UDim2.new(0, 250, 0, 26), UDim2.new(1, -20, 0, 20), ScreenGui)
	v58.AnchorPoint = Vector2.new(1, 0)
	v58.TextSize = 11
	v58.Font = Enum.Font.Gotham
	v58.TextColor3 = Color3.fromRGB(175, 175, 190)

	v58.MouseButton1Click:Connect(function()
		pcall(setclipboard, "https://discord.gg/xgmxFtCEVt")

		task.spawn(function()
			v21("2zvh", "discord link copied", Color3.fromRGB(70, 230, 140), 2)
		end)
	end)

	local function v59(p16)
		getgenv().hitbox = math.clamp(getgenv().hitbox + p16, 1, 60)
		TextLabel2.Text = getgenv().hitbox .. " studs"

		task.spawn(function()
			v21("2zvh", "hitbox: " .. getgenv().hitbox .. " studs", Color3.fromRGB(130, 80, 255), 2)
		end)
	end

	local function v60()
		u14 = not u14
		v55.Text = u14 and "hitbox: ON" or "hitbox: OFF"
		v55.TextColor3 = u14 and Color3.fromRGB(70, 230, 140) or Color3.fromRGB(255, 80, 100)

		task.spawn(function()
			v21("2zvh", u14 and "hitbox enabled" or "hitbox disabled", u14 and Color3.fromRGB(70, 230, 140) or Color3.fromRGB(255, 80, 100), 3)
		end)
	end

	local function v61(p17)
		UIScale.Scale = math.clamp(UIScale.Scale + p17, 0.6, 1.4)
		getgenv().uiscale = UIScale.Scale
		TextLabel3.Text = "UI: " .. math.floor(UIScale.Scale * 100 + 0.5) .. "%"
	end

	local function v62()
		local v63 = Part.Transparency < 1
		Part.Transparency = v63 and 1 or 0.75
		v56.Text = v63 and "range: OFF" or "range: ON"
		v56.TextColor3 = v63 and Color3.fromRGB(255, 80, 100) or Color3.fromRGB(70, 230, 140)
	end

	v49.MouseButton1Click:Connect(function()
		v59(-5)
	end)

	v50.MouseButton1Click:Connect(function()
		v59(5)
	end)

	v52.MouseButton1Click:Connect(function()
		v61(-0.1)
	end)

	v53.MouseButton1Click:Connect(function()
		v61(0.1)
	end)

	v55.MouseButton1Click:Connect(v60)
	v56.MouseButton1Click:Connect(v62)

	v57.MouseButton1Click:Connect(function()
		Frame2.Visible = not Frame2.Visible
	end)

	local function v64(p18)
		local u65
		local Position
		local Position2

		p18.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				u65 = true
				Position = input.Position
				Position2 = p18.Position

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then u65 = false end
				end)
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if u65 and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local v68 = (input.Position - Position) / UIScale.Scale
				p18.Position = UDim2.new(Position2.X.Scale, Position2.X.Offset + v68.X, Position2.Y.Scale, Position2.Y.Offset + v68.Y)
			end
		end)
	end

	v64(Frame2)
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

	if getgenv()._ ~= "this script was made by 2zvh. https://2zvh.xyz/" then
		LocalPlayer:Kick("Error: Credits were removed from the script.")
		return
	end
	print("Credits are valid, welcome, " .. LocalPlayer.Name .. ".")
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

	task.spawn(function()
		task.wait(5)
		v21("2zvh", "loaded | " .. getgenv().hitbox .. " studs | " .. getgenv().togglekey .. " | -" .. getgenv().reduce .. " +" .. getgenv().increase, Color3.fromRGB(130, 80, 255), 4)
		v21("2zvh", "plz join the discord. https://discord.gg/xgmxFtCEVt", Color3.fromRGB(130, 80, 255), 4)
	end)
else
	print("detected")
end
