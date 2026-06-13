-- ═══════════════════════════════════════════════════════════════
--  GAG 2 - REAL PET INVENTORY INJECTOR
--  Auto-discovers native inventory system and injects pets
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
    FollowDistance = 4,
    HeightAboveGround = 1,
    FollowSmoothness = 0.1,
    MaxEquipped = 8,
}

-- ═══════════════════════════════════════════════════════════════
--  DISCOVERY: Find GAG 2's Real Inventory System
-- ═══════════════════════════════════════════════════════════════

local GAG_Systems = {
    DataFolder = nil,           -- e.g., player.Data or player.PetData
    PetsFolder = nil,           -- Where pets are stored in player
    RemotesFolder = nil,        -- ReplicatedStorage.Remotes or Events
    PetAddedRemote = nil,       -- RemoteEvent for adding pets
    PetEquipRemote = nil,       -- RemoteEvent for equipping pets
    PetDataModule = nil,        -- ModuleScript with pet data structure
    InventoryUI = nil,          -- The real inventory GUI
    PetTemplate = nil,          -- Template for pet data entries
}

-- Discovery function
local function DiscoverGAGSystems()
    print("\n🔍 DISCOVERING GAG 2 SYSTEMS...")
    
    -- 1. Look for player data folders
    for _, child in ipairs(player:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Configuration") then
            local name = child.Name:lower()
            if name:find("data") or name:find("pet") or name:find("inventory") or name:find("save") then
                GAG_Systems.DataFolder = child
                print("  📁 Found DataFolder:", child.Name)
                
                -- Look for pets subfolder
                for _, sub in ipairs(child:GetChildren()) do
                    local subName = sub.Name:lower()
                    if subName:find("pet") or subName:find("companion") or subName:find("equip") then
                        GAG_Systems.PetsFolder = sub
                        print("  📁 Found PetsFolder:", sub:GetFullName())
                        break
                    end
                end
                break
            end
        end
    end
    
    -- 2. Look for remotes in ReplicatedStorage
    local remoteCandidates = {
        "Remotes", "Events", "RemoteEvents", "Communication", "Network"
    }
    
    for _, name in ipairs(remoteCandidates) do
        local folder = ReplicatedStorage:FindFirstChild(name)
        if folder then
            GAG_Systems.RemotesFolder = folder
            print("  📡 Found RemotesFolder:", folder.Name)
            
            -- Scan for pet-related remotes
            for _, remote in ipairs(folder:GetDescendants()) do
                if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                    local rName = remote.Name:lower()
                    if rName:find("pet") and (rName:find("add") or rName:find("give") or rName:find("spawn") or rName:find("create")) then
                        GAG_Systems.PetAddedRemote = remote
                        print("  📡 Found PetAddedRemote:", remote.Name)
                    end
                    if rName:find("pet") and (rName:find("equip") or rName:find("wear") or rName:find("active")) then
                        GAG_Systems.PetEquipRemote = remote
                        print("  📡 Found PetEquipRemote:", remote.Name)
                    end
                end
            end
            break
        end
    end
    
    -- 3. Look for inventory UI
    local guiCandidates = {
        player:WaitForChild("PlayerGui"),
    }
    for _, gui in ipairs(guiCandidates) do
        for _, screen in ipairs(gui:GetChildren()) do
            local sName = screen.Name:lower()
            if sName:find("inventory") or sName:find("pet") or sName:find("backpack") or sName:find("satchel") then
                GAG_Systems.InventoryUI = screen
                print("  🖥️ Found InventoryUI:", screen.Name)
                break
            end
        end
    end
    
    -- 4. Look for pet data module
    for _, module in ipairs(ReplicatedStorage:GetDescendants()) do
        if module:IsA("ModuleScript") then
            local mName = module.Name:lower()
            if mName:find("pet") and mName:find("data") or mName:find("pet") and mName:find("template") then
                GAG_Systems.PetDataModule = module
                print("  📜 Found PetDataModule:", module.Name)
                break
            end
        end
    end
    
    -- 5. Try to infer pet data structure from existing pets
    if GAG_Systems.PetsFolder then
        local existingPets = GAG_Systems.PetsFolder:GetChildren()
        if #existingPets > 0 then
            GAG_Systems.PetTemplate = existingPets[1]
            print("  📝 Found PetTemplate from existing pet:", existingPets[1].Name)
        end
    end
    
    -- Summary
    print("\n📊 DISCOVERY SUMMARY:")
    print("  DataFolder:", GAG_Systems.DataFolder and "✅" or "❌")
    print("  PetsFolder:", GAG_Systems.PetsFolder and "✅" or "❌")
    print("  RemotesFolder:", GAG_Systems.RemotesFolder and "✅" or "❌")
    print("  PetAddedRemote:", GAG_Systems.PetAddedRemote and "✅" or "❌")
    print("  PetEquipRemote:", GAG_Systems.PetEquipRemote and "✅" or "❌")
    print("  InventoryUI:", GAG_Systems.InventoryUI and "✅" or "❌")
    print("  PetTemplate:", GAG_Systems.PetTemplate and "✅" or "❌")
    
    local hasRealSystem = GAG_Systems.PetsFolder ~= nil or GAG_Systems.PetAddedRemote ~= nil
    print("\n🎯 Real GAG System Detected:", hasRealSystem and "YES" or "NO (fallback mode)")
    
    return hasRealSystem
end

-- Run discovery
local HAS_REAL_SYSTEM = DiscoverGAGSystems()

-- ═══════════════════════════════════════════════════════════════
--  GET PET FOLDER (for cloning visuals)
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
--  REAL INVENTORY INJECTION
-- ═══════════════════════════════════════════════════════════════

local function InjectPetToRealInventory(petName)
    if not HAS_REAL_SYSTEM then
        return false, "No real system detected"
    end
    
    print("\n💉 INJECTING:", petName, "into REAL inventory")
    
    -- Method 1: Use RemoteEvent (most common in GAG 2)
    if GAG_Systems.PetAddedRemote then
        print("  📡 Using RemoteEvent:", GAG_Systems.PetAddedRemote.Name)
        
        local success, err = pcall(function()
            -- Try different argument patterns
            GAG_Systems.PetAddedRemote:FireServer(petName)
        end)
        
        if success then
            print("  ✅ Fired PetAddedRemote")
            return true, "RemoteEvent"
        else
            print("  ❌ RemoteEvent failed:", err)
        end
    end
    
    -- Method 2: Direct folder insertion (if PetsFolder exists and replicates)
    if GAG_Systems.PetsFolder then
        print("  📁 Trying direct folder insertion...")
        
        -- Create a pet data entry matching GAG 2's structure
        local petEntry = nil
        
        if GAG_Systems.PetTemplate then
            -- Clone existing structure
            petEntry = GAG_Systems.PetTemplate:Clone()
            petEntry.Name = petName
            print("  📝 Cloned from template")
        else
            -- Create generic structure based on GAG 2's known format
            petEntry = Instance.new("Folder")
            petEntry.Name = petName
            
            -- GAG 2 pet attributes (based on game knowledge)
            local age = Instance.new("IntValue")
            age.Name = "Age"
            age.Value = 0
            age.Parent = petEntry
            
            local weight = Instance.new("NumberValue")
            weight.Name = "Weight"
            weight.Value = 1
            weight.Parent = petEntry
            
            local equipped = Instance.new("BoolValue")
            equipped.Name = "Equipped"
            equipped.Value = false
            equipped.Parent = petEntry
            
            local petType = Instance.new("StringValue")
            petType.Name = "Type"
            petType.Value = petName
            petType.Parent = petEntry
            
            print("  📝 Created generic pet structure")
        end
        
        petEntry.Parent = GAG_Systems.PetsFolder
        print("  ✅ Inserted into PetsFolder")
        return true, "DirectFolder"
    end
    
    -- Method 3: Try to find and invoke any BindableEvent or Function
    if GAG_Systems.DataFolder then
        for _, child in ipairs(GAG_Systems.DataFolder:GetDescendants()) do
            if child:IsA("BindableEvent") or child:IsA("BindableFunction") then
                local cName = child.Name:lower()
                if cName:find("pet") or cName:find("add") or cName:find("give") then
                    print("  🔗 Trying Bindable:", child.Name)
                    local success = pcall(function()
                        child:Fire(petName)
                    end)
                    if success then
                        print("  ✅ Bindable worked")
                        return true, "Bindable"
                    end
                end
            end
        end
    end
    
    return false, "All methods failed"
end

local function EquipPetInRealSystem(petNameOrId)
    if not HAS_REAL_SYSTEM then
        return false
    end
    
    -- Method 1: RemoteEvent
    if GAG_Systems.PetEquipRemote then
        pcall(function()
            GAG_Systems.PetEquipRemote:FireServer(petNameOrId)
        end)
        return true
    end
    
    -- Method 2: Direct value change
    if GAG_Systems.PetsFolder then
        for _, pet in ipairs(GAG_Systems.PetsFolder:GetChildren()) do
            if pet.Name == petNameOrId or pet:GetAttribute("Type") == petNameOrId then
                local equipped = pet:FindFirstChild("Equipped")
                if equipped and equipped:IsA("BoolValue") then
                    equipped.Value = true
                    print("  ✅ Set Equipped = true for", pet.Name)
                    return true
                end
            end
        end
    end
    
    return false
end

local function UnequipPetInRealSystem(petNameOrId)
    if not HAS_REAL_SYSTEM then
        return false
    end
    
    if GAG_Systems.PetsFolder then
        for _, pet in ipairs(GAG_Systems.PetsFolder:GetChildren()) do
            if pet.Name == petNameOrId or pet:GetAttribute("Type") == petNameOrId then
                local equipped = pet:FindFirstChild("Equipped")
                if equipped and equipped:IsA("BoolValue") then
                    equipped.Value = false
                    return true
                end
            end
        end
    end
    
    return false
end

-- ═══════════════════════════════════════════════════════════════
--  FALLBACK: VISUAL PET SPAWNER (when real system unavailable)
-- ═══════════════════════════════════════════════════════════════

local SpawnedPets = {}

local function GetGroundHeight(position)
    local rayOrigin = position + Vector3.new(0, 100, 0)
    local rayDirection = Vector3.new(0, -200, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local filterList = {}
    for _, petData in ipairs(SpawnedPets) do
        if petData.Model and petData.Model.Parent then
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
    
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        return player.Character.HumanoidRootPart.Position.Y - 3
    end
    
    return position.Y
end

local function ClonePetForWorld(petName)
    local template = PetFolder:FindFirstChild(petName)
    if not template then
        warn("❌ Pet not found:", petName)
        return nil
    end

    local clone = template:Clone()

    if template.PrimaryPart then
        local pp = clone:FindFirstChild(template.PrimaryPart.Name)
        if pp then
            clone.PrimaryPart = pp
        end
    end

    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
            part.CanQuery = false
            if part.Transparency >= 1 then
                part.Transparency = 0
            end
        end
        
        if part:IsA("Motor6D") then
            local p0 = clone:FindFirstChild(part.Part0 and part.Part0.Name or "")
            local p1 = clone:FindFirstChild(part.Part1 and part.Part1.Name or "")
            if p0 and p1 then
                part.Part0 = p0
                part.Part1 = p1
            end
        end
        
        if part:IsA("Weld") or part:IsA("ManualWeld") then
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

-- FIXED ANIMATION SYSTEM (Humanoid method)
local function StartAnimations(pet, petName)
    print("\n--- ANIMATIONS for", petName, "---")
    
    local animTracks = {}
    local playedAny = false
    
    local humanoid = pet:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        humanoid = Instance.new("Humanoid")
        humanoid.Name = "Humanoid"
        humanoid.Health = 100
        humanoid.MaxHealth = 100
        humanoid.Parent = pet
        print("📎 Created Humanoid")
    else
        print("📎 Found Humanoid")
    end
    
    local animationsFolder = pet:FindFirstChild("Animations")
    if not animationsFolder then
        for _, child in ipairs(pet:GetChildren()) do
            if child:IsA("Folder") and child.Name:lower():find("anim") then
                animationsFolder = child
                print("🔍 Found anim folder:", child.Name)
                break
            end
        end
    else
        print("🔍 Found Animations folder")
    end
    
    local function loadAndPlay(animObj)
        if not animObj:IsA("Animation") or animObj.AnimationId == "" then return false end
        
        print("  🎬", animObj.Name, "ID:", animObj.AnimationId:sub(1, 40))
        
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
                print("     ▶ PLAYING (Idle)")
                table.insert(animTracks, track)
                return true
            elseif name:find("walk") or name:find("fly") or name:find("run") or name:find("move") then
                track.Looped = true
                track.Priority = Enum.AnimationPriority.Movement
                print("     📥 LOADED (Movement)")
                table.insert(animTracks, track)
                return true
            else
                track.Looped = true
                track.Priority = Enum.AnimationPriority.Action
                track:Play()
                playedAny = true
                print("     ▶ PLAYING (Action)")
                table.insert(animTracks, track)
                return true
            end
        else
            print("     ❌ Failed:", tostring(track))
            return false
        end
    end
    
    if animationsFolder then
        print("🎬 Scanning Animations folder...")
        for _, animObj in ipairs(animationsFolder:GetDescendants()) do
            loadAndPlay(animObj)
        end
        for _, animObj in ipairs(animationsFolder:GetChildren()) do
            loadAndPlay(animObj)
        end
    end
    
    if not playedAny then
        print("🔍 Searching entire pet for animations...")
        for _, desc in ipairs(pet:GetDescendants()) do
            if desc:IsA("Animation") and desc.AnimationId ~= "" then
                loadAndPlay(desc)
            end
        end
    end
    
    if not playedAny then
        local animate = pet:FindFirstChild("Animate")
        if animate and animate:IsA("Script") then
            print("📜 Found Animate script")
            local newAnimate = animate:Clone()
            animate:Destroy()
            newAnimate.Parent = pet
            newAnimate.Disabled = false
            playedAny = true
            print("  ▶ Enabled")
        end
    end
    
    if not playedAny then
        warn("⚠ NO ANIMATIONS for", petName)
    else
        print("✅ Animations active")
    end
    
    print("---\n")
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
        if lookDir.Magnitude < 0.001 then
            lookDir = Vector3.new(0, 0, -1)
        end
        
        local newCF = CFrame.lookAt(smoothedPos, smoothedPos + lookDir)
        local petName = pet:GetAttribute("PetName") or ""
        if petName == "Bee" or petName == "Firefly" then
            newCF = newCF * CFrame.Angles(0, math.pi, 0)
        end
        
        pet:PivotTo(newCF)
    end)
    return followConn
end

local function SpawnVisualPet(petName)
    if #SpawnedPets >= CONFIG.MaxEquipped then
        local oldest = table.remove(SpawnedPets, 1)
        if oldest and oldest.Model then
            if oldest.FollowConn then oldest.FollowConn:Disconnect() end
            if oldest.AnimTracks then
                for _, track in ipairs(oldest.AnimTracks) do
                    pcall(function() track:Stop() track:Destroy() end)
                end
            end
            oldest.Model:Destroy()
        end
    end
    
    print("\n========== SPAWNING:", petName, "==========")
    
    local pet = ClonePetForWorld(petName)
    if not pet then 
        print("❌ Clone failed")
        return nil 
    end
    
    local char = player.Character
    if not char then
        warn("❌ Character not loaded")
        pet:Destroy()
        return nil
    end
    
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
    
    local followIndex = #SpawnedPets + 1
    local hasAnims, animTracks = StartAnimations(pet, petName)
    local followConn = FollowPlayer(pet, followIndex)
    
    local petData = {
        Model = pet,
        Name = petName,
        FollowConn = followConn,
        AnimTracks = animTracks,
    }
    
    table.insert(SpawnedPets, petData)
    
    pet.AncestryChanged:Connect(function(_, newParent)
        if not newParent then
            for i, p in ipairs(SpawnedPets) do
                if p.Model == pet then
                    if p.FollowConn then p.FollowConn:Disconnect() end
                    if p.AnimTracks then
                        for _, track in ipairs(p.AnimTracks) do
                            pcall(function() track:Stop() track:Destroy() end)
                        end
                    end
                    table.remove(SpawnedPets, i)
                    break
                end
            end
        end
    end)
    
    print("✅ SPAWNED:", petName, "| Anims:", hasAnims, "| Total:", #SpawnedPets)
    print("================================\n")
    return pet
end

local function ClearVisualPets()
    for _, petData in ipairs(SpawnedPets) do
        if petData.Model then
            if petData.FollowConn then petData.FollowConn:Disconnect() end
            if petData.AnimTracks then
                for _, track in ipairs(petData.AnimTracks) do
                    pcall(function() track:Stop() track:Destroy() end)
                end
            end
            petData.Model:Destroy()
        end
    end
    SpawnedPets = {}
    print("❌ All visual pets cleared")
end

-- ═══════════════════════════════════════════════════════════════
--  UNIFIED SPAWN FUNCTION (Real + Visual)
-- ═══════════════════════════════════════════════════════════════

local InventoryCache = {} -- Track what we've injected

local function SpawnPet(petName)
    -- Step 1: Try to inject into real inventory
    local injected, method = InjectPetToRealInventory(petName)
    
    if injected then
        print("💉 Successfully injected", petName, "via", method)
        InventoryCache[petName] = true
        
        -- Step 2: Try to equip via real system
        task.delay(0.3, function()
            EquipPetInRealSystem(petName)
        end)
        
        -- Step 3: Also spawn visual (since real system might not show it immediately)
        task.delay(0.5, function()
            SpawnVisualPet(petName)
        end)
        
        return true
    else
        -- Fallback: Just spawn visual
        print("⚠ Real injection failed, using visual fallback")
        SpawnVisualPet(petName)
        return false
    end
end

-- ═══════════════════════════════════════════════════════════════
--  GUI
-- ═══════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GAG2RealPetInjector"
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
mainFrame.Size = UDim2.new(0, 320, 0, 420)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -210)
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

-- Status indicator
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, 0, 0, 24)
statusBar.Position = UDim2.new(0, 0, 0, 42)
statusBar.BackgroundColor3 = HAS_REAL_SYSTEM and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 80, 40)
statusBar.BorderSizePixel = 0

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 1, 0)
statusLabel.Position = UDim2.new(0, 5, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = HAS_REAL_SYSTEM and "🟢 REAL SYSTEM DETECTED" or "🟡 VISUAL MODE (No real system found)"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Parent = statusBar

statusBar.Parent = mainFrame

-- Drag
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

-- Title
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
titleLabel.Text = "🐾 Real Pet Injector"
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

-- Count
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
countLabel.Text = "Spawned: 0 | Mode: " .. (HAS_REAL_SYSTEM and "REAL" or "VISUAL")
countLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
countLabel.TextSize = 13
countLabel.Font = Enum.Font.Gotham
countLabel.Parent = countFrame

countFrame.Parent = mainFrame

-- Populate
local allPets = GetAllPetNames()
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
    arrow.Text = HAS_REAL_SYSTEM and "💉" or "👁️"
    arrow.TextColor3 = HAS_REAL_SYSTEM and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 200, 100)
    arrow.TextSize = 20
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = btn

    btn.MouseButton1Click:Connect(function()
        SpawnPet(petName)
        countLabel.Text = "Spawned: " .. #SpawnedPets .. " | Mode: " .. (HAS_REAL_SYSTEM and "REAL" or "VISUAL")
        
        btn.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
        task.wait(0.2)
        btn.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
    end)

    btn.Parent = scroll
end

-- Buttons
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

clearBtn.MouseButton1Click:Connect(function()
    ClearVisualPets()
    countLabel.Text = "Spawned: 0 | Mode: " .. (HAS_REAL_SYSTEM and "REAL" or "VISUAL")
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.P then
        toggleGUI()
    end
end)

player.CharacterRemoving:Connect(function()
    ClearVisualPets()
end)

print("\n🐾 GAG 2 REAL PET INJECTOR loaded!")
print("📋 Pets:", #allPets, "| System:", HAS_REAL_SYSTEM and "REAL" or "VISUAL")
print("🔍 Discovery results printed above")
print("💡 If REAL system not detected, check the discovery output and adjust paths")
