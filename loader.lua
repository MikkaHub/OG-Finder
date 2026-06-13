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
frame.Size = UDim2.new(0, 300, 0, 170)
frame.Position = UDim2.new(0.5, -150, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
frame.BorderSizePixel = 0
frame.Active = true
frame.ClipsDescendants = true
frame.Parent = sg

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

-- Subtle shadow
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.7
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.ZIndex = -1
shadow.Parent = frame

-- Thin accent line top
local accent = Instance.new("Frame")
accent.Size = UDim2.new(1, 0, 0, 2)
accent.BackgroundColor3 = Color3.fromRGB(160, 90, 130)
accent.BorderSizePixel = 0
accent.Parent = frame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.Position = UDim2.new(0, 0, 0, 2)
header.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
header.BorderSizePixel = 0
header.Parent = frame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = header

-- Avatar in header (small, professional)
local miniAvatar = Instance.new("ImageLabel")
miniAvatar.Size = UDim2.new(0, 26, 0, 26)
miniAvatar.Position = UDim2.new(0, 14, 0, 8)
miniAvatar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
miniAvatar.Image = AVATAR_URL
miniAvatar.ScaleType = Enum.ScaleType.Crop
miniAvatar.Parent = header

Instance.new("UICorner", miniAvatar).CornerRadius = UDim.new(1, 0)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 180, 0, 42)
title.Position = UDim2.new(0, 48, 0, 0)
title.BackgroundTransparency = 1
title.Text = "MIKKA HUB"
title.TextColor3 = Color3.fromRGB(200, 180, 195)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -34, 0, 9)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = ""
closeBtn.AutoButtonColor = false
closeBtn.Parent = header

local closeIcon = Instance.new("TextLabel")
closeIcon.Size = UDim2.new(1, 0, 1, 0)
closeIcon.BackgroundTransparency = 1
closeIcon.Text = "×"
closeIcon.TextColor3 = Color3.fromRGB(120, 110, 120)
closeIcon.TextSize = 18
closeIcon.Font = Enum.Font.GothamBold
closeIcon.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
    closeIcon.TextColor3 = Color3.fromRGB(220, 80, 100)
end)
closeBtn.MouseLeave:Connect(function()
    closeIcon.TextColor3 = Color3.fromRGB(120, 110, 120)
end)

-- Divider
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -28, 0, 1)
divider.Position = UDim2.new(0, 14, 0, 44)
divider.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
divider.BorderSizePixel = 0
divider.Parent = frame

-- Content
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -28, 0, 108)
content.Position = UDim2.new(0, 14, 0, 50)
content.BackgroundTransparency = 1
content.Parent = frame

-- Avatar section (left)
local avatarSection = Instance.new("Frame")
avatarSection.Size = UDim2.new(0, 70, 0, 108)
avatarSection.BackgroundTransparency = 1
avatarSection.Parent = content

-- Main avatar
local avatarFrame = Instance.new("Frame")
avatarFrame.Size = UDim2.new(0, 56, 0, 56)
avatarFrame.Position = UDim2.new(0.5, -28, 0, 8)
avatarFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
avatarFrame.BorderSizePixel = 0
avatarFrame.Parent = avatarSection

Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)

local avatarStroke = Instance.new("UIStroke")
avatarStroke.Color = Color3.fromRGB(80, 70, 85)
avatarStroke.Thickness = 1.5
avatarStroke.Parent = avatarFrame

local avatarImage = Instance.new("ImageLabel")
avatarImage.Size = UDim2.new(1, 0, 1, 0)
avatarImage.BackgroundTransparency = 1
avatarImage.Image = AVATAR_URL
avatarImage.ScaleType = Enum.ScaleType.Crop
avatarImage.Parent = avatarFrame

Instance.new("UICorner", avatarImage).CornerRadius = UDim.new(1, 0)

-- Username below avatar
local username = Instance.new("TextLabel")
username.Size = UDim2.new(1, 0, 0, 16)
username.Position = UDim2.new(0, 0, 0, 70)
username.BackgroundTransparency = 1
username.Text = "@" .. player.Name
username.TextColor3 = Color3.fromRGB(130, 120, 135)
username.TextSize = 10
username.Font = Enum.Font.Gotham
username.TextXAlignment = Enum.TextXAlignment.Center
username.Parent = avatarSection

-- Status indicator
local status = Instance.new("Frame")
status.Size = UDim2.new(0, 8, 0, 8)
status.Position = UDim2.new(1, -14, 1, -14)
status.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
status.BorderSizePixel = 0
status.ZIndex = 2
status.Parent = avatarFrame

Instance.new("UICorner", status).CornerRadius = UDim.new(1, 0)

local statusRing = Instance.new("UIStroke")
statusRing.Color = Color3.fromRGB(20, 20, 24)
statusRing.Thickness = 2
statusRing.Parent = status

-- Value section (right)
local valueSection = Instance.new("Frame")
valueSection.Size = UDim2.new(1, -78, 0, 108)
valueSection.Position = UDim2.new(0, 78, 0, 0)
valueSection.BackgroundTransparency = 1
valueSection.Parent = content

local valueText = Instance.new("TextLabel")
valueText.Size = UDim2.new(1, 0, 0, 38)
valueText.Position = UDim2.new(0, 0, 0, 12)
valueText.BackgroundTransparency = 1
valueText.Text = tostring(sheckles.Value)
valueText.TextColor3 = Color3.fromRGB(240, 240, 240)
valueText.TextSize = 28
valueText.Font = Enum.Font.GothamBlack
valueText.TextXAlignment = Enum.TextXAlignment.Left
valueText.Parent = valueSection

local valueLabel = Instance.new("TextLabel")
valueLabel.Size = UDim2.new(1, 0, 0, 16)
valueLabel.Position = UDim2.new(0, 0, 0, 48)
valueLabel.BackgroundTransparency = 1
valueLabel.Text = "SHECKLES"
valueLabel.TextColor3 = Color3.fromRGB(110, 100, 115)
valueLabel.TextSize = 10
valueLabel.Font = Enum.Font.Gotham
valueLabel.TextXAlignment = Enum.TextXAlignment.Left
valueLabel.Parent = valueSection

-- Accent underline
local underline = Instance.new("Frame")
underline.Size = UDim2.new(0.3, 0, 0, 2)
underline.Position = UDim2.new(0, 0, 0, 66)
underline.BackgroundColor3 = Color3.fromRGB(160, 90, 130)
underline.BorderSizePixel = 0
underline.Parent = valueSection

-- Controls
local controls = Instance.new("Frame")
controls.Size = UDim2.new(1, 0, 0, 30)
controls.Position = UDim2.new(0, 0, 0, 76)
controls.BackgroundTransparency = 1
controls.Parent = valueSection

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(0.4, 0, 0, 28)
inputBox.Position = UDim2.new(0, 0, 0, 1)
inputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
inputBox.Text = "1000"
inputBox.TextColor3 = Color3.fromRGB(200, 200, 200)
inputBox.PlaceholderText = "Amount"
inputBox.PlaceholderColor3 = Color3.fromRGB(70, 70, 75)
inputBox.TextSize = 12
inputBox.Font = Enum.Font.Gotham
inputBox.ClearTextOnFocus = true
inputBox.Parent = controls

Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 8)

local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Color3.fromRGB(50, 50, 55)
inputStroke.Thickness = 1
inputStroke.Parent = inputBox

local addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.new(0.56, 0, 0, 28)
addBtn.Position = UDim2.new(0.44, 0, 0, 1)
addBtn.BackgroundColor3 = Color3.fromRGB(160, 80, 120)
addBtn.Text = "ADD"
addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addBtn.TextSize = 12
addBtn.Font = Enum.Font.GothamBold
addBtn.AutoButtonColor = false
addBtn.Parent = controls

Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 8)

addBtn.MouseEnter:Connect(function()
    TweenService:Create(addBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(190, 100, 150)}):Play()
    inputStroke.Color = Color3.fromRGB(80, 70, 90)
end)
addBtn.MouseLeave:Connect(function()
    TweenService:Create(addBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(160, 80, 120)}):Play()
    inputStroke.Color = Color3.fromRGB(50, 50, 55)
end)

addBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(addBtn, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(130, 60, 100)}):Play()
    end
end)
addBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(addBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(160, 80, 120)}):Play()
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

-- Toggle button (professional, clean)
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 44, 0, 44)
toggle.Position = UDim2.new(0, 14, 0.5, -22)
toggle.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
toggle.Text = ""
toggle.AutoButtonColor = false
toggle.Visible = false
toggle.Parent = sg

Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(80, 70, 85)
toggleStroke.Thickness = 1.5
toggleStroke.Parent = toggle

local toggleAvatar = Instance.new("ImageLabel")
toggleAvatar.Size = UDim2.new(0, 36, 0, 36)
toggleAvatar.Position = UDim2.new(0.5, -18, 0.5, -18)
toggleAvatar.BackgroundTransparency = 1
toggleAvatar.Image = AVATAR_URL
toggleAvatar.ScaleType = Enum.ScaleType.Crop
toggleAvatar.Parent = toggle

Instance.new("UICorner", toggleAvatar).CornerRadius = UDim.new(1, 0)

-- Subtle toggle status
local toggleStatus = Instance.new("Frame")
toggleStatus.Size = UDim2.new(0, 7, 0, 7)
toggleStatus.Position = UDim2.new(1, -10, 1, -10)
toggleStatus.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
toggleStatus.BorderSizePixel = 0
toggleStatus.ZIndex = 2
toggleStatus.Parent = toggle

Instance.new("UICorner", toggleStatus).CornerRadius = UDim.new(1, 0)

local toggleRing = Instance.new("UIStroke")
toggleRing.Color = Color3.fromRGB(20, 20, 24)
toggleRing.Thickness = 1.5
toggleRing.Parent = toggleStatus

toggle.MouseEnter:Connect(function()
    TweenService:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 35, 40), Size = UDim2.new(0, 48, 0, 48)}):Play()
    TweenService:Create(toggle, TweenInfo.new(0.15), {Position = UDim2.new(0, 12, 0.5, -24)}):Play()
end)
toggle.MouseLeave:Connect(function()
    TweenService:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20, 20, 24), Size = UDim2.new(0, 44, 0, 44)}):Play()
    TweenService:Create(toggle, TweenInfo.new(0.15), {Position = UDim2.new(0, 14, 0.5, -22)}):Play()
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
    toggle.Position = UDim2.new(0, 36, 0.5, 0)
    TweenService:Create(toggle, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0, 14, 0.5, -22)
    }):Play()
end)

toggle.MouseButton1Click:Connect(function()
    toggle.Visible = false
    frame.Visible = true
    frame.Size = UDim2.new(0, 0, 0, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 300, 0, 170),
        Position = UDim2.new(0.5, -150, 0.1, 0)
    }):Play()
end)

-- Open animation
frame.Size = UDim2.new(0, 0, 0, 0)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 300, 0, 170),
    Position = UDim2.new(0.5, -150, 0.1, 0)
}):Play()

print("MIKKA HUB loaded | " .. player.Name)
