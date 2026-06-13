local Players = game:GetService("Players")
local player = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

local leaderstats = player:FindFirstChild("leaderstats") or player:WaitForChild("leaderstats", 5)
if not leaderstats then return end
local sheckles = leaderstats:FindFirstChild("Sheckles") or leaderstats:WaitForChild("Sheckles", 5)
if not sheckles then return end

local old = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("MikkaHub")
if old then old:Destroy() end

-- IMAGE SETUP - Try multiple methods
local IMAGE_URL = "https://files.catbox.moe/29dya4.png"
local imageLoaded = false

local sg = Instance.new("ScreenGui")
sg.Name = "MikkaHub"
sg.ResetOnSpawn = false
sg.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 160)
frame.Position = UDim2.new(0.5, -140, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(18, 16, 22)
frame.BorderSizePixel = 0
frame.Active = true
frame.ClipsDescendants = true
frame.Parent = sg

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

local glow = Instance.new("UIStroke")
glow.Color = Color3.fromRGB(120, 60, 100)
glow.Thickness = 1.5
glow.Transparency = 0.4
glow.Parent = frame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(28, 20, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 16)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 20)
titleFix.Position = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = Color3.fromRGB(28, 20, 30)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 80, 140)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 150, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 80, 140))
})
titleGradient.Parent = titleBar

spawn(function()
    while titleBar.Parent do
        TweenService:Create(titleGradient, TweenInfo.new(3, Enum.EasingStyle.Linear), {Rotation = titleGradient.Rotation + 180}):Play()
        task.wait(3)
    end
end)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -60, 1, 0)
titleText.Position = UDim2.new(0, 16, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "MIKKA HUB"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 16
titleText.Font = Enum.Font.GothamBlack
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local titleShadow = Instance.new("TextLabel")
titleShadow.Size = titleText.Size
titleShadow.Position = UDim2.new(0, 17, 0, 1)
titleShadow.BackgroundTransparency = 1
titleShadow.Text = "MIKKA HUB"
titleShadow.TextColor3 = Color3.fromRGB(0, 0, 0)
titleShadow.TextTransparency = 0.5
titleShadow.TextSize = 16
titleShadow.Font = Enum.Font.GothamBlack
titleShadow.TextXAlignment = Enum.TextXAlignment.Left
titleShadow.ZIndex = titleText.ZIndex - 1
titleShadow.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(35, 20, 25)
closeBtn.Text = ""
closeBtn.AutoButtonColor = false
closeBtn.Parent = titleBar

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

local closeIcon = Instance.new("TextLabel")
closeIcon.Size = UDim2.new(1, 0, 1, 0)
closeIcon.BackgroundTransparency = 1
closeIcon.Text = "×"
closeIcon.TextColor3 = Color3.fromRGB(220, 140, 160)
closeIcon.TextSize = 22
closeIcon.Font = Enum.Font.GothamBold
closeIcon.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(220, 60, 90)}):Play()
    closeIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 20, 25)}):Play()
    closeIcon.TextColor3 = Color3.fromRGB(220, 140, 160)
end)

-- CIRCULAR LOGO IN GUI
local logoFrame = Instance.new("Frame")
logoFrame.Size = UDim2.new(0, 56, 0, 56)
logoFrame.Position = UDim2.new(0, 14, 0, 48)
logoFrame.BackgroundColor3 = Color3.fromRGB(160, 80, 120)
logoFrame.BorderSizePixel = 0
logoFrame.Parent = frame

Instance.new("UICorner", logoFrame).CornerRadius = UDim.new(1, 0)

local logoGlow = Instance.new("UIStroke")
logoGlow.Color = Color3.fromRGB(200, 100, 150)
logoGlow.Thickness = 2
logoGlow.Parent = logoFrame

local logoImage = Instance.new("ImageLabel")
logoImage.Name = "LogoImage"
logoImage.Size = UDim2.new(1, 0, 1, 0)
logoImage.BackgroundTransparency = 1
logoImage.ScaleType = Enum.ScaleType.Crop
logoImage.Image = IMAGE_URL
logoImage.Parent = logoFrame

Instance.new("UICorner", logoImage).CornerRadius = UDim.new(1, 0)

-- Loading indicator
local loadingSpinner = Instance.new("Frame")
loadingSpinner.Size = UDim2.new(0, 20, 0, 20)
loadingSpinner.Position = UDim2.new(0.5, -10, 0.5, -10)
loadingSpinner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
loadingSpinner.BackgroundTransparency = 0.5
loadingSpinner.BorderSizePixel = 0
loadingSpinner.Parent = logoFrame

Instance.new("UICorner", loadingSpinner).CornerRadius = UDim.new(1, 0)

-- Spinner animation
spawn(function()
    while loadingSpinner.Parent do
        TweenService:Create(loadingSpinner, TweenInfo.new(0.5), {Rotation = loadingSpinner.Rotation + 180}):Play()
        task.wait(0.5)
    end
end)

-- IMAGE LOADING SYSTEM
spawn(function()
    local attempts = 0
    local maxAttempts = 5
    
    while attempts < maxAttempts do
        attempts = attempts + 1
        task.wait(1)
        
        if logoImage.IsLoaded then
            imageLoaded = true
            loadingSpinner:Destroy()
            print("Image loaded successfully!")
            break
        else
            print("Attempt " .. attempts .. " failed, retrying...")
            -- Force reload by resetting image
            logoImage.Image = ""
            task.wait(0.1)
            logoImage.Image = IMAGE_URL
        end
    end
    
    if not imageLoaded then
        loadingSpinner:Destroy()
        print("All attempts failed. Image URL may be blocked.")
    end
end)

local display = Instance.new("TextLabel")
display.Size = UDim2.new(1, -86, 0, 36)
display.Position = UDim2.new(0, 82, 0, 52)
display.BackgroundTransparency = 1
display.Text = tostring(sheckles.Value)
display.TextColor3 = Color3.fromRGB(245, 245, 245)
display.TextSize = 28
display.Font = Enum.Font.GothamBlack
display.TextXAlignment = Enum.TextXAlignment.Left
display.Parent = frame

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, -86, 0, 16)
sub.Position = UDim2.new(0, 82, 0, 84)
sub.BackgroundTransparency = 1
sub.Text = "SHECKLES"
sub.TextColor3 = Color3.fromRGB(140, 110, 125)
sub.TextSize = 11
sub.Font = Enum.Font.Gotham
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = frame

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(0.44, 0, 0, 32)
inputBox.Position = UDim2.new(0.05, 0, 0, 116)
inputBox.BackgroundColor3 = Color3.fromRGB(32, 30, 38)
inputBox.Text = "1000"
inputBox.TextColor3 = Color3.fromRGB(230, 230, 230)
inputBox.PlaceholderText = "Amount"
inputBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 90)
inputBox.TextSize = 14
inputBox.Font = Enum.Font.GothamBold
inputBox.ClearTextOnFocus = true
inputBox.Parent = frame

Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 10)

local addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.new(0.46, 0, 0, 32)
addBtn.Position = UDim2.new(0.51, 0, 0, 116)
addBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 130)
addBtn.Text = "ADD"
addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addBtn.TextSize = 14
addBtn.Font = Enum.Font.GothamBlack
addBtn.AutoButtonColor = false
addBtn.Parent = frame

Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 10)

addBtn.MouseEnter:Connect(function()
    TweenService:Create(addBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(210, 100, 160)}):Play()
end)
addBtn.MouseLeave:Connect(function()
    TweenService:Create(addBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(180, 80, 130)}):Play()
end)

addBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(addBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(150, 60, 110), Size = UDim2.new(0.44, 0, 0, 30)}):Play()
    end
end)
addBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(addBtn, TweenInfo.new(0.15, Enum.EasingStyle.Back), {BackgroundColor3 = Color3.fromRGB(180, 80, 130), Size = UDim2.new(0.46, 0, 0, 32)}):Play()
    end
end)

local function addSheckles(amount)
    amount = tonumber(amount) or 1000
    local target = sheckles.Value + amount
    TweenService:Create(display, TweenInfo.new(0.2), {TextTransparency = 0.4}):Play()
    task.wait(0.12)
    sheckles.Value = target
    display.Text = tostring(target)
    TweenService:Create(display, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
end

addBtn.MouseButton1Click:Connect(function()
    addSheckles(inputBox.Text)
end)

sheckles.Changed:Connect(function(newVal)
    display.Text = tostring(newVal)
end)

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

-- TOGGLE BUTTON - CIRCULAR LOGO
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 50, 0, 50)
toggle.Position = UDim2.new(0, 14, 0.5, -25)
toggle.BackgroundColor3 = Color3.fromRGB(160, 80, 120)
toggle.Text = ""
toggle.AutoButtonColor = false
toggle.Visible = false
toggle.Parent = sg

Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(200, 100, 150)
toggleStroke.Thickness = 2
toggleStroke.Parent = toggle

local toggleLogo = Instance.new("ImageLabel")
toggleLogo.Name = "ToggleLogo"
toggleLogo.Size = UDim2.new(0, 40, 0, 40)
toggleLogo.Position = UDim2.new(0.5, -20, 0.5, -20)
toggleLogo.BackgroundTransparency = 1
toggleLogo.ScaleType = Enum.ScaleType.Crop
toggleLogo.Image = IMAGE_URL
toggleLogo.Parent = toggle

Instance.new("UICorner", toggleLogo).CornerRadius = UDim.new(1, 0)

-- Toggle loading spinner
local toggleSpinner = Instance.new("Frame")
toggleSpinner.Size = UDim2.new(0, 16, 0, 16)
toggleSpinner.Position = UDim2.new(0.5, -8, 0.5, -8)
toggleSpinner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
toggleSpinner.BackgroundTransparency = 0.5
toggleSpinner.BorderSizePixel = 0
toggleSpinner.Parent = toggle

Instance.new("UICorner", toggleSpinner).CornerRadius = UDim.new(1, 0)

spawn(function()
    while toggleSpinner.Parent do
        TweenService:Create(toggleSpinner, TweenInfo.new(0.5), {Rotation = toggleSpinner.Rotation + 180}):Play()
        task.wait(0.5)
    end
end)

-- Toggle image loading
spawn(function()
    local attempts = 0
    while attempts < 5 do
        attempts = attempts + 1
        task.wait(1)
        if toggleLogo.IsLoaded then
            toggleSpinner:Destroy()
            break
        else
            toggleLogo.Image = ""
            task.wait(0.1)
            toggleLogo.Image = IMAGE_URL
        end
    end
    if not toggleLogo.IsLoaded then
        toggleSpinner:Destroy()
    end
end)

-- Toggle glow animation
spawn(function()
    while toggle.Parent do
        TweenService:Create(toggleStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Transparency = 0.2}):Play()
        task.wait(1.5)
        TweenService:Create(toggleStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Transparency = 0.6}):Play()
        task.wait(1.5)
    end
end)

toggle.MouseEnter:Connect(function()
    TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(180, 100, 140), Size = UDim2.new(0, 54, 0, 54)}):Play()
    TweenService:Create(toggle, TweenInfo.new(0.2), {Position = UDim2.new(0, 12, 0.5, -27)}):Play()
end)

toggle.MouseLeave:Connect(function()
    TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(160, 80, 120), Size = UDim2.new(0, 50, 0, 50)}):Play()
    TweenService:Create(toggle, TweenInfo.new(0.2), {Position = UDim2.new(0, 14, 0.5, -25)}):Play()
end)

closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    task.wait(0.3)
    frame.Visible = false
    toggle.Visible = true
    toggle.Size = UDim2.new(0, 0, 0, 0)
    toggle.Position = UDim2.new(0, 39, 0.5, 0)
    TweenService:Create(toggle, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0, 14, 0.5, -25)
    }):Play()
end)

toggle.MouseButton1Click:Connect(function()
    toggle.Visible = false
    frame.Visible = true
    frame.Size = UDim2.new(0, 0, 0, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 280, 0, 160),
        Position = UDim2.new(0.5, -140, 0.1, 0)
    }):Play()
end)

frame.Size = UDim2.new(0, 0, 0, 0)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 280, 0, 160),
    Position = UDim2.new(0.5, -140, 0.1, 0)
}):Play()

print("MIKKA HUB loaded. Image URL: " .. IMAGE_URL)
