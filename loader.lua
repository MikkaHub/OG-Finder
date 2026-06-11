---- LEAKED AT https://discord.gg/BAjxpwGQB ----
---- CRYPTIC SOURCES LEAKED THIS JOIN NOW ----

-- casual gave the script and cryptic sources ofc deobfed it --

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ===================== ANTI BAT LOGIC (FIXED) =====================
local antiBatActive = false
local antiBatConn = nil
local antiBatLastSafe = nil

local function startAntiBat()
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	if antiBatConn then antiBatConn:Disconnect() end
	
	antiBatLastSafe = root.Position
	
	antiBatConn = RunService.Heartbeat:Connect(function()
		if not root or not root.Parent then return end
		
		-- Kill rotation fling immediately (silent)
		root.AssemblyAngularVelocity = Vector3.zero
		
		local vel = root.AssemblyLinearVelocity
		local horizSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
		
		-- Detect knockback: horizontal speed > 60 or falling too fast
		if horizSpeed > 60 or vel.Y > 80 or vel.Y < -120 then
			-- Soft counter: zero out external force, keep gravity
			root.AssemblyLinearVelocity = Vector3.new(
				vel.X * 0.15,  -- Dampen X fast but not instant
				math.clamp(vel.Y, -50, 50),  -- Clamp Y (no skyrocketing/falling)
				vel.Z * 0.15   -- Dampen Z fast but not instant
			)
			
			-- Pull back to last safe position gently
			local pull = (antiBatLastSafe - root.Position) * 0.25
			root.AssemblyLinearVelocity += pull
		else
			-- Normal movement, update safe position
			antiBatLastSafe = root.Position
		end
	end)
end

local function stopAntiBat()
	if antiBatConn then 
		antiBatConn:Disconnect() 
		antiBatConn = nil 
	end
	antiBatLastSafe = nil
end

LocalPlayer.CharacterAdded:Connect(function()
	if antiBatActive then stopAntiBat() task.wait(0.2) startAntiBat() end
end)

-- ===================== INF JUMP LOGIC =====================
local infJumpActive = false
local infJumpConn = nil

local function startInfJump()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if infJumpConn then infJumpConn:Disconnect() end
	infJumpConn = UserInputService.JumpRequest:Connect(function()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end)
end

local function stopInfJump()
	if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
end

LocalPlayer.CharacterAdded:Connect(function()
	if infJumpActive then stopInfJump() task.wait(0.2) startInfJump() end
end)

-- ===================== GUI =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IrishAntiBat"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 240, 0, 175)
Main.Position = UDim2.new(0.5, -120, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 13)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 0, 0)
MainStroke.Thickness = 2
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = Main

-- ===== HEADER =====
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 32)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundTransparency = 1
Header.Parent = Main

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(1, -30, 1, 0)
HeaderTitle.Position = UDim2.new(0, 12, 0, 2)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "IRISH ANTI BAT LEAKED BY ONYX & PLASMA"
HeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HeaderTitle.Font = Enum.Font.FredokaOne
HeaderTitle.TextSize = 8
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Parent = Header

-- Green dot
local Dot = Instance.new("Frame")
Dot.Size = UDim2.new(0, 6, 0, 6)
Dot.Position = UDim2.new(1, -16, 0.5, -3)
Dot.BackgroundColor3 = Color3.fromRGB(0, 225, 110)
Dot.BorderSizePixel = 0
Dot.Parent = Header
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

-- ===== TOGGLE ROW FACTORY =====
local function makeRow(parent, yOffset, labelText)
	local Card = Instance.new("Frame")
	Card.Size = UDim2.new(1, -20, 0, 52)
	Card.Position = UDim2.new(0, 10, 0, yOffset)
	Card.BackgroundColor3 = Color3.fromRGB(15, 16, 20)
	Card.BorderSizePixel = 0
	Card.Parent = parent

	local CardCorner = Instance.new("UICorner")
	CardCorner.CornerRadius = UDim.new(0, 10)
	CardCorner.Parent = Card

	-- Greyish outline when off
	local CardStroke = Instance.new("UIStroke")
	CardStroke.Color = Color3.fromRGB(35, 35, 45)
	CardStroke.Thickness = 1.5
	CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	CardStroke.Parent = Card

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0.6, 0, 0, 22)
	Label.Position = UDim2.new(0, 14, 0, 8)
	Label.BackgroundTransparency = 1
	Label.Text = labelText
	Label.TextColor3 = Color3.fromRGB(255, 255, 255)
	Label.Font = Enum.Font.FredokaOne
	Label.TextSize = 14
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Card

	local Status = Instance.new("TextLabel")
	Status.Size = UDim2.new(0.6, 0, 0, 14)
	Status.Position = UDim2.new(0, 14, 0, 28)
	Status.BackgroundTransparency = 1
	Status.Text = "DISABLED"
	Status.TextColor3 = Color3.fromRGB(100, 105, 115)
	Status.Font = Enum.Font.FredokaOne
	Status.TextSize = 10
	Status.TextXAlignment = Enum.TextXAlignment.Left
	Status.Parent = Card

	local PillBg = Instance.new("Frame")
	PillBg.Size = UDim2.new(0, 40, 0, 22)
	PillBg.Position = UDim2.new(1, -54, 0.5, -11)
	PillBg.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
	PillBg.BorderSizePixel = 0
	PillBg.Parent = Card
	Instance.new("UICorner", PillBg).CornerRadius = UDim.new(1, 0)

	local Knob = Instance.new("Frame")
	Knob.Size = UDim2.new(0, 14, 0, 14)
	Knob.Position = UDim2.new(0, 4, 0.5, -7)
	Knob.BackgroundColor3 = Color3.fromRGB(80, 85, 95)
	Knob.BorderSizePixel = 0
	Knob.Parent = PillBg
	Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

	local Btn = Instance.new("TextButton")
	Btn.Size = UDim2.new(1, 0, 1, 0)
	Btn.BackgroundTransparency = 1
	Btn.Text = ""
	Btn.Parent = Card

	return {
		card    = Card,
		stroke  = CardStroke,
		status  = Status,
		pillBg  = PillBg,
		knob    = Knob,
		btn     = Btn,
	}
end

local rowAntiBat = makeRow(Main, 36, "ANTI BAT")
local rowInfJump = makeRow(Main, 96, "INF JUMP")

-- ===== FOOTER =====
local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1, -20, 0, 20)
Footer.Position = UDim2.new(0, 12, 1, -24)
Footer.BackgroundTransparency = 1
Footer.Text = "https://discord.gg/BAjxpwGQB"
Footer.TextColor3 = Color3.fromRGB(140, 145, 155)
Footer.Font = Enum.Font.FredokaOne
Footer.TextSize = 9
Footer.TextXAlignment = Enum.TextXAlignment.Left
Footer.Parent = Main

-- ===== STATE UPDATE CONFIG =====
local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function setRowState(row, rowName, active)
	if active then
		if rowName == "ANTI BAT" then
			-- Anti Bat gets Green Outline and Green Active Text
			TweenService:Create(row.stroke, tweenInfo, {Color = Color3.fromRGB(0, 225, 110)}):Play()
			row.status.Text = "ACTIVE"
			TweenService:Create(row.status, tweenInfo, {TextColor3 = Color3.fromRGB(0, 225, 110)}):Play()
		elseif rowName == "INF JUMP" then
			-- Inf Jump gets Red Outline and Red Active Text
			TweenService:Create(row.stroke, tweenInfo, {Color = Color3.fromRGB(235, 15, 75)}):Play()
			row.status.Text = "ACTIVE"
			TweenService:Create(row.status, tweenInfo, {TextColor3 = Color3.fromRGB(235, 15, 75)}):Play()
		end
		
		TweenService:Create(row.pillBg, tweenInfo, {BackgroundColor3 = Color3.fromRGB(20, 20, 25)}):Play()
		TweenService:Create(row.knob, tweenInfo, {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		TweenService:Create(row.knob, tweenInfo, {Position = UDim2.new(0, 22, 0.5, -7)}):Play()
	else
		-- Back to greyish outline when disabled
		TweenService:Create(row.stroke, tweenInfo, {Color = Color3.fromRGB(35, 35, 45)}):Play()
		row.status.Text = "DISABLED"
		TweenService:Create(row.status, tweenInfo, {TextColor3 = Color3.fromRGB(100, 105, 115)}):Play()
		
		TweenService:Create(row.pillBg, tweenInfo, {BackgroundColor3 = Color3.fromRGB(28, 28, 35)}):Play()
		TweenService:Create(row.knob, tweenInfo, {BackgroundColor3 = Color3.fromRGB(80, 85, 95)}):Play()
		TweenService:Create(row.knob, tweenInfo, {Position = UDim2.new(0, 4, 0.5, -7)}):Play()
	end
end

-- Init
setRowState(rowAntiBat, "ANTI BAT", false)
setRowState(rowInfJump, "INF JUMP", false)

-- ===== BUTTON HOOKS =====
rowAntiBat.btn.MouseButton1Click:Connect(function()
	antiBatActive = not antiBatActive
	setRowState(rowAntiBat, "ANTI BAT", antiBatActive)
	if antiBatActive then startAntiBat() else stopAntiBat() end
end)

rowInfJump.btn.MouseButton1Click:Connect(function()
	infJumpActive = not infJumpActive
	setRowState(rowInfJump, "INF JUMP", infJumpActive)
	if infJumpActive then startInfJump() else stopInfJump() end
end)

-- ===== DRAGGING =====
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

Header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

Header.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		Main.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)
