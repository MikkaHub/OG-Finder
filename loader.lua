-- ═══════════════════════════════════════════════════════════════
--  GAG 2 - PET SPAWNER (Delta Executor)
--  Spawns visible pets with working animations, on ground or flying
--  Path: ReplicatedStorage.Assets.Pets
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- ═══════════════════════════════════════════════════════════════
--  CONFIG
-- ═══════════════════════════════════════════════════════════════

local CONFIG = {
    PetFolderPath = {"Assets", "Pets"},
    FollowDistance = 3.5,
    GroundOffset = 0.5,    -- slightly above ground
    FlyHeight = 4,
    FollowSmoothness = 0.1,
    BobSpeed = 2,
    BobAmount = 0.3,
    MaxPets = 10,
}

-- ═══════════════════════════════════════════════════════════════
--  GET PET FOLDER
-- ═══════════════════════════════════════════════════════════════

local PetFolder = ReplicatedStorage
for _, folderName in ipairs(CONFIG.PetFolderPath) do
    PetFolder = PetFolder:FindFirstChild(folderName)
    if not PetFolder then
        warn("❌ Path broken at:", folderName)
        return
    end
end

print("✅ Found pet folder:", PetFolder:GetFullName())

-- ═══════════════════════════════════════════════════════════════
--  FLYING PETS
-- ═══════════════════════════════════════════════════════════════

local FLYING_PETS = {
    ["Dragonfly"] = true,
    ["Golden Dragonfly"] = true,
    ["Bee"] = true,
    ["Firefly"] = true,
    ["Butterfly"] = true,
    ["Moth"] = true,
}

local function IsFlyingPet(petName)
    return FLYING_PETS[petName] == true
end

-- ═══════════════════════════════════════════════════════════════
--  GET ALL PETS
-- ═══════════════════════════════════════════════════════════════

local function GetAllPets()
    local pets = {}
    for _, template in ipairs(PetFolder:GetChildren()) do
        if template:IsA("Model") then
            table.insert(pets, template.Name)
        end
    end
    table.sort(pets)
    return pets
end

-- ═══════════════════════════════════════════════════════════════
--  SPAWNED PETS TRACKER
-- ═══════════════════════════════════════════════════════════════

local SpawnedPets = {}

-- ═══════════════════════════════════════════════════════════════
--  GET GROUND HEIGHT
-- ═══════════════════════════════════════════════════════════════

local function GetGroundHeight(position)
    local rayOrigin = position + Vector3.new(0, 50, 0)
    local rayDirection = Vector3.new(0, -100, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local filterList = {}
    for _, petData in ipairs(SpawnedPets) do
        if petData.Model then
            table.insert(filterList, petData.Model)
        end
    end
    if player.Character then
        table.insert(filterList, player.Character)
    end
    raycastParams.FilterDescendantsInstances = filterList
    
    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if result then
        return result.Position.Y
    end
    return position.Y - 3
end

-- ═══════════════════════════════════════════════════════════════
--  CLONE PET - ANCHORED INITIALLY
-- ═══════════════════════════════════════════════════════════════

local function ClonePet(petName)
    local template = PetFolder:FindFirstChild(petName)
    if not template then
        warn("❌ Pet not found:", petName)
        return nil
    end

    local clone = template:Clone()

    -- Restore PrimaryPart
    if template.PrimaryPart then
        local pp = clone:FindFirstChild(template.PrimaryPart.Name)
        if pp then
            clone.PrimaryPart = pp
        end
    end

    -- Setup all parts - ANCHORED first so they don't fall
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true        -- ANCHORED = stays put
            part.CanCollide = false
            part.CanQuery = false
            
            if part.Transparency >= 1 then
                part.Transparency = 0
            end
            
            if part.Material == Enum.Material.ForceField then
                part.Material = Enum.Material.SmoothPlastic
            end
        end
        
        -- Fix Motor6D
        if part:IsA("Motor6D") then
            local p0 = clone:FindFirstChild(part.Part0 and part.Part0.Name or "")
            local p1 = clone:FindFirstChild(part.Part1 and part.Part1.Name or "")
            if p0 and p1 then
                part.Part0 = p0
                part.Part1 = p1
            end
        end
        
        -- Fix welds
        if part:IsA("Weld") or part:IsA("ManualWeld") then
            local p0 = clone:FindFirstChild(part.Part0 and part.Part0.Name or "")
            local p1 = clone:FindFirstChild(part.Part1 and part.Part1.Name or "")
            if p0 and p1 then
                part.Part0 = p0
                part.Part1 = p1
            end
        end
        
        -- Fix decals
        if part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 0
        end
    end

    clone:SetAttribute("IsPet", true)
    clone:SetAttribute("PetName", petName)
    
    return clone
end

-- ═══════════════════════════════════════════════════════════════
--  ANIMATIONS - WORK WITH ANCHORED PARTS (use PivotTo for fake anim)
-- ═══════════════════════════════════════════════════════════════

local function StartAnimations(pet, petName)
    -- Check for Animation part
    local animPart = pet:FindFirstChild("Animation")
    local animController = pet:FindFirstChildOfClass("AnimationController")
    
    if not animController then
        animController = Instance.new("AnimationController")
        animController.Parent = pet
    end
    
    task.wait(0.05) -- let controller init
    
    local playedAny = false
    
    -- Try Animation part first
    if animPart then
        for _, child in ipairs(animPart:GetDescendants()) do
            if child:IsA("Animation") and child.AnimationId ~= "" then
                local success, track = pcall(function()
                    return animController:LoadAnimation(child)
                end)
                if success and track then
                    track.Looped = true
                    track.Priority = Enum.AnimationPriority.Action
                    track:Play()
                    playedAny = true
                    print("▶ AnimPart:", child.Name)
                end
            end
        end
        
        for _, child in ipairs(animPart:GetChildren()) do
            if child:IsA("Animation") and child.AnimationId ~= "" then
                local success, track = pcall(function()
                    return animController:LoadAnimation(child)
                end)
                if success and track then
                    track.Looped = true
                    track.Priority = Enum.AnimationPriority.Action
                    track:Play()
                    playedAny = true
                    print("▶ Direct:", child.Name)
                end
            end
        end
    end
    
    -- Search entire pet
    if not playedAny then
        for _, desc in ipairs(pet:GetDescendants()) do
            if desc:IsA("Animation") and desc.AnimationId ~= "" then
                local success, track = pcall(function()
                    return animController:LoadAnimation(desc)
                end)
                if success and track then
                    track.Looped = true
                    track.Priority = Enum.AnimationPriority.Action
                    track:Play()
                    playedAny = true
                    print("▶ Deep:", desc.Name)
                end
            end
        end
    end
    
    -- Animate script
    local animate = pet:FindFirstChild("Animate")
    if animate and animate:IsA("Script") then
        local animateClone = animate:Clone()
        animate:Destroy()
        animateClone.Parent = pet
        animateClone.Disabled = false
        print("▶ Script")
        playedAny = true
    end
    
    -- If still no animation, do manual bob as fake animation
    if not playedAny then
        print("⚠ No anims, using manual bob for", petName)
    end
    
    return playedAny
end

-- ═══════════════════════════════════════════════════════════════
--  FOLLOW SYSTEM
-- ═══════════════════════════════════════════════════════════════

local function FollowPlayer(pet, petName)
    local isFlying = IsFlyingPet(petName)
    local time = 0
    local followConn
    local bobConn

    followConn = RunService.Heartbeat:Connect(function(dt)
        if not pet or not pet.Parent then
            if followConn then followConn:Disconnect() end
            if bobConn then bobConn:Disconnect() end
            return
        end

        local char = player.Character
        if not char then return end

        local currentHRP = char:FindFirstChild("HumanoidRootPart")
        if not currentHRP then return end

        -- Find pet index
        local petIndex = 0
        for i, p in ipairs(SpawnedPets) do
            if p.Model == pet then
                petIndex = i
                break
            end
        end
        
        local angleOffset = (petIndex - 1) * 0.8
        local baseOffset = CFrame.Angles(0, angleOffset, 0) * CFrame.new(0, 0, -CONFIG.FollowDistance)
        local targetCFrame = currentHRP.CFrame * baseOffset
        
        local targetPos = targetCFrame.Position

        -- HEIGHT
        if isFlying then
            targetPos = Vector3.new(targetPos.X, currentHRP.Position.Y + CONFIG.FlyHeight, targetPos.Z)
        else
            local groundY = GetGroundHeight(targetPos)
            targetPos = Vector3.new(targetPos.X, groundY + CONFIG.GroundOffset, targetPos.Z)
        end

        -- Smooth
        local currentCF = pet:GetPivot()
        local smoothedPos = currentCF.Position:Lerp(targetPos, CONFIG.FollowSmoothness)

        -- Face player
        local lookDir = currentHRP.CFrame.LookVector
        if lookDir.Magnitude < 0.001 then
            lookDir = Vector3.new(0, 0, -1)
        end

        local newCF = CFrame.lookAt(smoothedPos, smoothedPos + lookDir)
        
        -- Bee fix
        if petName == "Bee" or petName == "Firefly" then
            newCF = newCF * CFrame.Angles(0, math.pi, 0)
        end

        -- PIVOT TO - works on anchored!
        pet:PivotTo(newCF)
    end)

    -- Bobbing (fake animation for anchored pets)
    bobConn = RunService.Heartbeat:Connect(function(dt)
        if not pet or not pet.Parent then
            if bobConn then bobConn:Disconnect() end
            return
        end
        
        time = time + dt * CONFIG.BobSpeed
        
        local char = player.Character
        if not char then return end
        local currentHRP = char:FindFirstChild("HumanoidRootPart")
        if not currentHRP then return end

        if currentHRP.Velocity.Magnitude < 2 then
            local bobOffset = math.sin(time) * CONFIG.BobAmount
            local currentCF = pet:GetPivot()
            local bobbedPos = currentCF.Position + Vector3.new(0, bobOffset, 0)
            local newCF = CFrame.new(bobbedPos) * currentCF.Rotation
            pet:PivotTo(newCF)
        end
    end)

    return followConn, bobConn
end

-- ═══════════════════════════════════════════════════════════════
--  SPAWN PET
-- ═══════════════════════════════════════════════════════════════

function SpawnPet(petName)
    if #SpawnedPets >= CONFIG.MaxPets then
        local oldest = table.remove(SpawnedPets, 1)
        if oldest and oldest.Model then
            if oldest.FollowConn then oldest.FollowConn:Disconnect() end
            if oldest.BobConn then oldest.BobConn:Disconnect() end
            oldest.Model:Destroy()
        end
    end

    local pet = ClonePet(petName)
    if not pet then return end

    local char = player.Character
    if not char then
        warn("❌ Character not loaded")
        return
    end

    local currentHRP = char:WaitForChild("HumanoidRootPart")
    
    -- Calculate spawn position
    local spawnPos = currentHRP.Position + Vector3.new(CONFIG.FollowDistance, 0, 0)
    
    if not IsFlyingPet(petName) then
        local groundY = GetGroundHeight(spawnPos)
        spawnPos = Vector3.new(spawnPos.X, groundY + CONFIG.GroundOffset, spawnPos.Z)
    else
        spawnPos = spawnPos + Vector3.new(0, CONFIG.FlyHeight, 0)
    end
    
    local spawnCF = CFrame.new(spawnPos) * CFrame.Angles(0, math.pi, 0)
    
    -- Position before parenting
    pet:PivotTo(spawnCF)
    
    -- PARENT TO WORKSPACE
    pet.Parent = workspace
    
    -- CRITICAL: Re-anchor after parenting (sometimes unanchors on parent)
    task.wait()
    for _, part in ipairs(pet:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
        end
    end
    
    -- Verify position
    local actualPos = pet:GetPivot().Position
    print("📍 Spawned at:", math.floor(actualPos.X), math.floor(actualPos.Y), math.floor(actualPos.Z))

    -- Start systems
    local followConn, bobConn = FollowPlayer(pet, petName)
    local hasAnims = StartAnimations(pet, petName)

    local petData = {
        Model = pet,
        Name = petName,
        FollowConn = followConn,
        BobConn = bobConn,
    }
    
    table.insert(SpawnedPets, petData)

    -- Cleanup on destroy
    pet.AncestryChanged:Connect(function(_, newParent)
        if not newParent then
            for i, p in ipairs(SpawnedPets) do
                if p.Model == pet then
                    if p.FollowConn then p.FollowConn:Disconnect() end
                    if p.BobConn then p.BobConn:Disconnect() end
                    table.remove(SpawnedPets, i)
                    countLabel.Text = "Spawned: " .. #SpawnedPets
                    break
                end
            end
        end
    end)

    print("✅ SPAWNED:", petName, "| Flying:", IsFlyingPet(petName), "| Anims:", hasAnims, "| Total:", #SpawnedPets)
    return pet
end

function ClearAllPets()
    for _, petData in ipairs(SpawnedPets) do
        if petData.Model then
            if petData.FollowConn then petData.FollowConn:Disconnect() end
            if petData.BobConn then petData.BobConn:Disconnect() end
            petData.Model:Destroy()
        end
    end
    SpawnedPets = {}
    print("❌ All cleared")
end

-- ═══════════════════════════════════════════════════════════════
--  DRAGGABLE GUI
-- ═══════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GAG2PetSpawner"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "Toggle"
toggleBtn.Size = UDim2.new(0, 55, 0, 55)
toggleBtn.Position = UDim2.new(0, 15, 0.5, -27)
toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
toggleBtn.Text = "🐾"
toggleBtn.TextSize = 28
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextColor3 = Color3.fromRGB(50, 30, 0)

local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(1, 0)
tCorner.Parent = toggleBtn

local tStroke = Instance.new("UIStroke")
tStroke.Color = Color3.fromRGB(200, 150, 40)
tStroke.Thickness = 3
tStroke.Parent = toggleBtn

toggleBtn.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = true

local mCorner = Instance.new("UICorner")
mCorner.CornerRadius = UDim.new(0, 14)
mCorner.Parent = mainFrame

local mStroke = Instance.new("UIStroke")
mStroke.Color = Color3.fromRGB(80, 80, 100)
mStroke.Thickness = 2
mStroke.Parent = mainFrame

mainFrame.Parent = screenGui

-- DRAG
local dragging = false
local dragStart = nil
local startPos = nil

local function updateDrag(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateDrag(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateDrag(input)
    end
end)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
titleBar.BorderSizePixel = 0

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 14)
tbCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -100, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🐾 Pet Spawner"
titleLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

titleBar.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 34, 0, 34)
closeBtn.Position = UDim2.new(1, -39, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
closeBtn.Text = "✕"
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

local cCorner = Instance.new("UICorner")
cCorner.CornerRadius = UDim.new(0, 10)
cCorner.Parent = closeBtn

closeBtn.Parent = mainFrame

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0, 70, 0, 28)
clearBtn.Position = UDim2.new(1, -82, 0, 7)
clearBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
clearBtn.Text = "Clear All"
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.TextSize = 11
clearBtn.Font = Enum.Font.GothamBold

local clCorner = Instance.new("UICorner")
clCorner.CornerRadius = UDim.new(0, 8)
clCorner.Parent = clearBtn

clearBtn.Parent = titleBar

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -95)
scroll.Position = UDim2.new(0, 8, 0, 48)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = scroll

local countFrame = Instance.new("Frame")
countFrame.Size = UDim2.new(1, -16, 0, 38)
countFrame.Position = UDim2.new(0, 8, 1, -42)
countFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)

local cfCorner = Instance.new("UICorner")
cfCorner.CornerRadius = UDim.new(0, 10)
cfCorner.Parent = countFrame

local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(1, -10, 1, 0)
countLabel.Position = UDim2.new(0, 5, 0, 0)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Spawned: 0"
countLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
countLabel.TextSize = 13
countLabel.Font = Enum.Font.Gotham
countLabel.Parent = countFrame

countFrame.Parent = mainFrame

-- ═══════════════════════════════════════════════════════════════
--  POPULATE LIST
-- ═══════════════════════════════════════════════════════════════

local allPets = GetAllPets()
print("📋 Found", #allPets, "pets")

for _, petName in ipairs(allPets) do
    local btn = Instance.new("TextButton")
    btn.Name = petName
    btn.Size = UDim2.new(1, -10, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
    btn.Text = "  " .. petName
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(75, 75, 95)
    stroke.Thickness = 1
    stroke.Parent = btn

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 28, 0, 28)
    arrow.Position = UDim2.new(1, -34, 0.5, -14)
    arrow.BackgroundTransparency = 1
    arrow.Text = "+"
    arrow.TextColor3 = Color3.fromRGB(100, 255, 100)
    arrow.TextSize = 20
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = btn

    btn.MouseButton1Click:Connect(function()
        SpawnPet(petName)
        countLabel.Text = "Spawned: " .. #SpawnedPets
        
        btn.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
        task.wait(0.2)
        btn.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
    end)

    btn.Parent = scroll
end

-- ═══════════════════════════════════════════════════════════════
--  BUTTONS
-- ═══════════════════════════════════════════════════════════════

local function toggleGUI()
    if mainFrame.Visible then
        TweenService:Create(mainFrame, TweenInfo.new(0.18), {
            Size = UDim2.new(0, 300, 0, 0),
            Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 0.5, 0)
        }):Play()
        task.wait(0.18)
        mainFrame.Visible = false
    else
        mainFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 300, 0, 0)
        TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 300, 0, 400),
            Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset)
        }):Play()
    end
end

toggleBtn.MouseButton1Click:Connect(toggleGUI)
closeBtn.MouseButton1Click:Connect(toggleGUI)

clearBtn.MouseButton1Click:Connect(function()
    ClearAllPets()
    countLabel.Text = "Spawned: 0"
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.P then
        toggleGUI()
    end
end)

player.CharacterRemoving:Connect(function()
    ClearAllPets()
    countLabel.Text = "Spawned: 0"
end)

print("🐾 GAG 2 Pet Spawner loaded!")
print("📋 Pets:", #allPets, "| Press P or click 🐾")
