local Players = game:GetService("Players")
local player = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

local leaderstats = player:FindFirstChild("leaderstats") or player:WaitForChild("leaderstats", 5)
if not leaderstats then return end
local sheckles = leaderstats:FindFirstChild("Sheckles") or leaderstats:WaitForChild("Sheckles", 5)
if not sheckles then return end

local old = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("MikkaHub")
if old then old:Destroy() end

local AVATAR_URL = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"

local sg = Instance.new("ScreenGui")
sg.Name = "MikkaHub"
sg.ResetOnSpawn = false
sg.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 340, 0, 200)
frame.Position = UDim2.new(0.5, -170, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 20, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.ClipsDescendants = true
frame.Parent = sg

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 24)

local glow = Instance.new("UIStroke")
glow.Color = Color3.fromRGB(200, 120, 170)
glow.Thickness = 2
glow.Transparency = 0.5
glow.Parent = frame

spawn(function()
    while frame.Parent do
        TweenService:Create(glow, TweenInfo.new(2, Enum.EasingStyle.Sine), {Transparency = 0.2}):Play()
        task.wait(2)
        TweenService:Create(glow, TweenInfo.new(2, Enum.EasingStyle.Sine), {Transparency = 0.6}):Play()
        task.wait(2)
    end
end)

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundColor3 = Color3.fromRGB(35, 28, 42)
topBar.BorderSizePixel = 0
topBar.Parent = frame

Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 24)

local topFix = Instance.new("Frame")
topFix.Size = UDim2.new(1, 0, 0, 25)
topFix.Position = UDim2.new(0, 0, 0.5, 0)
topFix.BackgroundColor3 = Color3.fromRGB(35, 28, 42)
topFix.BorderSizePixel = 0
topFix.Parent = topBar

local sparkle = Instance.new("TextLabel")
sparkle.Size = UDim2.new(0, 30, 0, 30)
sparkle.Position = UDim2.new(0, 14, 0, 10)
sparkle.BackgroundTransparency = 1
sparkle.Text = "✨"
sparkle.TextSize = 22
sparkle.Font = Enum.Font.GothamBold
sparkle.Parent = topBar

spawn(function()
    while sparkle.Parent do
        TweenService:Create(sparkle, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 14, 0, 6)}):Play()
        task.wait(0.6)
        TweenService:Create(sparkle, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0, 14, 0, 10)}):Play()
        task.wait(0.6)
    end
end)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0, 200, 0, 50)
titleText.Position = UDim2.new(0, 48, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "MIKKA HUB"
titleText.TextColor3 = Color3.fromRGB(255, 200, 230)
titleText.TextSize = 18
titleText.Font = Enum.Font.GothamBlack
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -40, 0, 9)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 40)
closeBtn.Text = ""
closeBtn.AutoButtonColor = false
closeBtn.Parent = topBar

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

local closeIcon = Instance.new("TextLabel")
closeIcon.Size = UDim2.new(1, 0, 1, 0)
closeIcon.BackgroundTransparency = 1
closeIcon.Text = "×"
closeIcon.TextColor3 = Color3.fromRGB(220, 160, 180)
closeIcon.TextSize = 20
closeIcon.Font = Enum.Font.GothamBold
closeIcon.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 80, 100), Size = UDim2.new(0, 34, 0, 34)}):Play()
    closeIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 30, 40), Size = UDim2.new(0, 32, 0, 32)}):Play()
    closeIcon.TextColor3 = Color3.fromRGB(220, 160, 180)
end)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -28, 0, 130)
content.Position = UDim2.new(0, 14, 0, 58)
content.BackgroundTransparency = 1
content.Parent = frame

local avatarContainer = Instance.new("Frame")
avatarContainer.Size = UDim2.new(0, 80, 0, 80)
avatarContainer.Position = UDim2.new(0, 10, 0, 10)
avatarContainer.BackgroundTransparency = 1
avatarContainer.Parent = content

-- Orbit ring 1 - realistic glowing orbs with trails
local orbit1 = Instance.new("Frame")
orbit1.Size = UDim2.new(0, 100, 0, 100)
orbit1.Position = UDim2.new(0.5, -50, 0.5, -50)
orbit1.BackgroundTransparency = 1
orbit1.Parent = avatarContainer

for i = 1, 3 do
    -- Trail effect
    local trail = Instance.new("Frame")
    trail.Size = UDim2.new(0, 8, 0, 8)
    trail.BackgroundColor3 = Color3.fromRGB(255, 150, 200)
    trail.BackgroundTransparency = 0.7
    trail.BorderSizePixel = 0
    trail.Parent = orbit1
    Instance.new("UICorner", trail).CornerRadius = UDim.new(1, 0)
    
    -- Main orb
    local orb = Instance.new("Frame")
    orb.Size = UDim2.new(0, 10, 0, 10)
    orb.BackgroundColor3 = Color3.fromRGB(255, 200, 230)
    orb.BorderSizePixel = 0
    orb.ZIndex = 2
    orb.Parent = orbit1
    Instance.new("UICorner", orb).CornerRadius = UDim.new(1, 0)
    
    -- Inner glow
    local inner = Instance.new("Frame")
    inner.Size = UDim2.new(0, 4, 0, 4)
    inner.Position = UDim2.new(0.5, -2, 0.5, -2)
    inner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    inner.BorderSizePixel = 0
    inner.ZIndex = 3
    inner.Parent = orb
    Instance.new("UICorner", inner).CornerRadius = UDim.new(1, 0)
    
    spawn(function()
        local angle = (i / 3) * math.pi * 2
        while orb.Parent do
            angle = angle + 0.04
            local x = math.cos(angle) * 48
            local y = math.sin(angle) * 48
            
            trail.Position = orb.Position
            orb.Position = UDim2.new(0.5, x - 5, 0.5, y - 5)
            
            -- Fade trail based on distance
            local dist = math.sqrt(x^2 + y^2)
            trail.BackgroundTransparency = 0.3 + (dist / 100)
            
            task.wait(0.03)
        end
    end)
end

-- Orbit ring 2 - slower, larger orbs
local orbit2 = Instance.new("Frame")
orbit2.Size = UDim2.new(0, 110, 0, 110)
orbit2.Position = UDim2.new(0.5, -55, 0.5, -55)
orbit2.BackgroundTransparency = 1
orbit2.Parent = avatarContainer

for i = 1, 2 do
    local trail = Instance.new("Frame")
    trail.Size = UDim2.new(0, 12, 0, 12)
    trail.BackgroundColor3 = Color3.fromRGB(200, 100, 160)
    trail.BackgroundTransparency = 0.8
    trail.BorderSizePixel = 0
    trail.Parent = orbit2
    Instance.new("UICorner", trail).CornerRadius = UDim.new(1, 0)
    
    local orb = Instance.new("Frame")
    orb.Size = UDim2.new(0, 14, 0, 14)
    orb.BackgroundColor3 = Color3.fromRGB(220, 140, 190)
    orb.BorderSizePixel = 0
    orb.ZIndex = 2
    orb.Parent = orbit2
    Instance.new("UICorner", orb).CornerRadius = UDim.new(1, 0)
    
    local inner = Instance.new("Frame")
    inner.Size = UDim2.new(0, 6, 0, 6)
    inner.Position = UDim2.new(0.5, -3, 0.5, -3)
    inner.BackgroundColor3 = Color3.fromRGB(255, 220, 240)
    inner.BorderSizePixel = 0
    inner.ZIndex = 3
    inner.Parent = orb
    Instance.new("UICorner", inner).CornerRadius = UDim.new(1, 0)
    
    -- Outer glow ring
    local glowRing = Instance.new("UIStroke")
    glowRing.Color = Color3.fromRGB(255, 180, 220)
    glowRing.Thickness = 2
    glowRing.Transparency = 0.5
    glowRing.Parent = orb
    
    spawn(function()
        local angle = (i / 2) * math.pi * 2
        while orb.Parent do
            angle = angle - 0.025
            local x = math.cos(angle) * 55
            local y = math.sin(angle) * 55
            
            trail.Position = orb.Position
            orb.Position = UDim2.new(0.5, x - 7, 0.5, y - 7)
            
            task.wait(0.03)
        end
    end)
end

-- Avatar frame
local avatarFrame = Instance.new("Frame")
avatarFrame.Size = UDim2.new(0, 64, 0, 64)
avatarFrame.Position = UDim2.new(0.5, -32, 0.5, -32)
avatarFrame.BackgroundColor3 = Color3.fromRGB(40, 30, 45)
avatarFrame.BorderSizePixel = 0
avatarFrame.ZIndex = 2
avatarFrame.Parent = avatarContainer

Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)

local avatarStroke = Instance.new("UIStroke")
avatarStroke.Color = Color3.fromRGB(220, 130, 180)
avatarStroke.Thickness = 3
avatarStroke.Parent = avatarFrame

local avatarImage = Instance.new("ImageLabel")
avatarImage.Size = UDim2.new(1, 0, 1, 0)
avatarImage.BackgroundTransparency = 1
avatarImage.Image = AVATAR_URL
avatarImage.ScaleType = Enum.ScaleType.Crop
avatarImage.ZIndex = 2
avatarImage.Parent = avatarFrame

Instance.new("UICorner", avatarImage).CornerRadius = UDim.new(1, 0)

-- Status dot
local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 12, 0, 12)
statusDot.Position = UDim2.new(1, -16, 1, -16)
statusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 130)
statusDot.BorderSizePixel = 0
statusDot.ZIndex = 3
statusDot.Parent = avatarFrame

Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

local statusRing = Instance.new("UIStroke")
statusRing.Color = Color3.fromRGB(25, 20, 30)
statusRing.Thickness = 2
statusRing.Parent = statusDot

spawn(function()
    while statusDot.Parent do
        TweenService:Create(statusDot, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -17, 1, -17)}):Play()
        task.wait(0.8)
        TweenService:Create(statusDot, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -16, 1, -16)}):Play()
        task.wait(0.8)
    end
end)

-- Value section
local valueSection = Instance.new("Frame")
valueSection.Size = UDim2.new(1, -100, 0, 80)
valueSection.Position = UDim2.new(0, 96, 0, 10)
valueSection.BackgroundTransparency = 1
valueSection.Parent = content

local valueText = Instance.new("TextLabel")
valueText.Size = UDim2.new(1, 0, 0, 40)
valueText.Position = UDim2.new(0, 0, 0, 8)
valueText.BackgroundTransparency = 1
valueText.Text = tostring(sheckles.Value)
valueText.TextColor3 = Color3.fromRGB(255, 230, 245)
valueText.TextSize = 32
valueText.Font = Enum.Font.GothamBlack
valueText.TextXAlignment = Enum.TextXAlignment.Left
valueText.Parent = valueSection

local valueLabel = Instance.new("TextLabel")
valueLabel.Size = UDim2.new(1, 0, 0, 18)
valueLabel.Position = UDim2.new(0, 0, 0, 46)
valueLabel.BackgroundTransparency = 1
valueLabel.Text = "SHECKLES"
valueLabel.TextColor3 = Color3.fromRGB(160, 120, 145)
valueLabel.TextSize = 11
valueLabel.Font = Enum.Font.Gotham
valueLabel.TextXAlignment = Enum.TextXAlignment.Left
valueLabel.Parent = valueSection

-- Controls
local controls = Instance.new("Frame")
controls.Size = UDim2.new(1, 0, 0, 36)
controls.Position = UDim2.new(0, 0, 0, 92)
controls.BackgroundTransparency = 1
controls.Parent = content

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(0.4, 0, 0, 32)
inputBox.Position = UDim2.new(0, 0, 0, 2)
inputBox.BackgroundColor3 = Color3.fromRGB(35, 30, 40)
inputBox.Text = "1000"
inputBox.TextColor3 = Color3.fromRGB(220, 210, 225)
inputBox.PlaceholderText = "Amount"
inputBox.PlaceholderColor3 = Color3.fromRGB(80, 70, 85)
inputBox.TextSize = 13
inputBox.Font = Enum.Font.GothamBold
inputBox.ClearTextOnFocus = true
inputBox.Parent = controls

Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 12)

local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Color3.fromRGB(60, 50, 70)
inputStroke.Thickness = 1.5
inputStroke.Parent = inputBox

local addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.new(0.56, 0, 0, 32)
addBtn.Position = UDim2.new(0.44, 0, 0, 2)
addBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 150)
addBtn.Text = "ADD"
addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addBtn.TextSize = 13
addBtn.Font = Enum.Font.GothamBlack
addBtn.AutoButtonColor = false
addBtn.Parent = controls

Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 12)

addBtn.MouseEnter:Connect(function()
    TweenService:Create(addBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(230, 120, 180), Size = UDim2.new(0.58, 0, 0, 34)}):Play()
    inputStroke.Color = Color3.fromRGB(100, 80, 110)
end)
addBtn.MouseLeave:Connect(function()
    TweenService:Create(addBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(200, 100, 150), Size = UDim2.new(0.56, 0, 0, 32)}):Play()
    inputStroke.Color = Color3.fromRGB(60, 50, 70)
end)

addBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(addBtn, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(170, 80, 130), Size = UDim2.new(0.54, 0, 0, 30)}):Play()
    end
end)
addBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(addBtn, TweenInfo.new(0.15, Enum.EasingStyle.Back), {BackgroundColor3 = Color3.fromRGB(200, 100, 150), Size = UDim2.new(0.56, 0, 0, 32)}):Play()
    end
end)

-- Functionality
local function addSheckles(amount)
    amount = tonumber(amount) or 1000
    local target = sheckles.Value + amount
    TweenService:Create(valueText, TweenInfo.new(0.15), {TextTransparency = 0.3}):Play()
    task.wait(0.1)
    sheckles.Value = target
    valueText.Text = tostring(target)
    TweenService:Create(valueText, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
end

addBtn.MouseButton1Click:Connect(function()
    addSheckles(inputBox.Text)
end)

sheckles.Changed:Connect(function(newVal)
    valueText.Text = tostring(newVal)
end)

-- Dragging
local dragging = false
local dragStart, startPos

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

frame.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Toggle button with avatar and realistic orbs
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 50, 0, 50)
toggle.Position = UDim2.new(0, 16, 0.5, -25)
toggle.BackgroundColor3 = Color3.fromRGB(25, 20, 30)
toggle.Text = ""
toggle.AutoButtonColor = false
toggle.Visible = false
toggle.Parent = sg

Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

local toggleGlow = Instance.new("UIStroke")
toggleGlow.Color = Color3.fromRGB(200, 120, 170)
toggleGlow.Thickness = 2
toggleGlow.Transparency = 0.5
toggleGlow.Parent = toggle

-- Toggle orbit with realistic orbs
local toggleOrbit = Instance.new("Frame")
toggleOrbit.Size = UDim2.new(0, 58, 0, 58)
toggleOrbit.Position = UDim2.new(0.5, -29, 0.5, -29)
toggleOrbit.BackgroundTransparency = 1
toggleOrbit.Parent = toggle

for i = 1, 2 do
    local trail = Instance.new("Frame")
    trail.Size = UDim2.new(0, 6, 0, 6)
    trail.BackgroundColor3 = Color3.fromRGB(255, 180, 220)
    trail.BackgroundTransparency = 0.6
    trail.BorderSizePixel = 0
    trail.Parent = toggleOrbit
    Instance.new("UICorner", trail).CornerRadius = UDim.new(1, 0)
    
    local orb = Instance.new("Frame")
    orb.Size = UDim2.new(0, 8, 0, 8)
    orb.BackgroundColor3 = Color3.fromRGB(255, 220, 240)
    orb.BorderSizePixel = 0
    orb.Parent = toggleOrbit
    Instance.new("UICorner", orb).CornerRadius = UDim.new(1, 0)
    
    local inner = Instance.new("Frame")
    inner.Size = UDim2.new(0, 3, 0, 3)
    inner.Position = UDim2.new(0.5, -1, 0.5, -1)
    inner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    inner.BorderSizePixel = 0
    inner.Parent = orb
    Instance.new("UICorner", inner).CornerRadius = UDim.new(1, 0)
    
    spawn(function()
        local angle = (i / 2) * math.pi * 2
        while orb.Parent do
            angle = angle + 0.06
            local x = math.cos(angle) * 29
            local y = math.sin(angle) * 29
            
            trail.Position = orb.Position
            orb.Position = UDim2.new(0.5, x - 4, 0.5, y - 4)
            
            task.wait(0.03)
        end
    end)
end

local toggleAvatar = Instance.new("ImageLabel")
toggleAvatar.Size = UDim2.new(0, 40, 0, 40)
toggleAvatar.Position = UDim2.new(0.5, -20, 0.5, -20)
toggleAvatar.BackgroundTransparency = 1
toggleAvatar.Image = AVATAR_URL
toggleAvatar.ScaleType = Enum.ScaleType.Crop
toggleAvatar.Parent = toggle

Instance.new("UICorner", toggleAvatar).CornerRadius = UDim.new(1, 0)

-- Toggle pulse
spawn(function()
    while toggle.Parent do
        TweenService:Create(toggleGlow, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Transparency = 0.2}):Play()
        task.wait(1.5)
        TweenService:Create(toggleGlow, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Transparency = 0.6}):Play()
        task.wait(1.5)
    end
end)

toggle.MouseEnter:Connect(function()
    TweenService:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 30, 45), Size = UDim2.new(0, 54, 0, 54)}):Play()
    TweenService:Create(toggle, TweenInfo.new(0.15), {Position = UDim2.new(0, 14, 0.5, -27)}):Play()
end)
toggle.MouseLeave:Connect(function()
    TweenService:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(25, 20, 30), Size = UDim2.new(0, 50, 0, 50)}):Play()
    TweenService:Create(toggle, TweenInfo.new(0.15), {Position = UDim2.new(0, 16, 0.5, -25)}):Play()
end)

closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    task.wait(0.25)
    frame.Visible = false
    toggle.Visible = true
    toggle.Size = UDim2.new(0, 0, 0, 0)
    toggle.Position = UDim2.new(0, 41, 0.5, 0)
    TweenService:Create(toggle, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0, 16, 0.5, -25)
    }):Play()
end)

toggle.MouseButton1Click:Connect(function()
    toggle.Visible = false
    frame.Visible = true
    frame.Size = UDim2.new(0, 0, 0, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 340, 0, 200),
        Position = UDim2.new(0.5, -170, 0.1, 0)
    }):Play()
end)

-- Open animation
frame.Size = UDim2.new(0, 0, 0, 0)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 340, 0, 200),
    Position = UDim2.new(0.5, -170, 0.1, 0)
}):Play()

print("MIKKA HUB loaded | " .. player.Name)
