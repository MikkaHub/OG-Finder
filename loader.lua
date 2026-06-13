local Players = game:GetService("Players")
local player = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

local leaderstats = player:FindFirstChild("leaderstats") or player:WaitForChild("leaderstats", 5)
if not leaderstats then return end
local sheckles = leaderstats:FindFirstChild("Sheckles") or leaderstats:WaitForChild("Sheckles", 5)
if not sheckles then return end

local old = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("MikkaHub")
if old then old:Destroy() end

local IMAGE_URL = "https://files.catbox.moe/29dya4.png"

local sg = Instance.new("ScreenGui")
sg.Name = "MikkaHub"
sg.ResetOnSpawn = false
sg.Parent = player:WaitForChild("PlayerGui")

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 170)
frame.Position = UDim2.new(0.5, -150, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
frame.BorderSizePixel = 0
frame.Active = true
frame.ClipsDescendants = true
frame.Parent = sg

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(50, 35, 45)
stroke.Thickness = 1
stroke.Transparency = 0.5
stroke.Parent = frame

-- Top accent line
local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.BackgroundColor3 = Color3.fromRGB(180, 90, 130)
accentLine.BorderSizePixel = 0
accentLine.Parent = frame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 38)
header.Position = UDim2.new(0, 0, 0, 2)
header.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
header.BorderSizePixel = 0
header.Parent = frame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 0)
headerCorner.Parent = header

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(1, -50, 1, 0)
headerTitle.Position = UDim2.new(0, 14, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Text = "MIKKA HUB"
headerTitle.TextColor3 = Color3.fromRGB(210, 180, 195)
headerTitle.TextSize = 14
headerTitle.Font = Enum.Font.GothamBold
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -32, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 25)
closeBtn.Text = ""
closeBtn.AutoButtonColor = false
closeBtn.Parent = header

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local closeIcon = Instance.new("TextLabel")
closeIcon.Size = UDim2.new(1, 0, 1, 0)
closeIcon.BackgroundTransparency = 1
closeIcon.Text = "×"
closeIcon.TextColor3 = Color3.fromRGB(140, 100, 115)
closeIcon.TextSize = 18
closeIcon.Font = Enum.Font.GothamBold
closeIcon.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(200, 60, 90)}):Play()
    closeIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30, 20, 25)}):Play()
    closeIcon.TextColor3 = Color3.fromRGB(140, 100, 115)
end)

-- Content area
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 0, 110)
content.Position = UDim2.new(0, 10, 0, 44)
content.BackgroundTransparency = 1
content.Parent = frame

-- Circular logo
local logoFrame = Instance.new("Frame")
logoFrame.Size = UDim2.new(0, 52, 0, 52)
logoFrame.Position = UDim2.new(0, 0, 0, 4)
logoFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
logoFrame.BorderSizePixel = 0
logoFrame.Parent = content

Instance.new("UICorner", logoFrame).CornerRadius = UDim.new(1, 0)

local logoStroke = Instance.new("UIStroke")
logoStroke.Color = Color3.fromRGB(60, 40, 55)
logoStroke.Thickness = 1.5
logoStroke.Parent = logoFrame

local logoImage = Instance.new("ImageLabel")
logoImage.Size = UDim2.new(1, 0, 1, 0)
logoImage.BackgroundTransparency = 1
logoImage.Image = IMAGE_URL
logoImage.ScaleType = Enum.ScaleType.Crop
logoImage.Parent = logoFrame

Instance.new("UICorner", logoImage).CornerRadius = UDim.new(1, 0)

-- Value section
local valueSection = Instance.new("Frame")
valueSection.Size = UDim2.new(1, -64, 0, 60)
valueSection.Position = UDim2.new(0, 64, 0, 0)
valueSection.BackgroundTransparency = 1
valueSection.Parent = content

local valueText = Instance.new("TextLabel")
valueText.Size = UDim2.new(1, 0, 0, 32)
valueText.Position = UDim2.new(0, 0, 0, 8)
valueText.BackgroundTransparency = 1
valueText.Text = tostring(sheckles.Value)
valueText.TextColor3 = Color3.fromRGB(240, 240, 240)
valueText.TextSize = 26
valueText.Font = Enum.Font.GothamBlack
valueText.TextXAlignment = Enum.TextXAlignment.Left
valueText.Parent = valueSection

local valueLabel = Instance.new("TextLabel")
valueLabel.Size = UDim2.new(1, 0, 0, 14)
valueLabel.Position = UDim2.new(0, 0, 0, 38)
valueLabel.BackgroundTransparency = 1
valueLabel.Text = "SHECKLES"
valueLabel.TextColor3 = Color3.fromRGB(110, 90, 105)
valueLabel.TextSize = 10
valueLabel.Font = Enum.Font.Gotham
valueLabel.TextXAlignment = Enum.TextXAlignment.Left
valueLabel.Parent = valueSection

-- Controls row
local controls = Instance.new("Frame")
controls.Size = UDim2.new(1, 0, 0, 34)
controls.Position = UDim2.new(0, 0, 0, 70)
controls.BackgroundTransparency = 1
controls.Parent = content

-- Input
local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(0.42, 0, 0, 30)
inputBox.Position = UDim2.new(0, 0, 0, 2)
inputBox.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
inputBox.Text = "1000"
inputBox.TextColor3 = Color3.fromRGB(200, 200, 200)
inputBox.PlaceholderText = "Amount"
inputBox.PlaceholderColor3 = Color3.fromRGB(70, 70, 75)
inputBox.TextSize = 13
inputBox.Font = Enum.Font.Gotham
inputBox.ClearTextOnFocus = true
inputBox.Parent = controls

Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 8)

local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Color3.fromRGB(45, 40, 50)
inputStroke.Thickness = 1
inputStroke.Parent = inputBox

-- Add button
local addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.new(0.54, 0, 0, 30)
addBtn.Position = UDim2.new(0.46, 0, 0, 2)
addBtn.BackgroundColor3 = Color3.fromRGB(170, 80, 125)
addBtn.Text = "ADD"
addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addBtn.TextSize = 13
addBtn.Font = Enum.Font.GothamBold
addBtn.AutoButtonColor = false
addBtn.Parent = controls

Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 8)

addBtn.MouseEnter:Connect(function()
    TweenService:Create(addBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(200, 100, 150)}):Play()
    inputStroke.Color = Color3.fromRGB(80, 60, 75)
end)
addBtn.MouseLeave:Connect(function()
    TweenService:Create(addBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(170, 80, 125)}):Play()
    inputStroke.Color = Color3.fromRGB(45, 40, 50)
end)

addBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(addBtn, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(140, 60, 100), Size = UDim2.new(0.52, 0, 0, 28)}):Play()
    end
end)
addBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(addBtn, TweenInfo.new(0.12, Enum.EasingStyle.Back), {BackgroundColor3 = Color3.fromRGB(170, 80, 125), Size = UDim2.new(0.54, 0, 0, 30)}):Play()
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

-- Toggle button (circular, professional)
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 44, 0, 44)
toggle.Position = UDim2.new(0, 12, 0.5, -22)
toggle.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
toggle.Text = ""
toggle.AutoButtonColor = false
toggle.Visible = false
toggle.Parent = sg

Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(100, 60, 85)
toggleStroke.Thickness = 1.5
toggleStroke.Parent = toggle

local toggleLogo = Instance.new("ImageLabel")
toggleLogo.Size = UDim2.new(0, 36, 0, 36)
toggleLogo.Position = UDim2.new(0.5, -18, 0.5, -18)
toggleLogo.BackgroundTransparency = 1
toggleLogo.Image = IMAGE_URL
toggleLogo.ScaleType = Enum.ScaleType.Crop
toggleLogo.Parent = toggle

Instance.new("UICorner", toggleLogo).CornerRadius = UDim.new(1, 0)

-- Toggle glow
spawn(function()
    while toggle.Parent do
        TweenService:Create(toggleStroke, TweenInfo.new(2, Enum.EasingStyle.Sine), {Transparency = 0.3}):Play()
        task.wait(2)
        TweenService:Create(toggleStroke, TweenInfo.new(2, Enum.EasingStyle.Sine), {Transparency = 0.7}):Play()
        task.wait(2)
    end
end)

toggle.MouseEnter:Connect(function()
    TweenService:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 25, 35), Size = UDim2.new(0, 48, 0, 48)}):Play()
    TweenService:Create(toggle, TweenInfo.new(0.15), {Position = UDim2.new(0, 10, 0.5, -24)}):Play()
end)

toggle.MouseLeave:Connect(function()
    TweenService:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20, 20, 24), Size = UDim2.new(0, 44, 0, 44)}):Play()
    TweenService:Create(toggle, TweenInfo.new(0.15), {Position = UDim2.new(0, 12, 0.5, -22)}):Play()
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
    toggle.Position = UDim2.new(0, 34, 0.5, 0)
    TweenService:Create(toggle, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0, 12, 0.5, -22)
    }):Play()
end)

toggle.MouseButton1Click:Connect(function()
    toggle.Visible = false
    frame.Visible = true
    frame.Size = UDim2.new(0, 0, 0, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 300, 0, 170),
        Position = UDim2.new(0.5, -150, 0.1, 0)
    }):Play()
end)

-- Open animation
frame.Size = UDim2.new(0, 0, 0, 0)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 300, 0, 170),
    Position = UDim2.new(0.5, -150, 0.1, 0)
}):Play()

print("MIKKA HUB loaded.")
