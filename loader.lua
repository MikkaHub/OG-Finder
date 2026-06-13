-- ═══════════════════════════════════════════════════════════════
--  GAG 2 - INVENTORY DIAGNOSTIC & INJECTOR
--  Step 1: Discovers YOUR exact pet data structure
--  Step 2: Injects pets using that exact structure
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
--  STEP 1: DEEP DISCOVERY - Find EXACTLY where pets are stored
-- ═══════════════════════════════════════════════════════════════

print("═══════════════════════════════════════════════════════")
print("🔍 GAG 2 INVENTORY DEEP DIAGNOSTIC")
print("═══════════════════════════════════════════════════════")

-- 1.1 Scan player for ALL folders/configurations
print("\n📁 SCANNING PLAYER CHILDREN:")
for _, child in ipairs(player:GetChildren()) do
    print("   " .. child.Name .. " (" .. child.ClassName .. ")")
    if child:IsA("Folder") or child:IsA("Configuration") then
        for _, sub in ipairs(child:GetChildren()) do
            print("      └─ " .. sub.Name .. " (" .. sub.ClassName .. ")")
            if sub:IsA("Folder") or sub:IsA("Configuration") then
                for _, sub2 in ipairs(sub:GetChildren()) do
                    print("         └─ " .. sub2.Name .. " (" .. sub2.ClassName .. ")")
                end
            end
        end
    end
end

-- 1.2 Look for pet data specifically
print("\n🐾 LOOKING FOR PET DATA:")
local PetDataLocations = {}

local function scanForPets(parent, path)
    for _, child in ipairs(parent:GetChildren()) do
        local currentPath = path .. "." .. child.Name
        local name = child.Name:lower()
        
        -- Check if this looks like pet data
        if name:find("pet") or name:find("companion") or name:find("animal") then
            print("   🎯 PET-LIKE at " .. currentPath .. " (" .. child.ClassName .. ")")
            table.insert(PetDataLocations, {
                path = currentPath,
                instance = child,
                class = child.ClassName
            })
        end
        
        -- Recurse into folders/configurations
        if child:IsA("Folder") or child:IsA("Configuration") or child:IsA("Model") then
            scanForPets(child, currentPath)
        end
    end
end

scanForPets(player, "player")

-- 1.3 Check ReplicatedStorage for pet modules/remotes
print("\n📡 SCANNING REPLICATEDSTORAGE:")
for _, child in ipairs(ReplicatedStorage:GetChildren()) do
    print("   " .. child.Name .. " (" .. child.ClassName .. ")")
    if child:IsA("Folder") then
        for _, sub in ipairs(child:GetChildren()) do
            print("      └─ " .. sub.Name .. " (" .. sub.ClassName .. ")")
        end
    end
end

-- 1.4 Look for RemoteEvents specifically
print("\n📡 LOOKING FOR PET REMOTES:")
local PetRemotes = {}
for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
    if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
        local name = desc.Name:lower()
        if name:find("pet") or name:find("add") or name:find("give") or name:find("spawn") or 
           name:find("equip") or name:find("inventory") or name:find("buy") then
            print("   🎯 " .. desc:GetFullName() .. " (" .. desc.ClassName .. ")")
            table.insert(PetRemotes, desc)
        end
    end
end

-- 1.5 Analyze existing pet data structure
print("\n📝 ANALYZING EXISTING PET DATA:")
local PetTemplate = nil
for _, loc in ipairs(PetDataLocations) do
    local instance = loc.instance
    if instance:IsA("Folder") or instance:IsA("Configuration") then
        local children = instance:GetChildren()
        print("   " .. loc.path .. " has " .. #children .. " children")
        
        for _, pet in ipairs(children) do
            print("   📋 Sample pet: " .. pet.Name .. " (" .. pet.ClassName .. ")")
            PetTemplate = pet
            for _, val in ipairs(pet:GetChildren()) do
                local valStr = ""
                if val:IsA("ValueBase") then
                    valStr = " = " .. tostring(val.Value)
                end
                print("      └─ " .. val.Name .. " (" .. val.ClassName .. ")" .. valStr)
            end
            break -- Just analyze first one
        end
        break
    end
end

-- 1.6 Check PlayerGui for inventory UI
print("\n🖥️ SCANNING PLAYERGUI FOR INVENTORY:")
for _, screen in ipairs(player.PlayerGui:GetChildren()) do
    local name = screen.Name:lower()
    if name:find("inventory") or name:find("backpack") or name:find("pet") or 
       name:find("bag") or name:find("menu") or name:find("ui") then
        print("   🎯 " .. screen.Name .. " (" .. screen.ClassName .. ")")
        for _, child in ipairs(screen:GetDescendants()) do
            if child:IsA("Frame") or child:IsA("ScrollingFrame") then
                local cName = child.Name:lower()
                if cName:find("inventory") or cName:find("slot") or cName:find("item") or 
                   cName:find("pet") or cName:find("grid") or cName:find("list") then
                    print("      └─ " .. child:GetFullName())
                    break
                end
            end
        end
    end
end

print("\n═══════════════════════════════════════════════════════")
print("🔍 DIAGNOSTIC COMPLETE")
print("═══════════════════════════════════════════════════════")

-- ═══════════════════════════════════════════════════════════════
--  STEP 2: INJECTION BASED ON DISCOVERED STRUCTURE
-- ═══════════════════════════════════════════════════════════════

local PetDataFolder = nil
local InjectedPets = {}

-- Determine the correct folder from discovery
if PetTemplate then
    PetDataFolder = PetTemplate.Parent
    print("\n✅ Using discovered folder: " .. PetDataFolder:GetFullName())
else
    -- Fallback: try common paths
    local fallbackPaths = {
        {"Pets"},
        {"Data", "Pets"},
        {"Data", "Inventory", "Pets"},
        {"leaderstats", "Pets"},
        {"PlayerData", "Pets"},
    }
    
    for _, path in ipairs(fallbackPaths) do
        local current = player
        local valid = true
        for _, name in ipairs(path) do
            current = current:FindFirstChild(name)
            if not current then
                valid = false
                break
            end
        end
        if valid then
            PetDataFolder = current
            print("✅ Using fallback path: " .. PetDataFolder:GetFullName())
            break
        end
    end
end

-- Get pet folder from ReplicatedStorage
local PetFolder = ReplicatedStorage
for _, name in ipairs({"Assets", "Pets"}) do
    PetFolder = PetFolder:FindFirstChild(name)
    if not PetFolder then
        warn("❌ Pet folder path broken at: " .. name)
        return
    end
end

print("✅ Pet templates at: " .. PetFolder:GetFullName())

-- ═══════════════════════════════════════════════════════════════
--  GET ALL PET NAMES
-- ═══════════════════════════════════════════════════════════════

local function GetAllPetNames()
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
--  INJECT PET USING EXACT NATIVE STRUCTURE
-- ═══════════════════════════════════════════════════════════════

local function InjectPet(petName)
    print("\n💉 INJECTING: " .. petName)
    
    -- Method 1: Fire RemoteEvent (most reliable)
    for _, remote in ipairs(PetRemotes) do
        local rName = remote.Name:lower()
        if rName:find("add") or rName:find("give") or rName:find("spawn") or rName:find("buy") or rName:find("pet") then
            print("   📡 Firing remote: " .. remote.Name)
            local success = pcall(function()
                remote:FireServer(petName)
            end)
            if success then
                print("   ✅ Remote fired successfully")
                InjectedPets[petName] = true
                return true
            end
        end
    end
    
    -- Method 2: Direct data insertion (if we found the folder)
    if PetDataFolder then
        print("   📁 Inserting into data folder...")
        
        local petEntry = nil
        
        if PetTemplate then
            -- Clone EXACT structure from existing pet
            petEntry = PetTemplate:Clone()
            petEntry.Name = petName
            print("   📝 Cloned exact structure from: " .. PetTemplate.Name)
        else
            -- Create generic structure
            petEntry = Instance.new("Folder")
            petEntry.Name = petName
            
            -- Common GAG 2 values
            local values = {
                {name = "Equipped", class = "BoolValue", value = false},
                {name = "Age", class = "IntValue", value = 0},
                {name = "Weight", class = "NumberValue", value = 1},
                {name = "Hunger", class = "NumberValue", value = 100},
                {name = "XP", class = "NumberValue", value = 0},
                {name = "Level", class = "IntValue", value = 1},
                {name = "Rarity", class = "StringValue", value = "Common"},
            }
            
            for _, v in ipairs(values) do
                local val = Instance.new(v.class)
                val.Name = v.name
                val.Value = v.value
                val.Parent = petEntry
            end
            print("   📝 Created generic structure")
        end
        
        -- Mark as injected
        petEntry:SetAttribute("Injected", true)
        petEntry:SetAttribute("InjectTime", os.time())
        
        petEntry.Parent = PetDataFolder
        InjectedPets[petName] = petEntry
        print("   ✅ Inserted into " .. PetDataFolder.Name)
        return true
    end
    
    -- Method 3: Try to invoke BindableEvents
    for _, desc in ipairs(player:GetDescendants()) do
        if desc:IsA("BindableEvent") then
            local name = desc.Name:lower()
            if name:find("pet") or name:find("add") then
                print("   🔗 Trying bindable: " .. desc.Name)
                local success = pcall(function()
                    desc:Fire(petName)
                end)
                if success then
                    print("   ✅ Bindable worked")
                    return true
                end
            end
        end
    end
    
    print("   ❌ All injection methods failed")
    return false
end

-- ═══════════════════════════════════════════════════════════════
--  VISUAL PET SPAWNER (with fixed animations)
-- ═══════════════════════════════════════════════════════════════

local EquippedVisuals = {}
local CONFIG = {
    FollowDistance = 4,
    HeightAboveGround = 1,
    FollowSmoothness = 0.1,
    MaxEquipped = 8,
}

local function GetGroundHeight(position)
    local rayOrigin = position + Vector3.new(0, 100, 0)
    local rayDirection = Vector3.new(0, -200, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local filterList = {}
    for _, data in pairs(EquippedVisuals) do
        if data.model and data.model.Parent then
            table.insert(filterList, data.model)
        end
    end
    if player.Character then
        table.insert(filterList, player.Character)
    end
    raycastParams.FilterDescendantsInstances = filterList
    
    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if result then return result.Position.Y end
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        return player.Character.HumanoidRootPart.Position.Y - 3
    end
    return position.Y
end

local function ClonePetForWorld(petName)
    local template = PetFolder:FindFirstChild(petName)
    if not template then return nil end

    local clone = template:Clone()
    if template.PrimaryPart then
        local pp = clone:FindFirstChild(template.PrimaryPart.Name)
        if pp then clone.PrimaryPart = pp end
    end

    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
            part.CanQuery = false
            if part.Transparency >= 1 then part.Transparency = 0 end
        end
        if part:IsA("Motor6D") or part:IsA("Weld") or part:IsA("ManualWeld") then
            local p0 = clone:FindFirstChild(part.Part0 and part.Part0.Name or "")
            local p1 = clone:FindFirstChild(part.Part1 and part.Part1.Name or "")
            if p0 and p1 then
                part.Part0 = p0
                part.Part1 = p1
            end
        end
        if part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 0
        end
    end

    clone:SetAttribute("IsPet", true)
    clone:SetAttribute("PetName", petName)
    return clone
end

local function StartAnimations(pet, petName)
    local animTracks = {}
    local playedAny = false
    
    local humanoid = pet:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        humanoid = Instance.new("Humanoid")
        humanoid.Name = "Humanoid"
        humanoid.Health = 100
        humanoid.MaxHealth = 100
        humanoid.Parent = pet
    end
    
    local animationsFolder = pet:FindFirstChild("Animations")
    if not animationsFolder then
        for _, child in ipairs(pet:GetChildren()) do
            if child:IsA("Folder") and child.Name:lower():find("anim") then
                animationsFolder = child
                break
            end
        end
    end
    
    local function loadAndPlay(animObj)
        if not animObj:IsA("Animation") or animObj.AnimationId == "" then return false end
        local success, track = pcall(function()
            return humanoid:LoadAnimation(animObj)
        end)
        if success and track then
            local name = animObj.Name:lower()
            if name:find("idle") or name:find("ground") or name:find("sit") then
                track.Looped = true
                track.Priority = Enum.AnimationPriority.Idle
                track:Play()
                playedAny = true
                table.insert(animTracks, track)
            elseif name:find("walk") or name:find("fly") or name:find("run") or name:find("move") then
                track.Looped = true
                track.Priority = Enum.AnimationPriority.Movement
                table.insert(animTracks, track)
            else
                track.Looped = true
                track.Priority = Enum.AnimationPriority.Action
                track:Play()
                playedAny = true
                table.insert(animTracks, track)
            end
            return true
        end
        return false
    end
    
    if animationsFolder then
        for _, animObj in ipairs(animationsFolder:GetDescendants()) do
            loadAndPlay(animObj)
        end
        for _, animObj in ipairs(animationsFolder:GetChildren()) do
            loadAndPlay(animObj)
        end
    end
    
    if not playedAny then
        for _, desc in ipairs(pet:GetDescendants()) do
            if desc:IsA("Animation") and desc.AnimationId ~= "" then
                loadAndPlay(desc)
            end
        end
    end
    
    if not playedAny then
        local animate = pet:FindFirstChild("Animate")
        if animate and animate:IsA("Script") then
            local newAnimate = animate:Clone()
            animate:Destroy()
            newAnimate.Parent = pet
            newAnimate.Disabled = false
            playedAny = true
        end
    end
    
    return playedAny, animTracks
end

local function FollowPlayer(pet, petIndex)
    local followConn
    followConn = RunService.Heartbeat:Connect(function()
        if not pet or not pet.Parent then
            if followConn then followConn:Disconnect() end
            return
        end
        local char = player.Character
        if not char then return end
        local currentHRP = char:FindFirstChild("HumanoidRootPart")
        if not currentHRP then return end
        
        local angleOffset = (petIndex - 1) * 0.8
        local baseOffset = CFrame.Angles(0, angleOffset, 0) * CFrame.new(0, 0, -CONFIG.FollowDistance)
        local targetCFrame = currentHRP.CFrame * baseOffset
        local targetPos = targetCFrame.Position
        
        local groundY = GetGroundHeight(targetPos)
        targetPos = Vector3.new(targetPos.X, groundY + CONFIG.HeightAboveGround, targetPos.Z)
        
        local currentCF = pet:GetPivot()
        local smoothedPos = currentCF.Position:Lerp(targetPos, CONFIG.FollowSmoothness)
        
        local lookDir = currentHRP.CFrame.LookVector
        if lookDir.Magnitude < 0.001 then lookDir = Vector3.new(0, 0, -1) end
        
        local newCF = CFrame.lookAt(smoothedPos, smoothedPos + lookDir)
        local pName = pet:GetAttribute("PetName") or ""
        if pName == "Bee" or pName == "Firefly" then
            newCF = newCF * CFrame.Angles(0, math.pi, 0)
        end
        
        pet:PivotTo(newCF)
    end)
    return followConn
end

function SpawnVisualPet(petName)
    if EquippedVisuals[petName] then return true end
    
    local eqCount = 0
    for _ in pairs(EquippedVisuals) do eqCount += 1 end
    if eqCount >= CONFIG.MaxEquipped then return false end
    
    local pet = ClonePetForWorld(petName)
    if not pet then return false end
    
    local char = player.Character
    if not char then pet:Destroy() return false end
    
    local currentHRP = char:WaitForChild("HumanoidRootPart")
    local spawnPos = currentHRP.Position + Vector3.new(CONFIG.FollowDistance, 0, 0)
    local groundY = GetGroundHeight(spawnPos)
    spawnPos = Vector3.new(spawnPos.X, groundY + CONFIG.HeightAboveGround, spawnPos.Z)
    
    local spawnCF = CFrame.new(spawnPos) * CFrame.Angles(0, math.pi, 0)
    pet:PivotTo(spawnCF)
    pet.Parent = workspace
    
    task.wait()
    for _, part in ipairs(pet:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
        end
    end
    
    local followIndex = eqCount + 1
    local hasAnims, animTracks = StartAnimations(pet, petName)
    local followConn = FollowPlayer(pet, followIndex)
    
    EquippedVisuals[petName] = {
        model = pet,
        followConn = followConn,
        animTracks = animTracks,
    }
    
    return true
end

function DespawnVisualPet(petName)
    local data = EquippedVisuals[petName]
    if not data then return false end
    if data.followConn then data.followConn:Disconnect() end
    if data.animTracks then
        for _, track in ipairs(data.animTracks) do
            pcall(function() track:Stop() track:Destroy() end)
        end
    end
    if data.model then data.model:Destroy() end
    EquippedVisuals[petName] = nil
    
    task.delay(0.1, function()
        local index = 1
        for _, petData in pairs(EquippedVisuals) do
            if petData.followConn then
                petData.followConn:Disconnect()
                petData.followConn = FollowPlayer(petData.model, index)
                index += 1
            end
        end
    end)
    return true
end

function DespawnAllVisuals()
    for name in pairs(EquippedVisuals) do
        DespawnVisualPet(name)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  GUI
-- ═══════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GAG2DiagnosticInjector"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 55, 0, 55)
toggleBtn.Position = UDim2.new(0, 15, 0.5, -27)
toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
toggleBtn.Text = "🔍"
toggleBtn.TextSize = 28
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextColor3 = Color3.fromRGB(50, 30, 0)
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", toggleBtn).Color = Color3.fromRGB(200, 150, 40)
Instance.new("UIStroke", toggleBtn).Thickness = 3
toggleBtn.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 420)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", mainFrame).Color = Color3.fromRGB(80, 80, 100)
Instance.new("UIStroke", mainFrame).Thickness = 2
mainFrame.Parent = screenGui

-- Drag
local dragging = false
local dragStart = nil
local startPos = nil
local function updateDrag(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
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

-- Title
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -100, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🔍 Diagnostic Injector"
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
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)
closeBtn.Parent = mainFrame

-- Status
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, 0, 0, 24)
statusBar.Position = UDim2.new(0, 0, 0, 42)
statusBar.BackgroundColor3 = PetDataFolder and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 80, 40)
statusBar.BorderSizePixel = 0

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 1, 0)
statusLabel.Position = UDim2.new(0, 5, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = PetDataFolder and ("🟢 DATA: " .. PetDataFolder.Name) or "🟡 NO DATA FOLDER"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Parent = statusBar
statusBar.Parent = mainFrame

-- Scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -110)
scroll.Position = UDim2.new(0, 8, 0, 70)
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

-- Stats
local countFrame = Instance.new("Frame")
countFrame.Size = UDim2.new(1, -16, 0, 38)
countFrame.Position = UDim2.new(0, 8, 1, -42)
countFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
Instance.new("UICorner", countFrame).CornerRadius = UDim.new(0, 10)

local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(1, -10, 1, 0)
countLabel.Position = UDim2.new(0, 5, 0, 0)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Injected: 0 | Visual: 0"
countLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
countLabel.TextSize = 13
countLabel.Font = Enum.Font.Gotham
countLabel.Parent = countFrame
countFrame.Parent = mainFrame

-- Populate
local allPets = GetAllPetNames()
print("📋 Found " .. #allPets .. " pet templates")

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

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(75, 75, 95)
    stroke.Thickness = 1
    stroke.Parent = btn

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 28, 0, 28)
    arrow.Position = UDim2.new(1, -34, 0.5, -14)
    arrow.BackgroundTransparency = 1
    arrow.Text = PetDataFolder and "💉" or "👁️"
    arrow.TextColor3 = PetDataFolder and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 200, 100)
    arrow.TextSize = 20
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = btn

    btn.MouseButton1Click:Connect(function()
        -- Inject into native data
        local success = InjectPet(petName)
        
        -- Also spawn visual
        task.delay(0.3, function()
            SpawnVisualPet(petName)
        end)
        
        -- Update count
        local injectedCount = 0
        for _ in pairs(InjectedPets) do injectedCount += 1 end
        local visualCount = 0
        for _ in pairs(EquippedVisuals) do visualCount += 1 end
        countLabel.Text = "Injected: " .. injectedCount .. " | Visual: " .. visualCount
        
        btn.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
        task.wait(0.2)
        btn.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
    end)

    btn.Parent = scroll
end

-- Toggle
local function toggleGUI()
    if mainFrame.Visible then
        TweenService:Create(mainFrame, TweenInfo.new(0.18), {
            Size = UDim2.new(0, 320, 0, 0),
            Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 0.5, 0)
        }):Play()
        task.wait(0.18)
        mainFrame.Visible = false
    else
        mainFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 320, 0, 0)
        TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 320, 0, 420),
            Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset)
        }):Play()
    end
end

toggleBtn.MouseButton1Click:Connect(toggleGUI)
closeBtn.MouseButton1Click:Connect(toggleGUI)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.P then
        toggleGUI()
    end
end)

player.CharacterRemoving:Connect(function()
    DespawnAllVisuals()
end)

print("\n═══════════════════════════════════════════════════════")
print("🐾 INJECTOR READY")
print("═══════════════════════════════════════════════════════")
print("📋 Pets: " .. #allPets)
print("🎯 Data Folder: " .. (PetDataFolder and PetDataFolder.Name or "NOT FOUND"))
print("📡 Remotes: " .. #PetRemotes)
print("💡 Check console output above for full diagnostic")
print("💡 Tell me the exact path where your pets are stored!")
