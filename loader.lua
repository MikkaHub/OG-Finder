local Players = game:GetService("Players")
local player = Players.LocalPlayer

if type(setfflag) ~= "function" then
    player:Kick("Your Executer Does Not Support This Script! [ ROOSY HUB ]")
    return
end

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local pos1 = Vector3.new(-352.98, -7, 74.30)
local pos2 = Vector3.new(-352.98, -6.49, 45.76)
local standing1 = Vector3.new(-336.36, -4.59, 99.51)
local standing2 = Vector3.new(-334.81, -4.59, 18.90)

local spot1_sequence = {
    CFrame.new(-370.810913, -7.00000334, 41.2687263, 0.99984771, 1.22364419e-09, 0.0174523517, -6.54859778e-10, 1, -3.2596418e-08, -0.0174523517, 3.25800258e-08, 0.99984771),
    CFrame.new(-336.355286, -5.10107088, 17.2327671, -0.999883354, -2.76150569e-08, 0.0152716246, -2.88224964e-08, 1, -7.88441525e-08, -0.0152716246, -7.9275118e-08, -0.999883354)
}
local spot2_sequence = {
    CFrame.new(-354.782867, -7.00000334, 92.8209305, -0.999997616, -1.11891862e-09, -0.00218066527, -1.11958298e-09, 1, 3.03415071e-10, 0.00218066527, 3.05855785e-10, -0.999997616),
    CFrame.new(-336.942902, -5.10106993, 99.3276443, 0.999914348, -3.63984611e-08, 0.0130875716, 3.67094941e-08, 1, -2.35254749e-08, -0.0130875716, 2.40038975e-08, 0.999914348)
}

local ConfigName = "RoosyHalfTP_Config.json"
local Config = {
    FrameXScale = 0, FrameXOffset = 30, FrameYScale = 0, FrameYOffset = 137,
    LeftKey = "None", RightKey = "None", ShowESP = true,
    HalfTp = false, AutoPotion = false, InstantGrab = false
}

local function LoadConfig()
    if readfile then
        local success, data = pcall(readfile, ConfigName)
        if success and type(data) == "string" and data ~= "" then
            local decodeSuccess, decoded = pcall(HttpService.JSONDecode, HttpService, data)
            if decodeSuccess and type(decoded) == "table" then
                for k, v in pairs(decoded) do
                    Config[k] = v
                end
            end
        end
    end
end

local function SaveConfig()
    if writefile then
        pcall(function()
            writefile(ConfigName, HttpService:JSONEncode(Config))
        end)
    end
end

LoadConfig()

if CoreGui:FindFirstChild("RoosyHalfTP") then
    CoreGui.RoosyHalfTP:Destroy()
end
if CoreGui:FindFirstChild("HexSemiTPGui") then
    CoreGui.HexSemiTPGui:Destroy()
end
if CoreGui:FindFirstChild("DawoodSemiTPGui") then
    CoreGui.DawoodSemiTPGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RoosyHalfTP"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

local ESPElements = {}

local function createESPBox(transform, labelText, customSize)
    local espFolder = Instance.new("Folder")
    espFolder.Name = "ESPBox_" .. labelText
    espFolder.Parent = workspace
    
    local box = Instance.new("Part")
    box.Size = customSize or Vector3.new(5, 0.5, 5)
    
    if typeof(transform) == "CFrame" then
        box.CFrame = transform
    else
        box.Position = transform
    end
    
    box.Anchored = true
    box.CanCollide = false
    box.Transparency = Config.ShowESP and 0.5 or 1
    box.Material = Enum.Material.Neon
    box.Color = Color3.fromRGB(100, 60, 180)
    box.Parent = espFolder
    
    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Adornee = box
    selectionBox.LineThickness = 0.05
    selectionBox.Color3 = Color3.fromRGB(100, 60, 180)
    selectionBox.Visible = Config.ShowESP
    selectionBox.Parent = box
    
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = box
    billboard.Size = UDim2.new(4, 0, 1, 0)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = Config.ShowESP
    billboard.Parent = box

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    frame.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Parent = frame

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 90, 90)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    grad.Rotation = 0
    grad.Parent = stroke

    task.spawn(function()
        while task.wait() do
            if not grad.Parent then break end
            grad.Rotation = (grad.Rotation + 1.2) % 360
        end
    end)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -10, 1, -10)
    textLabel.Position = UDim2.new(0, 5, 0, 5)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = labelText
    textLabel.TextColor3 = Color3.new(0.6, 0.8, 1)
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextScaled = true
    textLabel.Parent = frame

    table.insert(ESPElements, {box = box, sbox = selectionBox, billboard = billboard})

    return espFolder
end

createESPBox(standing1, "Standing 1")
createESPBox(standing2, "Standing 2")

local autoTpLeftCFrame = CFrame.new(-352.747192, -7.02221918, 72.5176468, 0.999999523, -7.71221309e-08, 0.00096146093, 7.72208466e-08, 1, -1.02638907e-07, -0.00096146093, 1.02713109e-07, 0.999999523) * CFrame.Angles(0, math.rad(90), 0)
createESPBox(autoTpLeftCFrame, "Auto tp Left", Vector3.new(1, 0.2, 8))

local autoTpRightCFrame = CFrame.new(-353.125275, -7.02221918, 47.1294556, -0.999999881, 6.90323034e-08, -0.000438153715, 6.90570872e-08, 1, -5.6546785e-08, 0.000438153715, -5.65770364e-08, -0.999999881) * CFrame.Angles(0, math.rad(90), 0)
createESPBox(autoTpRightCFrame, "Auto tp Right", Vector3.new(1, 0.2, 8))

local Frame = Instance.new("Frame")
Frame.BackgroundTransparency = 0.4
Frame.Position = UDim2.new(Config.FrameXScale, Config.FrameXOffset, Config.FrameYScale, Config.FrameYOffset)
Frame.ClipsDescendants = true
Frame.Active = true
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Frame

local UIStroke = Instance.new("UIStroke")
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Thickness = 2
UIStroke.Color = Color3.new(1, 1, 1)
UIStroke.Parent = Frame

local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 90, 90)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
Gradient.Rotation = 0
Gradient.Parent = UIStroke

task.spawn(function()
    local speed = 0.8
    while task.wait() do
        if not Gradient.Parent then break end
        Gradient.Rotation = (Gradient.Rotation + speed) % 360
    end
end)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 10, 0, 8)
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.Text = "Half-TP"
TitleLabel.TextSize = 18
TitleLabel.Size = UDim2.new(1, -40, 0, 24)
TitleLabel.Parent = Frame

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 90, 90)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
TitleGradient.Rotation = 0
TitleGradient.Parent = TitleLabel

task.spawn(function()
    local speed = 1.2
    while task.wait() do
        if not TitleGradient.Parent then break end
        TitleGradient.Rotation = (TitleGradient.Rotation + speed) % 360
    end
end)

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Font = Enum.Font.GothamBlack
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
MinimizeBtn.Position = UDim2.new(1, -32, 0, 8)
MinimizeBtn.TextColor3 = Color3.new(1, 1, 1)
MinimizeBtn.Text = "-"
MinimizeBtn.TextSize = 14
MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
MinimizeBtn.Parent = Frame

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeBtn

local MinStroke = Instance.new("UIStroke")
MinStroke.Thickness = 2
MinStroke.Color = Color3.fromRGB(255, 255, 255)
MinStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MinStroke.Parent = MinimizeBtn

local function createGradientStroke(parent)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Parent = parent
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 90, 90)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    grad.Rotation = 0
    grad.Parent = stroke
    task.spawn(function()
        while task.wait() do
            if not grad.Parent then break end
            grad.Rotation = (grad.Rotation + 1.2) % 360
        end
    end)
    return stroke
end

local currentYOffset = 48

local function CreateToggle(text, configKey, defaultState, callback)
    if Config[configKey] == nil then
        Config[configKey] = defaultState
    end
    local state = Config[configKey]

    local ToggleRow = Instance.new("Frame")
    ToggleRow.Position = UDim2.new(0, 10, 0, currentYOffset)
    ToggleRow.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    ToggleRow.Size = UDim2.new(1, -20, 0, 34)
    ToggleRow.Parent = Frame
    createGradientStroke(ToggleRow)

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.Parent = ToggleRow

    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.TextColor3 = Color3.new(1, 1, 1)
    ToggleLabel.Font = Enum.Font.GothamBlack
    ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
    ToggleLabel.Text = text
    ToggleLabel.TextSize = 13
    ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
    ToggleLabel.Parent = ToggleRow

    local SwitchBg = Instance.new("Frame")
    SwitchBg.BackgroundTransparency = 1
    SwitchBg.Position = UDim2.new(1, -46, 0.5, -9)
    SwitchBg.Size = UDim2.new(0, 36, 0, 18)
    SwitchBg.Parent = ToggleRow

    local SwitchBgCorner = Instance.new("UICorner")
    SwitchBgCorner.CornerRadius = UDim.new(0, 9)
    SwitchBgCorner.Parent = SwitchBg

    local SwitchBgStroke = Instance.new("UIStroke")
    SwitchBgStroke.Thickness = 2
    SwitchBgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    SwitchBgStroke.Color = Color3.new(1, 1, 1)
    SwitchBgStroke.Parent = SwitchBg

    local SwitchKnob = Instance.new("Frame")
    SwitchKnob.BackgroundColor3 = Color3.new(1, 1, 1)
    SwitchKnob.Size = UDim2.new(0, 14, 0, 14)
    SwitchKnob.Parent = SwitchBg

    local SwitchKnobCorner = Instance.new("UICorner")
    SwitchKnobCorner.CornerRadius = UDim.new(0, 7)
    SwitchKnobCorner.Parent = SwitchKnob

    local goal = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    local color = state and Color3.fromRGB(100, 60, 200) or Color3.fromRGB(45, 45, 65)
    SwitchKnob.Position = goal
    SwitchBg.BackgroundColor3 = color

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Text = ""
    ToggleBtn.BackgroundTransparency = 1
    ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
    ToggleBtn.Parent = ToggleRow

    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        Config[configKey] = state
        SaveConfig()
        
        goal = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        color = state and Color3.fromRGB(100, 60, 200) or Color3.fromRGB(45, 45, 65)
        TweenService:Create(SwitchKnob, TweenInfo.new(0.15), {Position = goal}):Play()
        TweenService:Create(SwitchBg, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
        if callback then callback(state) end
    end)
    
    task.spawn(function()
        if callback then callback(state) end
    end)

    currentYOffset = currentYOffset + 40
end

local function CreateButton(text, callback)
    local ButtonRow = Instance.new("TextButton")
    ButtonRow.Position = UDim2.new(0, 10, 0, currentYOffset)
    ButtonRow.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    ButtonRow.Size = UDim2.new(1, -20, 0, 34)
    ButtonRow.Text = text
    ButtonRow.TextColor3 = Color3.new(1, 1, 1)
    ButtonRow.Font = Enum.Font.GothamBlack
    ButtonRow.TextSize = 13
    ButtonRow.Parent = Frame
    createGradientStroke(ButtonRow)

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.Parent = ButtonRow

    ButtonRow.MouseButton1Click:Connect(callback)

    currentYOffset = currentYOffset + 40
end

local function CreateButtonWithKeybind(text, configKey, callback)
    local Row = Instance.new("Frame")
    Row.Position = UDim2.new(0, 10, 0, currentYOffset)
    Row.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Row.Size = UDim2.new(1, -20, 0, 34)
    Row.Parent = Frame
    createGradientStroke(Row)

    local RowCorner = Instance.new("UICorner")
    RowCorner.Parent = Row

    local Btn = Instance.new("TextButton")
    Btn.BackgroundTransparency = 1
    Btn.Size = UDim2.new(1, -70, 1, 0)
    Btn.Text = text
    Btn.TextColor3 = Color3.new(1, 1, 1)
    Btn.Font = Enum.Font.GothamBlack
    Btn.TextSize = 13
    Btn.Parent = Row
    Btn.MouseButton1Click:Connect(callback)

    local boundKey = nil
    pcall(function()
        if Config[configKey] and Config[configKey] ~= "None" then
            boundKey = Enum.KeyCode[Config[configKey]]
        end
    end)

    local KeybindBtn = Instance.new("TextButton")
    local keyName = boundKey and boundKey.Name or "--"
    KeybindBtn.Text = "[" .. keyName .. "]"
    KeybindBtn.AutoButtonColor = false
    KeybindBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    KeybindBtn.Position = UDim2.new(1, -65, 0.5, -11)
    KeybindBtn.Size = UDim2.new(0, 60, 0, 22)
    KeybindBtn.TextColor3 = Color3.new(1, 1, 1)
    KeybindBtn.Font = Enum.Font.GothamBlack
    KeybindBtn.TextScaled = true
    KeybindBtn.Parent = Row

    local constraint = Instance.new("UITextSizeConstraint")
    constraint.MaxTextSize = 10
    constraint.Parent = KeybindBtn

    local KeyCorner = Instance.new("UICorner")
    KeyCorner.CornerRadius = UDim.new(0, 5)
    KeyCorner.Parent = KeybindBtn

    local listening = false

    KeybindBtn.MouseButton1Click:Connect(function()
        listening = true
        KeybindBtn.Text = "[...]"
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                boundKey = input.KeyCode
                Config[configKey] = boundKey.Name
                SaveConfig()
                KeybindBtn.Text = "[" .. boundKey.Name .. "]"
                listening = false
            end
        elseif not gpe and boundKey and input.KeyCode == boundKey then
            if not UserInputService:GetFocusedTextBox() then
                callback()
            end
        end
    end)

    currentYOffset = currentYOffset + 40
end

local function CreateStatus(defaultText)
    local StatusRow = Instance.new("Frame")
    StatusRow.Position = UDim2.new(0, 10, 0, currentYOffset)
    StatusRow.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    StatusRow.Size = UDim2.new(1, -20, 0, 34)
    StatusRow.Parent = Frame
    createGradientStroke(StatusRow)

    local StatusCorner = Instance.new("UICorner")
    StatusCorner.Parent = StatusRow

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.new(0.6, 0.8, 1)
    StatusLabel.Font = Enum.Font.GothamMedium
    StatusLabel.Size = UDim2.new(1, 0, 1, 0)
    StatusLabel.Text = defaultText
    StatusLabel.TextSize = 13
    StatusLabel.Parent = StatusRow

    currentYOffset = currentYOffset + 40
    return StatusLabel
end

local dragging = false
local dragStart = nil
local startPos = nil
local minimized = false

local function clampPosition(pos)
    local screenSize = workspace.CurrentCamera.ViewportSize
    local guiSize = Frame.AbsoluteSize
    local maxX = screenSize.X - guiSize.X
    local maxY = screenSize.Y - guiSize.Y
    local x = math.clamp(pos.X.Offset, 0, math.max(0, maxX))
    local y = math.clamp(pos.Y.Offset, 0, math.max(0, maxY))
    return UDim2.new(0, x, 0, y)
end

Frame.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        Frame.Position = clampPosition(newPos)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            dragging = false
            Config.FrameXScale = Frame.Position.X.Scale
            Config.FrameXOffset = Frame.Position.X.Offset
            Config.FrameYScale = Frame.Position.Y.Scale
            Config.FrameYOffset = Frame.Position.Y.Offset
            SaveConfig()
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.RightShift then
        if not UserInputService:GetFocusedTextBox() then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end
end)

local allAnimalsCache = {}
local PromptMemoryCache = {}
local InternalStealCache = {}
local AUTO_STEAL_PROX_RADIUS = 200

local IsStealing = false
local StealProgress = 0
local CurrentStealTarget = nil

local semiTPEnabled = false
_G.AutoPotion = false

local function getHRP()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
end

CreateToggle("Show ESP", "ShowESP", true, function(state)
    for _, esp in ipairs(ESPElements) do
        if esp.box and esp.box.Parent then
            esp.box.Transparency = state and 0.5 or 1
            esp.sbox.Visible = state
            esp.billboard.Enabled = state
        end
    end
end)

CreateToggle("Half Tp", "HalfTp", false, function(s) semiTPEnabled = s end)
CreateToggle("Instant Grab", "InstantGrab", false, function(s) Config.InstantGrab = s end)
CreateToggle("Auto Potion", "AutoPotion", false, function(s) _G.AutoPotion = s end)

local function ResetToWork()
    local flags = {
        {"GameNetPVHeaderRotationalVelocityZeroCutoffExponent", "-5000"},
        {"LargeReplicatorWrite5", "true"}, {"LargeReplicatorEnabled9", "true"},
        {"AngularVelociryLimit", "360"}, {"TimestepArbiterVelocityCriteriaThresholdTwoDt", "2147483646"},
        {"S2PhysicsSenderRate", "15000"}, {"DisableDPIScale", "true"},
        {"MaxDataPacketPerSend", "2147483647"}, {"ServerMaxBandwith", "52"},
        {"PhysicsSenderMaxBandwidthBps", "20000"}, {"MaxTimestepMultiplierBuoyancy", "2147483647"},
        {"SimOwnedNOUCountThresholdMillionth", "2147483647"}, {"MaxMissedWorldStepsRemembered", "-2147483648"},
        {"CheckPVDifferencesForInterpolationMinVelThresholdStudsPerSecHundredth", "1"},
        {"StreamJobNOUVolumeLengthCap", "2147483647"}, {"DebugSendDistInSteps", "-2147483648"},
        {"MaxTimestepMultiplierAcceleration", "2147483647"}, {"LargeReplicatorRead5", "true"},
        {"SimExplicitlyCappedTimestepMultiplier", "2147483646"}, {"GameNetDontSendRedundantNumTimes", "1"},
        {"CheckPVLinearVelocityIntegrateVsDeltaPositionThresholdPercent", "1"},
        {"CheckPVCachedRotVelThresholdPercent", "10"}, {"LargeReplicatorSerializeRead3", "true"},
        {"ReplicationFocusNouExtentsSizeCutoffForPauseStuds", "2147483647"},
        {"NextGenReplicatorEnabledWrite4", "true"},
        {"CheckPVDifferencesForInterpolationMinRotVelThresholdRadsPerSecHundredth", "1"},
        {"GameNetDontSendRedundantDeltaPositionMillionth", "1"},
        {"InterpolationFrameVelocityThresholdMillionth", "5"},
        {"StreamJobNOUVolumeCap", "2147483647"}, {"InterpolationFrameRotVelocityThresholdMillionth", "5"},
        {"WorldStepMax", "30"}, {"TimestepArbiterHumanoidLinearVelThreshold", "1"},
        {"InterpolationFramePositionThresholdMillionth", "5"},
        {"TimestepArbiterHumanoidTurningVelThreshold", "1"},
        {"MaxTimestepMultiplierContstraint", "2147483647"},
        {"GameNetPVHeaderLinearVelocityZeroCutoffExponent", "-5000"},
        {"CheckPVCachedVelThresholdPercent", "10"}, {"TimestepArbiterOmegaThou", "1073741823"},
        {"MaxAcceptableUpdateDelay", "1"}, {"LargeReplicatorSerializeWrite4", "true"},
    }
    for _, data in ipairs(flags) do
        pcall(function() if setfflag then setfflag(data[1], data[2]) end end)
    end
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Dead) end
        char:ClearAllChildren()
        local f = Instance.new("Model", workspace)
        player.Character = f task.wait()
        player.Character = char f:Destroy()
    end
end

local function isMyBase(plotName)
    local plot = workspace.Plots:FindFirstChild(plotName)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    return sign and sign:FindFirstChild("YourBase") and sign.YourBase.Enabled
end

local function scanSinglePlot(plot)
    if not plot or not plot:IsA("Model") or isMyBase(plot.Name) then return end
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return end
    for _, podium in ipairs(podiums:GetChildren()) do
        if podium:IsA("Model") and podium:FindFirstChild("Base") then
            table.insert(allAnimalsCache, {
                plot = plot.Name, slot = podium.Name,
                worldPosition = podium:GetPivot().Position,
                uid = plot.Name .. "_" .. podium.Name,
            })
        end
    end
end

local function initializeScanner()
    task.wait(2)
    local plots = workspace:WaitForChild("Plots", 10)
    for _, plot in ipairs(plots:GetChildren()) do scanSinglePlot(plot) end
    plots.ChildAdded:Connect(scanSinglePlot)
    task.spawn(function()
        while task.wait(3) do
            table.clear(allAnimalsCache)
            for _, plot in ipairs(plots:GetChildren()) do scanSinglePlot(plot) end
        end
    end)
end

local function findPrompt(animal)
    local cached = PromptMemoryCache[animal.uid]
    if cached and cached.Parent then return cached end
    local plot = workspace.Plots:FindFirstChild(animal.plot)
    local podium = plot and plot.AnimalPodiums:FindFirstChild(animal.slot)
    local prompt = podium and podium.Base.Spawn.PromptAttachment:FindFirstChildOfClass("ProximityPrompt")
    if prompt then PromptMemoryCache[animal.uid] = prompt end
    return prompt
end

local function buildStealCallbacks(prompt)
    if InternalStealCache[prompt] then return end
    local data = { holdCallbacks = {}, triggerCallbacks = {}, ready = true }
    local ok1, conns1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(conns1) == "table" then
        for _, conn in ipairs(conns1) do
            if type(conn.Function) == "function" then table.insert(data.holdCallbacks, conn.Function) end
        end
    end
    local ok2, conns2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(conns2) == "table" then
        for _, conn in ipairs(conns2) do
            if type(conn.Function) == "function" then table.insert(data.triggerCallbacks, conn.Function) end
        end
    end
    if #data.holdCallbacks > 0 or #data.triggerCallbacks > 0 then
        InternalStealCache[prompt] = data
    end
end

local function executeInternalStealAsync(prompt, animalData, sequence)
    local data = InternalStealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false
    IsStealing = true
    StealProgress = 0
    CurrentStealTarget = animalData
    
    task.spawn(function()
        for _, fn in ipairs(data.holdCallbacks) do task.spawn(fn) end
        local startTime = tick()
        local tpDone = false
        while tick() - startTime < 1.3 do
            StealProgress = (tick() - startTime) / 1.3
            if StealProgress >= 0.73 and not tpDone then
                tpDone = true
                local hrp = getHRP()
                if hrp then
                    local currentRot = hrp.CFrame.Rotation
                    hrp.CFrame = CFrame.new(sequence[1].Position) * currentRot
                    task.wait(0.1)
                    hrp.CFrame = CFrame.new(sequence[2].Position) * currentRot
                    task.wait(0.2)
                    local d1 = (hrp.Position - pos1).Magnitude
                    local d2 = (hrp.Position - pos2).Magnitude
                    hrp.CFrame = CFrame.new(d1 < d2 and pos1 or pos2) * currentRot
                end
            end
            task.wait(0.05)
        end
        StealProgress = 1
        for _, fn in ipairs(data.triggerCallbacks) do task.spawn(fn) end
        if fireproximityprompt then task.spawn(function() fireproximityprompt(prompt) end) end
        task.wait(0.1)
        data.ready = true
        task.wait(0.3)
        IsStealing = false
        StealProgress = 0
        CurrentStealTarget = nil
    end)
    return true
end

local function attemptSteal(prompt, animalData, sequence)
    if not prompt or not prompt.Parent then return false end
    buildStealCallbacks(prompt)
    if not InternalStealCache[prompt] then return false end
    return executeInternalStealAsync(prompt, animalData, sequence)
end

local function getNearestAnimal()
    local hrp = getHRP()
    if not hrp then return nil end
    local nearest, dist = nil, math.huge
    for _, animal in ipairs(allAnimalsCache) do
        local d = (hrp.Position - animal.worldPosition).Magnitude
        if d < dist and d <= AUTO_STEAL_PROX_RADIUS then
            dist = d nearest = animal
        end
    end
    return nearest
end

local function executeStealAction(sequence)
    if IsStealing then return end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local bp = player:FindFirstChild("Backpack")
    
    if hum and bp then
        if _G.AutoPotion then
            local potion = bp:FindFirstChild("Giant Potion")
            if potion then
                hum:EquipTool(potion)
                task.wait(0.1)
                pcall(function() potion:Activate() end)
                task.wait(0.1)
            end
        end

        local carpet = bp:FindFirstChild("Flying Carpet")
        if carpet then hum:EquipTool(carpet); task.wait(0.05) end
    end
    
    local animal = getNearestAnimal()
    if not animal then return end
    local prompt = findPrompt(animal)
    if not prompt then return end
    attemptSteal(prompt, animal, sequence)
end

CreateButtonWithKeybind("Auto tp Left", "LeftKey", function()
    executeStealAction(spot1_sequence)
end)

CreateButtonWithKeybind("Auto tp Right", "RightKey", function()
    executeStealAction(spot2_sequence)
end)

CreateButton("Desync", function()
    ResetToWork()
end)

local StatusLabel = CreateStatus("Status: IDLE")

Frame.Size = UDim2.new(0, 200, 0, currentYOffset + 10)
local originalSize = Frame.Size
local minimizedSize = UDim2.new(0, 200, 0, 40)

MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local targetSize = minimized and minimizedSize or originalSize
    local targetText = minimized and "+" or "-"
    TweenService:Create(Frame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = targetSize
    }):Play()
    MinimizeBtn.Text = targetText
end)

task.spawn(function()
    while true do
        task.wait(0.02)
        if IsStealing then
            local pct = math.floor((math.clamp(StealProgress, 0, 1) * 100) + 0.5)
            StatusLabel.Text = "STEALING: " .. pct .. "%"
            StatusLabel.TextColor3 = Color3.fromRGB(200, 150, 255)
        else
            StatusLabel.Text = "Status: IDLE"
            StatusLabel.TextColor3 = Color3.new(0.6, 0.8, 1)
        end
    end
end)

local currentEquipTask = nil
local isHolding = false

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, plr)
    if plr ~= player then return end
    if Config.InstantGrab and not IsStealing then
        prompt.HoldDuration = 0.1
        prompt.RequiresLineOfSight = false
        task.spawn(function()
            if fireproximityprompt then fireproximityprompt(prompt) end
            prompt:InputHoldBegin()
            task.wait(0.15)
            prompt:InputHoldEnd()
        end)
    end
    if not semiTPEnabled then return end
    isHolding = true
    if currentEquipTask then task.cancel(currentEquipTask) end
    currentEquipTask = task.spawn(function()
        task.wait(1)
        if isHolding and semiTPEnabled then
            local bp = player:WaitForChild("Backpack", 2)
            if bp then
                local carpet = bp:FindFirstChild("Flying Carpet")
                if carpet and player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid:EquipTool(carpet)
                end
            end
        end
    end)
end)

ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt, plr)
    if plr ~= player then return end
    isHolding = false
    if currentEquipTask then task.cancel(currentEquipTask) end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, plr)
    if plr ~= player or not semiTPEnabled then return end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then
        local bp = player:FindFirstChild("Backpack")
        if bp then
            local carpet = bp:FindFirstChild("Flying Carpet")
            if carpet and player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid:EquipTool(carpet)
            end
        end
        local d1 = (root.Position - pos1).Magnitude
        local d2 = (root.Position - pos2).Magnitude
        root.CFrame = CFrame.new(d1 < d2 and pos1 or pos2) * root.CFrame.Rotation
        if _G.AutoPotion then
            if bp then
                local potion = bp:FindFirstChild("Giant Potion")
                if potion and player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid:EquipTool(potion)
                    task.wait(0)
                    pcall(function() potion:Activate() end)
                end
            end
        end
    end
    isHolding = false
end)

initializeScanner()
