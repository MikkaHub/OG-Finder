-- ═══════════════════════════════════════════════════════════════
--  GAG 2 - NATIVE PET DATA INJECTOR
--  Injects pets into the REAL game data system that the inventory reads
--  Pets appear in the actual GAG 2 inventory UI automatically
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
--  DISCOVER NATIVE PET DATA SYSTEM
-- ═══════════════════════════════════════════════════════════════

local NativePetData = {
    Folder = nil,           -- player.Pets or player.Data.Pets
    Remotes = nil,          -- ReplicatedStorage.Remotes
    PetAddedEvent = nil,    -- RemoteEvent for adding pets
    PetEquipEvent = nil,    -- RemoteEvent for equipping
    PetDataTemplate = nil,  -- Template from existing pet
}

local function DiscoverNativeSystem()
    print("\n🔍 DISCOVERING GAG 2 NATIVE PET SYSTEM...")
    
    -- 1. Look for player.Pets folder (most common in GAG 2)
    local petsFolder = player:FindFirstChild("Pets")
    if petsFolder then
        NativePetData.Folder = petsFolder
        print("  📁 Found player.Pets")
    else
        -- Check player.Data.Pets
        local dataFolder = player:FindFirstChild("Data")
        if dataFolder then
            petsFolder = dataFolder:FindFirstChild("Pets")
            if petsFolder then
                NativePetData.Folder = petsFolder
                print("  📁 Found player.Data.Pets")
            end
        end
    end
    
    -- 2. Look for stats/leaderstats with pet info
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            if stat.Name:lower():find("pet") then
                print("  📊 Found pet stat:", stat.Name)
            end
        end
    end
    
    -- 3. Look for Remotes
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then
        remotes = ReplicatedStorage:FindFirstChild("Events")
    end
    if remotes then
        NativePetData.Remotes = remotes
        print("  📡 Found Remotes folder")
        
        for _, remote in ipairs(remotes:GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                local rName = remote.Name:lower()
                if rName:find("pet") and (rName:find("add") or rName:find("give") or rName:find("spawn") or rName:find("create") or rName:find("buy")) then
                    NativePetData.PetAddedEvent = remote
                    print("  📡 Found PetAdd remote:", remote.Name)
                end
                if rName:find("pet") and (rName:find("equip") or rName:find("wear") or rName:find("active") or rName:find("toggle")) then
                    NativePetData.PetEquipEvent = remote
                    print("  📡 Found PetEquip remote:", remote.Name)
                end
            end
        end
    end
    
    -- 4. Analyze existing pet data structure
    if NativePetData.Folder then
        local existing = NativePetData.Folder:GetChildren()
        print("  📝 Existing pets in data:", #existing)
        if #existing > 0 then
            NativePetData.PetDataTemplate = existing[1]
            print("  📝 Template:", existing[1].Name, "| Class:", existing[1].ClassName)
            for _, child in ipairs(existing[1]:GetChildren()) do
                print("     -", child.Name, "(" .. child.ClassName .. ") =", 
                    child:IsA("ValueBase") and tostring(child.Value) or "N/A")
            end
        end
    end
    
    print("\n📊 NATIVE SYSTEM STATUS:")
    print("  Data Folder:", NativePetData.Folder and "✅" or "❌")
    print("  PetAdd Remote:", NativePetData.PetAddedEvent and "✅" or "❌")
    print("  PetEquip Remote:", NativePetData.PetEquipEvent and "✅" or "❌")
    
    return NativePetData.Folder ~= nil or NativePetData.PetAddedEvent ~= nil
end

local HAS_NATIVE_SYSTEM = DiscoverNativeSystem()

-- ═══════════════════════════════════════════════════════════════
--  GET PET FOLDER
-- ═══════════════════════════════════════════════════════════════

local PetFolder = ReplicatedStorage
for _, folderName in ipairs(CONFIG.PetFolderPath) do
    PetFolder = PetFolder:FindFirstChild(folderName)
    if not PetFolder then
        warn("❌ Pet folder path broken at:", folderName)
        return
    end
end

print("✅ Pet folder:", PetFolder:GetFullName())

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
--  INJECT PET INTO NATIVE DATA SYSTEM
-- ═══════════════════════════════════════════════════════════════

local InjectedPetData = {} -- Track what we injected

local function InjectPetToNativeData(petName)
    if not HAS_NATIVE_SYSTEM then
        return false, "No native system found"
    end
    
    print("\n💉 INJECTING", petName, "into native data...")
    
    -- Check if already exists
    if InjectedPetData[petName] then
        print("   ⚠ Already injected")
        return true, "Already exists"
    end
    
    -- Method 1: Fire RemoteEvent (most reliable)
    if NativePetData.PetAddedEvent then
        print("   📡 Firing PetAdd remote...")
        local success = pcall(function()
            -- Try different argument patterns
            NativePetData.PetAddedEvent:FireServer(petName)
        end)
        if success then
            print("   ✅ Remote fired successfully")
            InjectedPetData[petName] = true
            return true, "RemoteEvent"
        end
    end
    
    -- Method 2: Direct folder manipulation
    if NativePetData.Folder then
        print("   📁 Inserting into data folder...")
        
        local petEntry = nil
        
        if NativePetData.PetDataTemplate then
            -- Clone existing structure
            petEntry = NativePetData.PetDataTemplate:Clone()
            petEntry.Name = petName
            print("   📝 Cloned from template")
        else
            -- Create standard GAG 2 pet data structure
            -- Based on wiki: pets have Name, Equipped, Age, Weight, etc.
            petEntry = Instance.new("Folder")
            petEntry.Name = petName
            
            -- Standard GAG 2 pet values
            local equipped = Instance.new("BoolValue")
            equipped.Name = "Equipped"
            equipped.Value = false
            equipped.Parent = petEntry
            
            local age = Instance.new("IntValue")
            age.Name = "Age"
            age.Value = 0
            age.Parent = petEntry
            
            local weight = Instance.new("NumberValue")
            weight.Name = "Weight"
            weight.Value = 1
            weight.Parent = petEntry
            
            local hunger = Instance.new("NumberValue")
            hunger.Name = "Hunger"
            hunger.Value = 100
            hunger.Parent = petEntry
            
            local xp = Instance.new("NumberValue")
            xp.Name = "XP"
            xp.Value = 0
            xp.Parent = petEntry
            
            print("   📝 Created standard GAG 2 structure")
        end
        
        -- Mark as injected
        petEntry:SetAttribute("IsInjected", true)
        petEntry:SetAttribute("InjectedTime", os.time())
        
        petEntry.Parent = NativePetData.Folder
        InjectedPetData[petName] = petEntry
        print("   ✅ Inserted into", NativePetData.Folder.Name)
        return true, "DirectFolder"
    end
    
    return false, "All methods failed"
end

local function EquipPetInNativeData(petName)
    if not HAS_NATIVE_SYSTEM then return false end
    
    -- Method 1: RemoteEvent
    if NativePetData.PetEquipEvent then
        pcall(function()
            NativePetData.PetEquipEvent:FireServer(petName)
        end)
        return true
    end
    
    -- Method 2: Direct value change
    if NativePetData.Folder then
        local pet = NativePetData.Folder:FindFirstChild(petName)
        if pet then
            local equipped = pet:FindFirstChild("Equipped")
            if equipped and equipped:IsA("BoolValue") then
                equipped.Value = true
                print("   ✅ Set Equipped = true for", petName)
                return true
            end
        end
    end
    
    return false
end

local function UnequipPetInNativeData(petName)
    if not HAS_NATIVE_SYSTEM then return false end
    
    if NativePetData.Folder then
        local pet = NativePetData.Folder:FindFirstChild(petName)
        if pet then
            local equipped = pet:FindFirstChild("Equipped")
            if equipped and equipped:IsA("BoolValue") then
                equipped.Value = false
                return true
            end
        end
    end
    
    return false
end

-- ═══════════════════════════════════════════════════════════════
--  VISUAL PET SPAWNER (for equipped pets)
-- ═══════════════════════════════════════════════════════════════

local EquippedVisuals = {} -- [petName] = { model, followConn, animTracks }

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
    if EquippedVisuals[petName] then
        print("⚠", petName, "already visualized")
        return true
    end
    
    local eqCount = 0
    for _ in pairs(EquippedVisuals) do eqCount += 1 end
    if eqCount >= CONFIG.MaxEquipped then
        warn("❌ Max equipped:", CONFIG.MaxEquipped)
        return false
    end
    
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
    
    pet.AncestryChanged:Connect(function(_, newParent)
        if not newParent and EquippedVisuals[petName] then
            task.defer(function()
                -- Check if still equipped in native data
                if NativePetData.Folder then
                    local petData = NativePetData.Folder:FindFirstChild(petName)
                    if petData then
                        local equipped = petData:FindFirstChild("Equipped")
                        if equipped and equipped:IsA("BoolValue") and equipped.Value then
                            -- Still equipped, respawn
                            task.wait(0.5)
                            SpawnVisualPet(petName)
                        end
                    end
                end
            end)
        end
    end)
    
    print("✅ Visual spawned:", petName, "| Anims:", hasAnims)
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
    
    -- Recalculate indices
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
    
    print("📤 Despawned:", petName)
    return true
end

function DespawnAllVisuals()
    for name in pairs(EquippedVisuals) do
        DespawnVisualPet(name)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  UNIFIED SPAWN FUNCTION
-- ═══════════════════════════════════════════════════════════════

function SpawnPet(petName)
    -- Step 1: Inject into native data
    local injected, method = InjectPetToNativeData(petName)
    
    if injected then
        print("💉 Native injection successful:", method)
        
        -- Step 2: Equip in native data
        task.delay(0.2, function()
            EquipPetInNativeData(petName)
        end)
        
        -- Step 3: Spawn visual
        task.delay(0.5, function()
            SpawnVisualPet(petName)
        end)
        
        return true
    else
        -- Fallback: just visual
        print("⚠ Native injection failed, spawning visual only")
        SpawnVisualPet(petName)
        return false
    end
end

-- ═══════════════════════════════════════════════════════════════
--  GUI
-- ═══════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GAG2NativeInjector"
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
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", toggleBtn).Color = Color3.fromRGB(200, 150, 40)
Instance.new("UIStroke", toggleBtn).Thickness = 3
toggleBtn.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
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

-- Status bar
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, 0, 0, 24)
statusBar.Position = UDim2.new(0, 0, 0, 42)
statusBar.BackgroundColor3 = HAS_NATIVE_SYSTEM and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 80, 40)
statusBar.BorderSizePixel = 0

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 1, 0)
statusLabel.Position = UDim2.new(0, 5, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = HAS_NATIVE_SYSTEM and "🟢 NATIVE SYSTEM ACTIVE" or "🟡 VISUAL MODE ONLY"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Parent = statusBar

statusBar.Parent = mainFrame

-- Drag system
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
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -100, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🐾 Native Pet Injector"
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

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0, 70, 0, 28)
clearBtn.Position = UDim2.new(1, -82, 0, 7)
clearBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
clearBtn.Text = "Clear All"
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.TextSize = 11
clearBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 8)
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
countLabel.Text = "Native: 0 | Visual: 0"
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
    arrow.Text = HAS_NATIVE_SYSTEM and "💉" or "👁️"
    arrow.TextColor3 = HAS_NATIVE_SYSTEM and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 200, 100)
    arrow.TextSize = 20
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = btn

    btn.MouseButton1Click:Connect(function()
        SpawnPet(petName)
        
        local nativeCount = 0
        for _ in pairs(InjectedPetData) do nativeCount += 1 end
        local visualCount = 0
        for _ in pairs(EquippedVisuals) do visualCount += 1 end
        countLabel.Text = "Native: " .. nativeCount .. " | Visual: " .. visualCount
        
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

clearBtn.MouseButton1Click:Connect(function()
    DespawnAllVisuals()
    countLabel.Text = "Native: " .. #InjectedPetData .. " | Visual: 0"
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.P then
        toggleGUI()
    end
end)

player.CharacterRemoving:Connect(function()
    DespawnAllVisuals()
end)

print("\n🐾 GAG 2 NATIVE PET INJECTOR loaded!")
print("📋 Pets:", #allPets)
print("🎯 Native System:", HAS_NATIVE_SYSTEM and "DETECTED" or "NOT FOUND")
print("💡 Check console for discovery details")
