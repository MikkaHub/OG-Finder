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

-- Main frame with slight tilt feel
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 180)
frame.Position = UDim2.new(0.5, -160, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
frame.BorderSizePixel = 0
frame.Active = true
frame.ClipsDescendants = true
frame.Parent = sg

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

-- Double border effect
local outerStroke = Instance.new("UIStroke")
outerStroke.Color = Color3.fromRGB(30, 25, 35)
outerStroke.Thickness = 1
outerStroke.Transparency = 0.6
outerStroke.Parent = frame

local innerStroke = Instance.new("UIStroke")
innerStroke.Color = Color3.fromRGB(60, 40, 70)
innerStroke.Thickness = 1
innerStroke.Transparency = 0.8
innerStroke.Parent = frame

-- Top bar with subtle gradient
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 3)
topBar.BackgroundColor3 = Color3.fromRGB(200, 80, 130)
topBar.BorderSizePixel = 0
topBar.Parent = frame

-- Header with avatar inline
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 48)
header.Position = UDim2.new(0, 0, 0, 3)
header.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
header.BorderSizePixel = 0
header.Parent = frame

-- Small avatar in header
local miniAvatar = Instance.new("ImageLabel")
miniAvatar.Size = UDim2.new(0, 28, 0, 28)
miniAvatar.Position = UDim2.new(0, 12, 0, 10)
miniAvatar.BackgroundColor3 = Color3.fromRGB(40, 30, 40)
miniAvatar.Image = AVATAR_URL
miniAvatar.ScaleType = Enum.ScaleType.Crop
miniAvatar.Parent = header

Instance.new("UICorner", miniAvatar).CornerRadius = UDim.new(0, 6)

local miniStroke = Instance.new("UIStroke")
miniStroke.Color = Color3.fromRGB(80, 50, 70)
miniStroke.Thickness = 1
miniStroke.Parent = miniAvatar

-- Title next to avatar
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0, 200, 0, 48)
titleText.Position = UDim2.new(0, 48, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "MIKKA HUB"
titleText.TextColor3 = Color3.fromRGB(220, 200, 210)
titleText.TextSize = 15
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = header

-- Subtitle
local subTitle = Instance.new("TextLabel")
subTitle.Size = UDim2.new(0, 200, 0, 14)
subTitle.Position = UDim2.new(0, 48, 0, 30)
subTitle.BackgroundTransparency = 1
subTitle.Text = "v2.0  |  " .. player.Name
subTitle.TextColor3 = Color3.fromRGB(100, 80, 95)
subTitle.TextSize = 9
subTitle.Font = Enum.Font.Gotham
subTitle.TextXAlignment = Enum.TextXAlignment.Left
subTitle.Parent = header

-- Close X
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -30, 0, 13)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = ""
closeBtn.AutoButtonColor = false
closeBtn.Parent = header

local closeX = Instance.new("TextLabel")
closeX.Size = UDim2.new(1, 0, 1, 0)
closeX.BackgroundTransparency = 1
closeX.Text = "×"
closeX.TextColor3 = Color3.fromRGB(120, 90, 105)
closeX.TextSize = 20
closeX.Font = Enum.Font.GothamBold
closeX.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
    closeX.TextColor3 = Color3.fromRGB(255, 80, 100)
    TweenService:Create(closeX, TweenInfo.new(0.1), {Rotation = 90}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    closeX.TextColor3 = Color3.fromRGB(120, 90, 105)
    TweenService:Create(closeX, TweenInfo.new(0.1), {Rotation = 0}):Play()
end)

-- Divider line
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -24, 0, 1)
divider.Position = UDim2.new(0, 12, 0, 51)
divider.BackgroundColor3 = Color3.fromRGB(35, 30, 40)
divider.BorderSizePixel = 0
divider.Parent = frame

-- Main content area
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -24, 0, 110)
content.Position = UDim2.new(0, 12, 0, 56)
content.BackgroundTransparency = 1
content.Parent = frame

-- Big avatar with glow
local avatarFrame = Instance.new("Frame")
avatarFrame.Size = UDim2.new(0, 64, 0, 64)
avatarFrame.Position = UDim2.new(0, 0, 0, 8)
avatarFrame.BackgroundColor3 = Color3.fromRGB(25, 20, 28)
avatarFrame.BorderSizePixel = 0
avatarFrame.Parent = content

Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(0, 12)

local avatarGlow = Instance.new("UIStroke")
avatarGlow.Color = Color3.fromRGB(100, 60, 90)
avatarGlow.Thickness = 2
avatarGlow.Transparency = 0.5
avatarGlow.Parent = avatarFrame

local avatarImage = Instance.new("ImageLabel")
avatarImage.Size = UDim2.new(1, 0, 1, 0)
avatarImage.BackgroundTransparency = 1
avatarImage.Image = AVATAR_URL
avatarImage.ScaleType = Enum.ScaleType.Crop
avatarImage.Parent = avatarFrame

Instance.new("UICorner", avatarImage).CornerRadius = UDim.new(0, 12)

-- Status dot with pulse
local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 10, 0, 10)
statusDot.Position = UDim2.new(1, -14, 1, -14)
statusDot.BackgroundColor3 = Color3.fromRGB(0, 220, 100)
statusDot.BorderSizePixel = 0
statusDot.ZIndex = 2
statusDot.Parent = avatarFrame

Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

local statusRing = Instance.new("UIStroke")
statusRing.Color = Color3.fromRGB(12, 12, 16)
statusRing.Thickness = 2
statusRing.Parent = statusDot

-- Pulse animation
spawn(function()
    while statusDot.Parent do
        TweenService:Create(statusDot, TweenInfo.new(1, Enum.EasingStyle.Sine), {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -15, 1, -15)}):Play()
        task.wait(1)
        TweenService:Create(statusDot, TweenInfo.new(1, Enum.EasingStyle.Sine), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(1, -14, 1, -14)}):Play()
        task.wait(1)
    end
end)

-- Value display
local valueSection = Instance.new("Frame")
valueSection.Size = UDim2.new(1, -80, 0, 70)
valueSection.Position = UDim2.new(0, 76, 0, 8)
valueSection.BackgroundTransparency = 1
valueSection.Parent = content

local valueText = Instance.new("TextLabel")
valueText.Size = UDim2.new(1, 0, 0, 36)
valueText.Position = UDim2.new(0, 0, 0, 4)
valueText.BackgroundTransparency = 1
valueText.Text = tostring(sheckles.Value)
valueText.TextColor3 = Color3.fromRGB(240, 240, 240)
valueText.TextSize = 28
valueText.Font = Enum.Font.GothamBlack
valueText.TextXAlignment = Enum.TextXAlignment.Left
valueText.Parent = valueSection

local valueLine = Instance.new("Frame")
valueLine.Size = UDim2.new(0.4, 0, 0, 2)
valueLine.Position = UDim2.new(0, 0, 0, 38)
valueLine.BackgroundColor3 = Color3.fromRGB(180, 80, 130)
valueLine.BorderSizePixel = 0
valueLine.Parent = valueSection

local valueLabel = Instance.new("TextLabel")
valueLabel.Size = UDim2.new(1, 0, 0, 16)
valueLabel.Position = UDim2.new(0, 0, 0, 44)
valueLabel.BackgroundTransparency = 1
valueLabel.Text = "SHECKLES"
valueLabel.TextColor3 = Color3.fromRGB(100, 80, 95)
valueLabel.TextSize = 10
valueLabel.Font = Enum.Font.Gotham
valueLabel.TextXAlignment = Enum.TextXAlignment.Left
valueLabel.Parent = valueSection

-- Controls
local controls = Instance.new("Frame")
controls.Size = UDim2.new(1, 0, 0, 32)
controls.Position = UDim2.new(0, 0, 0, 78)
controls.BackgroundTransparency = 1
controls.Parent = content

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(0.38, 0, 0, 28)
inputBox.Position = UDim2.new(0, 0, 0, 2)
inputBox.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
inputBox.Text = "1000"
inputBox.TextColor3 = Color3.fromRGB(180, 180, 180)
inputBox.PlaceholderText = "Amount"
inputBox.PlaceholderColor3 = Color3.fromRGB(60, 60, 65)
inputBox.TextSize = 12
inputBox.Font = Enum.Font.Gotham
inputBox.ClearTextOnFocus = true
inputBox.Parent = controls

Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 6)

local inputLine = Instance.new("UIStroke")
inputLine.Color = Color3.fromRGB(50, 40, 55)
inputLine.Thickness = 1
inputLine.Parent = inputBox

addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.new(0.58, 0, 0, 28)
addBtn.Position = UDim2.new(0.42, 0, 0, 2)
addBtn.BackgroundColor3 = Color3.fromRGB(160, 70, 115)
addBtn.Text = "ADD"
addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addBtn.TextSize = 12
addBtn.Font = Enum.Font.GothamBold
addBtn.AutoButtonColor = false
addBtn.Parent = controls

Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 6)

addBtn.MouseEnter:Connect(function()
    TweenService:Create(addBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(190, 90, 140)}):Play()
    inputLine.Color = Color3.fromRGB(80, 60, 80)
end)
addBtn.MouseLeave:Connect(function()
    TweenService:Create(addBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(160, 70, 115)}):Play()
    inputLine.Color = Color3.fromRGB(50, 40, 55)
end)

addBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(addBtn, TweenInfo.new(0.06), {BackgroundColor3 = Color3.fromRGB(130, 50, 90), Size = UDim2.new(0.56, 0, 0, 26)}):Play()
    end
end)
addBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(addBtn, TweenInfo.new(0.1, Enum.EasingStyle.Back), {BackgroundColor3 = Color3.fromRGB(160, 70, 115), Size = UDim2.new(0.58, 0, 0, 28)}):Play()
    end
end)

-- Functionality
local function addSheckles(amount)
    amount = tonumber(amount) or 1000
    local target = sheckles.Value + amount
    TweenService:Create(valueText, TweenInfo.new(0.12), {TextTransparency = 0.3}):Play()
    task.wait(0.08)
    sheckles.Value = target
    valueText.Text = tostring(target)
    TweenService:Create(valueText, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
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

-- Toggle with avatar
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 42, 0, 42)
toggle.Position = UDim2.new(0, 14, 0.5, -21)
toggle.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
toggle.Text = ""
toggle.AutoButtonColor = false
toggle.Visible = false
toggle.Parent = sg

Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 10)

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(80, 50, 70)
toggleStroke.Thickness = 1.5
toggleStroke.Parent = toggle

local toggleAvatar = Instance.new("ImageLabel")
toggleAvatar.Size = UDim2.new(0, 34, 0, 34)
toggleAvatar.Position = UDim2.new(0.5, -17, 0.5, -17)
toggleAvatar.BackgroundTransparency = 1
toggleAvatar.Image = AVATAR_URL
toggleAvatar.ScaleType = Enum.ScaleType.Crop
toggleAvatar.Parent = toggle

Instance.new("UICorner", toggleAvatar).CornerRadius = UDim.new(0, 8)

local toggleStatus = Instance.new("Frame")
toggleStatus.Size = UDim2.new(0, 7, 0, 7)
toggleStatus.Position = UDim2.new(1, -9, 1, -9)
toggleStatus.BackgroundColor3 = Color3.fromRGB(0, 220, 100)
toggleStatus.BorderSizePixel = 0
toggleStatus.ZIndex = 2
toggleStatus.Parent = toggle

Instance.new("UICorner", toggleStatus).CornerRadius = UDim.new(1, 0)

local toggleRing = Instance.new("UIStroke")
toggleRing.Color = Color3.fromRGB(18, 18, 22)
toggleRing.Thickness = 1.5
toggleRing.Parent = toggleStatus

-- Toggle pulse
spawn(function()
    while toggle.Parent do
        TweenService:Create(toggleStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Transparency = 0.3}):Play()
        task.wait(1.5)
        TweenService:Create(toggleStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Transparency = 0.7}):Play()
        task.wait(1.5)
    end
end)

toggle.MouseEnter:Connect(function()
    TweenService:Create(toggle, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30, 25, 35), Size = UDim2.new(0, 46, 0, 46)}):Play()
    TweenService:Create(toggle, TweenInfo.new(0.12), {Position = UDim2.new(0, 12, 0.5, -23)}):Play()
end)

toggle.MouseLeave:Connect(function()
    TweenService:Create(toggle, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(18, 18, 22), Size = UDim2.new(0, 42, 0, 42)}):Play()
    TweenService:Create(toggle, TweenInfo.new(0.12), {Position = UDim2.new(0, 14, 0.5, -21)}):Play()
end)

closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    task.wait(0.2)
    frame.Visible = false
    toggle.Visible = true
    toggle.Size = UDim2.new(0, 0, 0, 0)
    toggle.Position = UDim2.new(0, 35, 0.5, 0)
    TweenService:Create(toggle, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 42, 0, 42),
        Position = UDim2.new(0, 14, 0.5, -21)
    }):Play()
end)

toggle.MouseButton1Click:Connect(function()
    toggle.Visible = false
    frame.Visible = true
    frame.Size = UDim2.new(0, 0, 0, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 320, 0, 180),
        Position = UDim2.new(0.5, -160, 0.1, 0)
    }):Play()
end)

-- Open animation
frame.Size = UDim2.new(0, 0, 0, 0)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 320, 0, 180),
    Position = UDim2.new(0.5, -160, 0.1, 0)
}):Play()

print("MIKKA HUB loaded | " .. player.Name)
