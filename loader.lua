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
frame.Size = UDim2.new(0, 340, 0, 190)
frame.Position = UDim2.new(0.5, -170, 0.5, -95)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
frame.BorderSizePixel = 0
frame.Active = true
frame.ClipsDescendants = true
frame.Parent = sg

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

-- FULL AMBIENT GLOW around entire GUI
local glowBack = Instance.new("ImageLabel")
glowBack.Name = "GlowBack"
glowBack.Size = UDim2.new(1, 60, 1, 60)
glowBack.Position = UDim2.new(0, -30, 0, -30)
glowBack.BackgroundTransparency = 1
glowBack.Image = "rbxassetid://1316045217"
glowBack.ImageColor3 = Color3.fromRGB(220, 100, 170)
glowBack.ImageTransparency = 0.55
glowBack.ScaleType = Enum.ScaleType.Slice
glowBack.SliceCenter = Rect.new(10, 10, 118, 118)
glowBack.ZIndex = -3
glowBack.Parent = frame

local glowMid = Instance.new("ImageLabel")
glowMid.Name = "GlowMid"
glowMid.Size = UDim2.new(1, 40, 1, 40)
glowMid.Position = UDim2.new(0, -20, 0, -20)
glowMid.BackgroundTransparency = 1
glowMid.Image = "rbxassetid://1316045217"
glowMid.ImageColor3 = Color3.fromRGB(200, 90, 160)
glowMid.ImageTransparency = 0.65
glowMid.ScaleType = Enum.ScaleType.Slice
glowMid.SliceCenter = Rect.new(10, 10, 118, 118)
glowMid.ZIndex = -2
glowMid.Parent = frame

local glowFront = Instance.new("ImageLabel")
glowFront.Name = "GlowFront"
glowFront.Size = UDim2.new(1, 20, 1, 20)
glowFront.Position = UDim2.new(0, -10, 0, -10)
glowFront.BackgroundTransparency = 1
glowFront.Image = "rbxassetid://1316045217"
glowFront.ImageColor3 = Color3.fromRGB(220, 110, 180)
glowFront.ImageTransparency = 0.75
glowFront.ScaleType = Enum.ScaleType.Slice
glowFront.SliceCenter = Rect.new(10, 10, 118, 118)
glowFront.ZIndex = -1
glowFront.Parent = frame

-- Animate glow breathing effect
spawn(function()
    while frame.Parent do
        TweenService:Create(glowBack, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.5}):Play()
        TweenService:Create(glowMid, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.6}):Play()
        TweenService:Create(glowFront, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.7}):Play()
        task.wait(2)
        TweenService:Create(glowBack, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.6}):Play()
        TweenService:Create(glowMid, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.7}):Play()
        TweenService:Create(glowFront, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.8}):Play()
        task.wait(2)
    end
end)
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
shadow.ZIndex = -2
shadow.Parent = frame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
header.BorderSizePixel = 0
header.ZIndex = 1
header.Parent = frame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = header

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 20)
headerFix.Position = UDim2.new(0, 0, 0.5, 0)
headerFix.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
headerFix.BorderSizePixel = 0
headerFix.ZIndex = 1
headerFix.Parent = header

-- Avatar in header
local miniAvatar = Instance.new("ImageLabel")
miniAvatar.Size = UDim2.new(0, 30, 0, 30)
miniAvatar.Position = UDim2.new(0, 14, 0, 10)
miniAvatar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
miniAvatar.Image = AVATAR_URL
miniAvatar.ScaleType = Enum.ScaleType.Crop
miniAvatar.ZIndex = 2
miniAvatar.Parent = header

Instance.new("UICorner", miniAvatar).CornerRadius = UDim.new(1, 0)

local miniStroke = Instance.new("UIStroke")
miniStroke.Color = Color3.fromRGB(70, 60, 75)
miniStroke.Thickness = 1.5
miniStroke.ZIndex = 2
miniStroke.Parent = miniAvatar

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 200, 0, 50)
title.Position = UDim2.new(0, 52, 0, 0)
title.BackgroundTransparency = 1
title.Text = "MIKKA HUB"
title.TextColor3 = Color3.fromRGB(220, 200, 215)
title.TextSize = 16
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 2
title.Parent = header

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0, 11)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 25, 30)
closeBtn.Text = ""
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 2
closeBtn.Parent = header

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local closeIcon = Instance.new("TextLabel")
closeIcon.Size = UDim2.new(1, 0, 1, 0)
closeIcon.BackgroundTransparency = 1
closeIcon.Text = "×"
closeIcon.TextColor3 = Color3.fromRGB(160, 120, 135)
closeIcon.TextSize = 20
closeIcon.Font = Enum.Font.GothamBold
closeIcon.ZIndex = 3
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
content.Size = UDim2.new(1, -24, 0, 126)
content.Position = UDim2.new(0, 12, 0, 52)
content.BackgroundTransparency = 1
content.ZIndex = 1
content.Parent = frame

-- Left: Avatar with bounce + spin ring
local leftSection = Instance.new("Frame")
leftSection.Size = UDim2.new(0, 90, 1, 0)
leftSection.BackgroundTransparency = 1
leftSection.ZIndex = 1
leftSection.Parent = content

local avatarFrame = Instance.new("Frame")
avatarFrame.Size = UDim2.new(0, 68, 0, 68)
avatarFrame.Position = UDim2.new(0.5, -34, 0, 8)
avatarFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
avatarFrame.BorderSizePixel = 0
avatarFrame.ZIndex = 1
avatarFrame.Parent = leftSection

Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)

local avatarStroke = Instance.new("UIStroke")
avatarStroke.Color = Color3.fromRGB(100, 80, 115)
avatarStroke.Thickness = 2
avatarStroke.ZIndex = 1
avatarStroke.Parent = avatarFrame

-- Bounce animation
spawn(function()
    while avatarFrame.Parent do
        TweenService:Create(avatarFrame, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Position = UDim2.new(0.5, -34, 0, 6)}):Play()
        task.wait(1.5)
        TweenService:Create(avatarFrame, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Position = UDim2.new(0.5, -34, 0, 10)}):Play()
        task.wait(1.5)
    end
end)

-- Avatar image
local avatarImage = Instance.new("ImageLabel")
avatarImage.Size = UDim2.new(1, 0, 1, 0)
avatarImage.BackgroundTransparency = 1
avatarImage.Image = AVATAR_URL
avatarImage.ScaleType = Enum.ScaleType.Crop
avatarImage.ZIndex = 1
avatarImage.Parent = avatarFrame

Instance.new("UICorner", avatarImage).CornerRadius = UDim.new(1, 0)

-- Hover scale
avatarFrame.MouseEnter:Connect(function()
    TweenService:Create(avatarFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 72, 0, 72), Position = UDim2.new(0.5, -36, 0, 6)}):Play()
    TweenService:Create(avatarStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(220, 120, 180)}):Play()
end)
avatarFrame.MouseLeave:Connect(function()
    TweenService:Create(avatarFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 68, 0, 68), Position = UDim2.new(0.5, -34, 0, 8)}):Play()
    TweenService:Create(avatarStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(100, 80, 115)}):Play()
end)

local username = Instance.new("TextLabel")
username.Size = UDim2.new(1, 0, 0, 18)
username.Position = UDim2.new(0, 0, 0, 94)
username.BackgroundTransparency = 1
username.Text = "@" .. player.Name
username.TextColor3 = Color3.fromRGB(130, 120, 135)
username.TextSize = 11
username.Font = Enum.Font.Gotham
username.TextXAlignment = Enum.TextXAlignment.Center
username.ZIndex = 1
username.Parent = leftSection

-- Right: Number Display
local rightSection = Instance.new("Frame")
rightSection.Size = UDim2.new(1, -98, 1, 0)
rightSection.Position = UDim2.new(0, 98, 0, 0)
rightSection.BackgroundTransparency = 1
rightSection.ZIndex = 1
rightSection.Parent = content

-- Number card
local numberCard = Instance.new("Frame")
numberCard.Size = UDim2.new(1, 0, 0, 70)
numberCard.Position = UDim2.new(0, 0, 0, 6)
numberCard.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
numberCard.BorderSizePixel = 0
numberCard.ZIndex = 1
numberCard.Parent = rightSection

Instance.new("UICorner", numberCard).CornerRadius = UDim.new(0, 12)

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = Color3.fromRGB(50, 45, 55)
cardStroke.Thickness = 1
cardStroke.ZIndex = 1
cardStroke.Parent = numberCard

-- Big number
local valueText = Instance.new("TextLabel")
valueText.Size = UDim2.new(1, -16, 0, 40)
valueText.Position = UDim2.new(0, 10, 0, 8)
valueText.BackgroundTransparency = 1
valueText.Text = tostring(sheckles.Value)
valueText.TextColor3 = Color3.fromRGB(255, 255, 255)
valueText.TextSize = 32
valueText.Font = Enum.Font.GothamBlack
valueText.TextXAlignment = Enum.TextXAlignment.Left
valueText.ZIndex = 2
valueText.Parent = numberCard

local valueLabel = Instance.new("TextLabel")
valueLabel.Size = UDim2.new(1, -16, 0, 16)
valueLabel.Position = UDim2.new(0, 10, 0, 46)
valueLabel.BackgroundTransparency = 1
valueLabel.Text = "SHECKLES"
valueLabel.TextColor3 = Color3.fromRGB(150, 130, 145)
valueLabel.TextSize = 10
valueLabel.Font = Enum.Font.GothamBold
valueLabel.TextXAlignment = Enum.TextXAlignment.Left
valueLabel.ZIndex = 2
valueLabel.Parent = numberCard

-- Controls
local controls = Instance.new("Frame")
controls.Size = UDim2.new(1, 0, 0, 36)
controls.Position = UDim2.new(0, 0, 0, 84)
controls.BackgroundTransparency = 1
controls.ZIndex = 1
controls.Parent = rightSection

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(0.4, 0, 0, 32)
inputBox.Position = UDim2.new(0, 0, 0, 2)
inputBox.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
inputBox.Text = "1000"
inputBox.TextColor3 = Color3.fromRGB(200, 200, 205)
inputBox.PlaceholderText = "Amount"
inputBox.PlaceholderColor3 = Color3.fromRGB(70, 70, 75)
inputBox.TextSize = 13
inputBox.Font = Enum.Font.Gotham
inputBox.ClearTextOnFocus = true
inputBox.ZIndex = 2
inputBox.Parent = controls

Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 10)

local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Color3.fromRGB(50, 50, 55)
inputStroke.Thickness = 1
inputStroke.ZIndex = 2
inputStroke.Parent = inputBox

local addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.new(0.56, 0, 0, 32)
addBtn.Position = UDim2.new(0.44, 0, 0, 2)
addBtn.BackgroundColor3 = Color3.fromRGB(175, 85, 130)
addBtn.Text = "ADD"
addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addBtn.TextSize = 13
addBtn.Font = Enum.Font.GothamBold
addBtn.AutoButtonColor = false
addBtn.ZIndex = 2
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

-- TOGGLE - Bottom Left
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 52, 0, 52)
toggle.Position = UDim2.new(0, 20, 1, -72)
toggle.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
toggle.Text = ""
toggle.AutoButtonColor = false
toggle.Visible = false
toggle.Parent = sg

Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(80, 70, 90)
toggleStroke.Thickness = 2
toggleStroke.Parent = toggle

-- Toggle ambient glow
local toggleGlowBack = Instance.new("ImageLabel")
toggleGlowBack.Name = "ToggleGlowBack"
toggleGlowBack.Size = UDim2.new(1, 20, 1, 20)
toggleGlowBack.Position = UDim2.new(0, -10, 0, -10)
toggleGlowBack.BackgroundTransparency = 1
toggleGlowBack.Image = "rbxassetid://1316045217"
toggleGlowBack.ImageColor3 = Color3.fromRGB(220, 100, 170)
toggleGlowBack.ImageTransparency = 0.5
toggleGlowBack.ScaleType = Enum.ScaleType.Slice
toggleGlowBack.SliceCenter = Rect.new(10, 10, 118, 118)
toggleGlowBack.ZIndex = -1
toggleGlowBack.Parent = toggle

local toggleGlowFront = Instance.new("ImageLabel")
toggleGlowFront.Name = "ToggleGlowFront"
toggleGlowFront.Size = UDim2.new(1, 10, 1, 10)
toggleGlowFront.Position = UDim2.new(0, -5, 0, -5)
toggleGlowFront.BackgroundTransparency = 1
toggleGlowFront.Image = "rbxassetid://1316045217"
toggleGlowFront.ImageColor3 = Color3.fromRGB(200, 90, 160)
toggleGlowFront.ImageTransparency = 0.65
toggleGlowFront.ScaleType = Enum.ScaleType.Slice
toggleGlowFront.SliceCenter = Rect.new(10, 10, 118, 118)
toggleGlowFront.ZIndex = -1
toggleGlowFront.Parent = toggle

-- Animate toggle glow breathing
spawn(function()
    while toggle.Parent do
        TweenService:Create(toggleGlowBack, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.4}):Play()
        TweenService:Create(toggleGlowFront, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.55}):Play()
        task.wait(1.5)
        TweenService:Create(toggleGlowBack, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.55}):Play()
        TweenService:Create(toggleGlowFront, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.7}):Play()
        task.wait(1.5)
    end
end)
toggleAvatar.Size = UDim2.new(0, 42, 0, 42)
toggleAvatar.Position = UDim2.new(0.5, -21, 0.5, -21)
toggleAvatar.BackgroundTransparency = 1
toggleAvatar.Image = AVATAR_URL
toggleAvatar.ScaleType = Enum.ScaleType.Crop
toggleAvatar.ZIndex = 1
toggleAvatar.Parent = toggle

Instance.new("UICorner", toggleAvatar).CornerRadius = UDim.new(1, 0)

local toggleStatus = Instance.new("Frame")
toggleStatus.Size = UDim2.new(0, 10, 0, 10)
toggleStatus.Position = UDim2.new(1, -13, 1, -13)
toggleStatus.BackgroundColor3 = Color3.fromRGB(0, 210, 100)
toggleStatus.BorderSizePixel = 0
toggleStatus.ZIndex = 2
toggleStatus.Parent = toggle

Instance.new("UICorner", toggleStatus).CornerRadius = UDim.new(1, 0)

local toggleRing = Instance.new("UIStroke")
toggleRing.Color = Color3.fromRGB(22, 22, 26)
toggleRing.Thickness = 2
toggleRing.Parent = toggleStatus

toggle.MouseEnter:Connect(function()
    TweenService:Create(toggle, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(35, 35, 42), Size = UDim2.new(0, 56, 0, 56)}):Play()
    TweenService:Create(toggle, TweenInfo.new(0.12), {Position = UDim2.new(0, 18, 1, -76)}):Play()
end)
toggle.MouseLeave:Connect(function()
    TweenService:Create(toggle, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(22, 22, 26), Size = UDim2.new(0, 52, 0, 52)}):Play()
    TweenService:Create(toggle, TweenInfo.new(0.12), {Position = UDim2.new(0, 20, 1, -72)}):Play()
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
    toggle.Position = UDim2.new(0, 46, 1, -26)
    TweenService:Create(toggle, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 52, 0, 52),
        Position = UDim2.new(0, 20, 1, -72)
    }):Play()
end)

-- Open animation
toggle.MouseButton1Click:Connect(function()
    toggle.Visible = false
    frame.Visible = true
    frame.Size = UDim2.new(0, 0, 0, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 340, 0, 190),
        Position = UDim2.new(0.5, -170, 0.5, -95)
    }):Play()
end)

-- Initial open
frame.Size = UDim2.new(0, 0, 0, 0)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 340, 0, 190),
    Position = UDim2.new(0.5, -170, 0.5, -95)
}):Play()

print("MIKKA HUB loaded | " .. player.Name)
