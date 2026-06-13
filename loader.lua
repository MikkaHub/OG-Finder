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

-- Main frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 180)
frame.Position = UDim2.new(0.5, -160, 0.5, -90)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
frame.BorderSizePixel = 0
frame.Active = true
frame.ClipsDescendants = true
frame.Parent = sg

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

-- Shadow
local shadow = Instance.new("ImageLabel")
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 6)
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.6
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.ZIndex = -1
shadow.Parent = frame

-- Top gradient bar
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 3)
topBar.BackgroundColor3 = Color3.fromRGB(190, 100, 150)
topBar.BorderSizePixel = 0
topBar.Parent = frame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 48)
header.Position = UDim2.new(0, 0, 0, 3)
header.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
header.BorderSizePixel = 0
header.Parent = frame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = header

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 20)
headerFix.Position = UDim2.new(0, 0, 0.5, 0)
headerFix.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

-- Avatar in header
local miniAvatar = Instance.new("ImageLabel")
miniAvatar.Size = UDim2.new(0, 28, 0, 28)
miniAvatar.Position = UDim2.new(0, 14, 0, 10)
miniAvatar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
miniAvatar.Image = AVATAR_URL
miniAvatar.ScaleType = Enum.ScaleType.Crop
miniAvatar.Parent = header

Instance.new("UICorner", miniAvatar).CornerRadius = UDim.new(1, 0)

local miniStroke = Instance.new("UIStroke")
miniStroke.Color = Color3.fromRGB(70, 60, 75)
miniStroke.Thickness = 1.5
miniStroke.Parent = miniAvatar

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 200, 0, 48)
title.Position = UDim2.new(0, 50, 0, 0)
title.BackgroundTransparency = 1
title.Text = "MIKKA HUB"
title.TextColor3 = Color3.fromRGB(220, 200, 215)
title.TextSize = 16
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -36, 0, 11)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 25, 30)
closeBtn.Text = ""
closeBtn.AutoButtonColor = false
closeBtn.Parent = header

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local closeIcon = Instance.new("TextLabel")
closeIcon.Size = UDim2.new(1, 0, 1, 0)
closeIcon.BackgroundTransparency = 1
closeIcon.Text = "×"
closeIcon.TextColor3 = Color3.fromRGB(160, 120, 135)
closeIcon.TextSize = 20
closeIcon.Font = Enum.Font.GothamBold
closeIcon.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(220, 60, 90)}):Play()
    closeIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(40, 25, 30)}):Play()
    closeIcon.TextColor3 = Color3.fromRGB(160, 120, 135)
end)

-- Content
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -24, 0, 116)
content.Position = UDim2.new(0, 12, 0, 54)
content.BackgroundTransparency = 1
content.Parent = frame

-- Left: Avatar
local leftSection = Instance.new("Frame")
leftSection.Size = UDim2.new(0, 80, 1, 0)
leftSection.BackgroundTransparency = 1
leftSection.Parent = content

local avatarFrame = Instance.new("Frame")
avatarFrame.Size = UDim2.new(0, 64, 0, 64)
avatarFrame.Position = UDim2.new(0.5, -32, 0, 8)
avatarFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
avatarFrame.BorderSizePixel = 0
avatarFrame.Parent = leftSection

Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)

local avatarStroke = Instance.new("UIStroke")
avatarStroke.Color = Color3.fromRGB(90, 70, 100)
avatarStroke.Thickness = 2
avatarStroke.Parent = avatarFrame

local avatarImage = Instance.new("ImageLabel")
avatarImage.Size = UDim2.new(1, 0, 1, 0)
avatarImage.BackgroundTransparency = 1
avatarImage.Image = AVATAR_URL
avatarImage.ScaleType = Enum.ScaleType.Crop
avatarImage.Parent = avatarFrame

Instance.new("UICorner", avatarImage).CornerRadius = UDim.new(1, 0)

-- Status dot
local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 10, 0, 10)
statusDot.Position = UDim2.new(1, -14, 1, -14)
statusDot.BackgroundColor3 = Color3.fromRGB(0, 220, 100)
statusDot.BorderSizePixel = 0
statusDot.ZIndex = 2
statusDot.Parent = avatarFrame

Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

local statusRing = Instance.new("UIStroke")
statusRing.Color = Color3.fromRGB(18, 18, 22)
statusRing.Thickness = 2
statusRing.Parent = statusDot

-- Username
local username = Instance.new("TextLabel")
username.Size = UDim2.new(1, 0, 0, 16)
username.Position = UDim2.new(0, 0, 0, 78)
username.BackgroundTransparency = 1
username.Text = "@" .. player.Name
username.TextColor3 = Color3.fromRGB(120, 110, 125)
username.TextSize = 10
username.Font = Enum.Font.Gotham
username.TextXAlignment = Enum.TextXAlignment.Center
username.Parent = leftSection

-- Right: Value + Controls
local rightSection = Instance.new("Frame")
rightSection.Size = UDim2.new(1, -88, 1, 0)
rightSection.Position = UDim2.new(0, 88, 0, 0)
rightSection.BackgroundTransparency = 1
rightSection.Parent = content

local valueText = Instance.new("TextLabel")
valueText.Size = UDim2.new(1, 0, 0, 42)
valueText.Position = UDim2.new(0, 0, 0, 10)
valueText.BackgroundTransparency = 1
valueText.Text = tostring(sheckles.Value)
valueText.TextColor3 = Color3.fromRGB(245, 245, 245)
valueText.TextSize = 32
valueText.Font = Enum.Font.GothamBlack
valueText.TextXAlignment = Enum.TextXAlignment.Left
valueText.Parent = rightSection

local valueLabel = Instance.new("TextLabel")
valueLabel.Size = UDim2.new(1, 0, 0, 16)
valueLabel.Position = UDim2.new(0, 0, 0, 50)
valueLabel.BackgroundTransparency = 1
valueLabel.Text = "SHECKLES"
valueLabel.TextColor3 = Color3.fromRGB(110, 100, 115)
valueLabel.TextSize = 10
valueLabel.Font = Enum.Font.Gotham
valueLabel.TextXAlignment = Enum.TextXAlignment.Left
valueLabel.Parent = rightSection

-- Accent line
local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(0.35, 0, 0, 2)
accentLine.Position = UDim2.new(0, 0, 0, 68)
accentLine.BackgroundColor3 = Color3.fromRGB(190, 100, 150)
accentLine.BorderSizePixel = 0
accentLine.Parent = rightSection

-- Controls
local controls = Instance.new("Frame")
controls.Size = UDim2.new(1, 0, 0, 32)
controls.Position = UDim2.new(0, 0, 0, 80)
controls.BackgroundTransparency = 1
controls.Parent = rightSection

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(0.38, 0, 0, 30)
inputBox.Position = UDim2.new(0, 0, 0, 1)
inputBox.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
inputBox.Text = "1000"
inputBox.TextColor3 = Color3.fromRGB(200, 200, 205)
inputBox.PlaceholderText = "Amount"
inputBox.PlaceholderColor3 = Color3.fromRGB(70, 70, 75)
inputBox.TextSize = 12
inputBox.Font = Enum.Font.Gotham
inputBox.ClearTextOnFocus = true
inputBox.Parent = controls

Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 10)

local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Color3.fromRGB(50, 50, 55)
inputStroke.Thickness = 1
inputStroke.Parent = inputBox

local addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.new(0.58, 0, 0, 30)
addBtn.Position = UDim2.new(0.42, 0, 0, 1)
addBtn.BackgroundColor3 = Color3.fromRGB(175, 85, 130)
addBtn.Text = "ADD"
addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addBtn.TextSize = 12
addBtn.Font = Enum.Font.GothamBold
addBtn.AutoButtonColor = false
addBtn.Parent = controls

Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 10)

addBtn.MouseEnter:Connect(function()
    TweenService:Create(addBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(205, 105, 160)}):Play()
    inputStroke.Color = Color3.fromRGB(80, 70, 90)
end)
addBtn.MouseLeave:Connect(function()
    TweenService:Create(addBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(175, 85, 130)}):Play()
    inputStroke.Color = Color3.fromRGB(50, 50, 55)
end)

addBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(addBtn, TweenInfo.new(0.06), {BackgroundColor3 = Color3.fromRGB(145, 65, 110)}):Play()
    end
end)
addBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(addBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(175, 85, 130)}):Play()
    end
end)

-- Functionality
local function addSheckles(amount)
    amount = tonumber(amount) or 1000
    local target = sheckles.Value + amount
    TweenService:Create(valueText, TweenInfo.new(0.1), {TextTransparency = 0.3}):Play()
    task.wait(0.06)
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

-- TOGGLE - Bottom right corner
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 48, 0, 48)
toggle.Position = UDim2.new(1, -64, 1, -64)
toggle.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
toggle.Text = ""
toggle.AutoButtonColor = false
toggle.Visible = false
toggle.Parent = sg

Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(80, 70, 90)
toggleStroke.Thickness = 1.5
toggleStroke.Parent = toggle

local toggleAvatar = Instance.new("ImageLabel")
toggleAvatar.Size = UDim2.new(0, 38, 0, 38)
toggleAvatar.Position = UDim2.new(0.5, -19, 0.5, -19)
toggleAvatar.BackgroundTransparency = 1
toggleAvatar.Image = AVATAR_URL
toggleAvatar.ScaleType = Enum.ScaleType.Crop
toggleAvatar.Parent = toggle

Instance.new("UICorner", toggleAvatar).CornerRadius = UDim.new(1, 0)

local toggleStatus = Instance.new("Frame")
toggleStatus.Size = UDim2.new(0, 8, 0, 8)
toggleStatus.Position = UDim2.new(1, -11, 1, -11)
toggleStatus.BackgroundColor3 = Color3.fromRGB(0, 210, 100)
toggleStatus.BorderSizePixel = 0
toggleStatus.ZIndex = 2
toggleStatus.Parent = toggle

Instance.new("UICorner", toggleStatus).CornerRadius = UDim.new(1, 0)

local toggleRing = Instance.new("UIStroke")
toggleRing.Color = Color3.fromRGB(22, 22, 26)
toggleRing.Thickness = 1.5
toggleRing.Parent = toggleStatus

-- Toggle hover
toggle.MouseEnter:Connect(function()
    TweenService:Create(toggle, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(35, 35, 42), Size = UDim2.new(0, 52, 0, 52)}):Play()
    TweenService:Create(toggle, TweenInfo.new(0.12), {Position = UDim2.new(1, -68, 1, -68)}):Play()
end)
toggle.MouseLeave:Connect(function()
    TweenService:Create(toggle, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(22, 22, 26), Size = UDim2.new(0, 48, 0, 48)}):Play()
    TweenService:Create(toggle, TweenInfo.new(0.12), {Position = UDim2.new(1, -64, 1, -64)}):Play()
end)

-- Close animation
closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    task.wait(0.2)
    frame.Visible = false
    toggle.Visible = true
    toggle.Size = UDim2.new(0, 0, 0, 0)
    toggle.Position = UDim2.new(1, -24, 1, -24)
    TweenService:Create(toggle, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 48, 0, 48),
        Position = UDim2.new(1, -64, 1, -64)
    }):Play()
end)

-- Open animation
toggle.MouseButton1Click:Connect(function()
    toggle.Visible = false
    frame.Visible = true
    frame.Size = UDim2.new(0, 0, 0, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 320, 0, 180),
        Position = UDim2.new(0.5, -160, 0.5, -90)
    }):Play()
end)

-- Initial open
frame.Size = UDim2.new(0, 0, 0, 0)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 320, 0, 180),
    Position = UDim2.new(0.5, -160, 0.5, -90)
}):Play()

print("MIKKA HUB loaded | " .. player.Name)
