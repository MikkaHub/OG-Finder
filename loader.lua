-- ═══════════════════════════════════════════════════════════════
--  GAG 2 - PET SPAWNER v2 (Inventory + Equip System)
--  Fixes: Animations via Humanoid, Inventory-first flow
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
    MaxEquipped = 8,      -- Max pets following you at once
    MaxInventory = 60,    -- Max pets in inventory
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
--  DATA STRUCTURES
-- ═══════════════════════════════════════════════════════════════

-- Inventory: { [petId] = { name = "IceSerpent", equipped = false, id = "uuid" } }
-- Equipped: { [petId] = { model = Model, followConn = Connection, animTracks = {} } }
local Inventory = {}
local EquippedPets = {}
local nextId = 1

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
--  GET GROUND HEIGHT
-- ═══════════════════════════════════════════════════════════════

local function GetGroundHeight(position)
    local rayOrigin = position + Vector3.new(0, 100, 0)
    local rayDirection = Vector3.new(0, -200, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local filterList = {}
    for _, petData in pairs(EquippedPets) do
        if petData.model and petData.model.Parent then
            table.insert(filterList, petData.model)
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

-- ═══════════════════════════════════════════════════════════════
--  CLONE PET (for world spawning)
-- ═══════════════════════════════════════════════════════════════

local function ClonePetForWorld(petName)
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

    -- Setup all parts
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
            part.CanQuery = false
            
            if part.Transparency >= 1 then
                part.Transparency = 0
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
--  CLONE PET FOR VIEWPORT (for inventory preview)
-- ═══════════════════════════════════════════════════════════════

local function ClonePetForViewport(petName)
    local template = PetFolder:FindFirstChild(petName)
    if not template then return nil end
    
    local clone = template:Clone()
    
    -- Strip scripts, keep visuals only
    for _, desc in ipairs(clone:GetDescendants()) do
        if desc:IsA("Script") or desc:IsA("LocalScript") then
            desc:Destroy()
        elseif desc:IsA("BasePart") then
            desc.Anchored = true
            desc.CanCollide = false
            if desc.Transparency >= 1 then
                desc.Transparency = 0
            end
        elseif desc:IsA("Decal") or desc:IsA("Texture") then
            desc.Transparency = 0
        end
    end
    
    -- Restore PrimaryPart for camera framing
    if template.PrimaryPart then
        local pp = clone:FindFirstChild(template.PrimaryPart.Name)
        if pp then
            clone.PrimaryPart = pp
        end
    end
    
    return clone
end

-- ═══════════════════════════════════════════════════════════════
--  ANIMATION SYSTEM (Fixed - uses Humanoid:LoadAnimation)
-- ═══════════════════════════════════════════════════════════════

local function StartAnimations(pet, petName)
    print("\n--- ANIMATIONS for", petName, "---")
    
    local animTracks = {}
    local playedAny = false
    
    -- Find or create Humanoid (needed for LoadAnimation)
    local humanoid = pet:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        humanoid = Instance.new("Humanoid")
        humanoid.Name = "Humanoid"
        humanoid.Health = 100
        humanoid.MaxHealth = 100
        humanoid.Parent = pet
        print("📎 Created Humanoid for animations")
    else
        print("📎 Found existing Humanoid")
    end
    
    -- Find the "Animations" folder inside the pet
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
    
    -- Helper to load and play animation
    local function loadAndPlay(animObj, source)
        if not animObj:IsA("Animation") or animObj.AnimationId == "" then return false end
        
        print("  🎬", source .. ":", animObj.Name, "ID:", animObj.AnimationId:sub(1, 40))
        
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
                -- Don't auto-play, just load for later
                print("     📥 LOADED (Movement)")
                table.insert(animTracks, track)
                return true
                
            elseif name:find("jump") or name:find("fall") then
                track.Looped = false
                track.Priority = Enum.AnimationPriority.Action
                -- Don't auto-play
                print("     📥 LOADED (Action)")
                table.insert(animTracks, track)
                return true
                
            else
                -- Default: play as action
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
    
    -- Step 1: Scan Animations folder descendants
    if animationsFolder then
        print("🎬 Scanning Animations folder...")
        for _, animObj in ipairs(animationsFolder:GetDescendants()) do
            loadAndPlay(animObj, "folder")
        end
        -- Also check direct children
        for _, animObj in ipairs(animationsFolder:GetChildren()) do
            loadAndPlay(animObj, "direct")
        end
    end
    
    -- Step 2: Fallback - search entire pet for Animation objects
    if not playedAny then
        print("🔍 Searching entire pet for animations...")
        for _, desc in ipairs(pet:GetDescendants()) do
            if desc:IsA("Animation") and desc.AnimationId ~= "" then
                -- Skip if already loaded from Animations folder
                local alreadyLoaded = false
                for _, track in ipairs(animTracks) do
                    if track.Animation == desc then
                        alreadyLoaded = true
                        break
                    end
                end
                if not alreadyLoaded then
                    loadAndPlay(desc, "fallback")
                end
            end
        end
    end
    
    -- Step 3: If still no animations, try Animate script
    if not playedAny then
        local animate = pet:FindFirstChild("Animate")
        if animate and animate:IsA("Script") then
            print("📜 Found Animate script, enabling...")
            local newAnimate = animate:Clone()
            animate:Destroy()
            newAnimate.Parent = pet
            newAnimate.Disabled = false
            playedAny = true
            print("  ▶ Enabled Animate script")
        end
    end
    
    if not playedAny then
        warn("⚠ NO ANIMATIONS PLAYED for", petName)
    else
        print("✅ Animations active | Tracks:", #animTracks)
    end
    
    print("---\n")
    return playedAny, animTracks
end

-- ═══════════════════════════════════════════════════════════════
--  FOLLOW SYSTEM
-- ═══════════════════════════════════════════════════════════════

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
        
        -- Bee/Firefly face fix
        local petName = pet:GetAttribute("PetName") or ""
        if petName == "Bee" or petName == "Firefly" then
            newCF = newCF * CFrame.Angles(0, math.pi, 0)
        end

        pet:PivotTo(newCF)
    end)

    return followConn
end

-- ═══════════════════════════════════════════════════════════════
--  INVENTORY SYSTEM
-- ═══════════════════════════════════════════════════════════════

function AddToInventory(petName)
    if #Inventory >= CONFIG.MaxInventory then
        warn("❌ Inventory full! Max:", CONFIG.MaxInventory)
        return nil
    end
    
    local id = tostring(nextId)
    nextId += 1
    
    local petData = {
        id = id,
        name = petName,
        equipped = false,
    }
    
    Inventory[id] = petData
    print("📦 Added to inventory:", petName, "| ID:", id, "| Total:", #Inventory)
    
    return id
end

function RemoveFromInventory(petId)
    local petData = Inventory[petId]
    if not petData then return false end
    
    -- Unequip first if equipped
    if petData.equipped then
        UnequipPet(petId)
    end
    
    Inventory[petId] = nil
    print("🗑️ Removed from inventory:", petData.name, "| ID:", petId)
    return true
end

function EquipPet(petId)
    local petData = Inventory[petId]
    if not petData then
        warn("❌ Pet not found in inventory:", petId)
        return false
    end
    
    if petData.equipped then
        print("⚠ Already equipped:", petData.name)
        return true
    end
    
    -- Check max equipped
    local equippedCount = 0
    for _, p in pairs(Inventory) do
        if p.equipped then equippedCount += 1 end
    end
    
    if equippedCount >= CONFIG.MaxEquipped then
        warn("❌ Max equipped reached:", CONFIG.MaxEquipped)
        return false
    end
    
    print("\n========== EQUIPPING:", petData.name, "==========")
    
    -- Spawn in world
    local pet = ClonePetForWorld(petData.name)
    if not pet then
        warn("❌ Clone failed")
        return false
    end
    
    local char = player.Character
    if not char then
        warn("❌ Character not loaded")
        pet:Destroy()
        return false
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
    
    -- Calculate follow index
    local followIndex = equippedCount + 1
    
    -- Start animations
    local hasAnims, animTracks = StartAnimations(pet, petData.name)
    
    -- Start following
    local followConn = FollowPlayer(pet, followIndex)
    
    -- Store equipped data
    EquippedPets[petId] = {
        model = pet,
        followConn = followConn,
        animTracks = animTracks or {},
    }
    
    petData.equipped = true
    
    -- Cleanup on destroy
    pet.AncestryChanged:Connect(function(_, newParent)
        if not newParent then
            -- Pet was destroyed externally, unequip it
            if Inventory[petId] and Inventory[petId].equipped then
                task.defer(function()
                    UnequipPet(petId)
                end)
            end
        end
    end)
    
    print("✅ EQUIPPED:", petData.name, "| Anims:", hasAnims, "| FollowIndex:", followIndex)
    print("================================\n")
    
    return true
end

function UnequipPet(petId)
    local petData = Inventory[petId]
    if not petData or not petData.equipped then
        return false
    end
    
    local equippedData = EquippedPets[petId]
    if equippedData then
        -- Stop animations
        for _, track in ipairs(equippedData.animTracks) do
            pcall(function()
                track:Stop()
                track:Destroy()
            end)
        end
        
        -- Disconnect follow
        if equippedData.followConn then
            equippedData.followConn:Disconnect()
        end
        
        -- Destroy model
        if equippedData.model then
            equippedData.model:Destroy()
        end
        
        EquippedPets[petId] = nil
    end
    
    petData.equipped = false
    print("📤 Unequipped:", petData.name, "| ID:", petId)
    
    -- Recalculate follow positions for remaining pets
    task.delay(0.1, function()
        local index = 1
        for id, eqData in pairs(EquippedPets) do
            if eqData.followConn then
                eqData.followConn:Disconnect()
            end
            eqData.followConn = FollowPlayer(eqData.model, index)
            index += 1
        end
    end)
    
    return true
end

function UnequipAll()
    local toUnequip = {}
    for id, petData in pairs(Inventory) do
        if petData.equipped then
            table.insert(toUnequip, id)
        end
    end
    for _, id in ipairs(toUnequip) do
        UnequipPet(id)
    end
end

function ClearInventory()
    UnequipAll()
    Inventory = {}
    nextId = 1
    print("❌ Inventory cleared")
end

-- ═══════════════════════════════════════════════════════════════
--  GUI CREATION
-- ═══════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GAG2PetSpawner"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Toggle Button
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

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, 350, 0, 450)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -225)
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

-- DRAG SYSTEM
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

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
titleBar.BorderSizePixel = 0

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 14)
tbCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -120, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🐾 Pet Inventory"
titleLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

titleBar.Parent = mainFrame

-- Close Button
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

-- Tab Buttons (Inventory / Spawn)
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, -16, 0, 36)
tabFrame.Position = UDim2.new(0, 8, 0, 44)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.Parent = tabFrame

local invTab = Instance.new("TextButton")
invTab.Name = "InventoryTab"
invTab.Size = UDim2.new(0.5, -3, 1, 0)
invTab.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
invTab.Text = "📦 Inventory"
invTab.TextColor3 = Color3.fromRGB(255, 255, 255)
invTab.TextSize = 13
invTab.Font = Enum.Font.GothamBold

local invTabCorner = Instance.new("UICorner")
invTabCorner.CornerRadius = UDim.new(0, 8)
invTabCorner.Parent = invTab

invTab.Parent = tabFrame

local spawnTab = Instance.new("TextButton")
spawnTab.Name = "SpawnTab"
spawnTab.Size = UDim2.new(0.5, -3, 1, 0)
spawnTab.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
spawnTab.Text = "➕ Spawn New"
spawnTab.TextColor3 = Color3.fromRGB(200, 200, 200)
spawnTab.TextSize = 13
spawnTab.Font = Enum.Font.GothamBold

local spawnTabCorner = Instance.new("UICorner")
spawnTabCorner.CornerRadius = UDim.new(0, 8)
spawnTabCorner.Parent = spawnTab

spawnTab.Parent = tabFrame

-- Content Frames
local invContent = Instance.new("Frame")
invContent.Name = "InventoryContent"
invContent.Size = UDim2.new(1, -16, 1, -140)
invContent.Position = UDim2.new(0, 8, 0, 84)
invContent.BackgroundTransparency = 1
invContent.Visible = true
invContent.Parent = mainFrame

local spawnContent = Instance.new("Frame")
spawnContent.Name = "SpawnContent"
spawnContent.Size = UDim2.new(1, -16, 1, -140)
spawnContent.Position = UDim2.new(0, 8, 0, 84)
spawnContent.BackgroundTransparency = 1
spawnContent.Visible = false
spawnContent.Parent = mainFrame

-- Inventory Scroll
local invScroll = Instance.new("ScrollingFrame")
invScroll.Size = UDim2.new(1, 0, 1, 0)
invScroll.BackgroundTransparency = 1
invScroll.BorderSizePixel = 0
invScroll.ScrollBarThickness = 5
invScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
invScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
invScroll.Parent = invContent

local invGrid = Instance.new("UIGridLayout")
invGrid.CellSize = UDim2.new(0, 100, 0, 120)
invGrid.CellPadding = UDim2.new(0, 8, 0, 8)
invGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
invGrid.Parent = invScroll

-- Spawn Scroll
local spawnScroll = Instance.new("ScrollingFrame")
spawnScroll.Size = UDim2.new(1, 0, 1, 0)
spawnScroll.BackgroundTransparency = 1
spawnScroll.BorderSizePixel = 0
spawnScroll.ScrollBarThickness = 5
spawnScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
spawnScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
spawnScroll.Parent = spawnContent

local spawnList = Instance.new("UIListLayout")
spawnList.Padding = UDim.new(0, 6)
spawnList.HorizontalAlignment = Enum.HorizontalAlignment.Center
spawnList.Parent = spawnScroll

-- Stats Bar
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1, -16, 0, 50)
statsFrame.Position = UDim2.new(0, 8, 1, -58)
statsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)

local sfCorner = Instance.new("UICorner")
sfCorner.CornerRadius = UDim.new(0, 10)
sfCorner.Parent = statsFrame

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -10, 1, 0)
statsLabel.Position = UDim2.new(0, 5, 0, 0)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = "Inventory: 0/60 | Equipped: 0/8"
statsLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
statsLabel.TextSize = 13
statsLabel.Font = Enum.Font.Gotham
statsLabel.Parent = statsFrame

statsFrame.Parent = mainFrame

-- ═══════════════════════════════════════════════════════════════
--  GUI FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function updateStats()
    local invCount = 0
    local eqCount = 0
    for _, p in pairs(Inventory) do
        invCount += 1
        if p.equipped then eqCount += 1 end
    end
    statsLabel.Text = string.format("Inventory: %d/%d | Equipped: %d/%d", invCount, CONFIG.MaxInventory, eqCount, CONFIG.MaxEquipped)
end

local function createViewportForPet(petName, parent)
    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.new(1, 0, 0, 80)
    viewport.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    viewport.BorderSizePixel = 0
    
    local vCorner = Instance.new("UICorner")
    vCorner.CornerRadius = UDim.new(0, 8)
    vCorner.Parent = viewport
    
    -- Clone pet for viewport
    local petClone = ClonePetForViewport(petName)
    if petClone then
        petClone.Parent = viewport
        
        local camera = Instance.new("Camera")
        camera.Parent = viewport
        viewport.CurrentCamera = camera
        
        -- Frame the pet
        task.defer(function()
            task.wait(0.1)
            if petClone and petClone.Parent then
                local cf, size = petClone:GetBoundingBox()
                local maxDim = math.max(size.X, size.Y, size.Z)
                local dist = maxDim * 2.5
                if dist < 3 then dist = 3 end
                if dist > 15 then dist = 15 end
                
                camera.CFrame = CFrame.new(cf.Position + Vector3.new(0, 0, dist), cf.Position)
                camera.FieldOfView = 30
            end
        end)
    end
    
    viewport.Parent = parent
    return viewport
end

local function refreshInventory()
    -- Clear existing
    for _, child in ipairs(invScroll:GetChildren()) do
        if not child:IsA("UIGridLayout") then
            child:Destroy()
        end
    end
    
    -- Add inventory items
    for id, petData in pairs(Inventory) do
        local card = Instance.new("Frame")
        card.Name = "PetCard_" .. id
        card.Size = UDim2.new(0, 100, 0, 120)
        card.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 10)
        cardCorner.Parent = card
        
        -- Equipped indicator
        if petData.equipped then
            card.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
        end
        
        -- Viewport
        createViewportForPet(petData.name, card)
        
        -- Name label
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -4, 0, 20)
        nameLabel.Position = UDim2.new(0, 2, 0, 82)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = petData.name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 11
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = card
        
        -- Equip/Unequip button
        local actionBtn = Instance.new("TextButton")
        actionBtn.Size = UDim2.new(1, -8, 0, 24)
        actionBtn.Position = UDim2.new(0, 4, 0, 92)
        actionBtn.BackgroundColor3 = petData.equipped and Color3.fromRGB(200, 60, 60) or Color3.fromRGB(60, 150, 60)
        actionBtn.Text = petData.equipped and "Unequip" or "Equip"
        actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        actionBtn.TextSize = 11
        actionBtn.Font = Enum.Font.GothamBold
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = actionBtn
        
        actionBtn.Parent = card
        
        actionBtn.MouseButton1Click:Connect(function()
            if petData.equipped then
                UnequipPet(id)
            else
                EquipPet(id)
            end
            refreshInventory()
            updateStats()
        end)
        
        -- Delete button (X)
        local delBtn = Instance.new("TextButton")
        delBtn.Size = UDim2.new(0, 20, 0, 20)
        delBtn.Position = UDim2.new(1, -22, 0, 2)
        delBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
        delBtn.Text = "×"
        delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        delBtn.TextSize = 14
        delBtn.Font = Enum.Font.GothamBold
        
        local delCorner = Instance.new("UICorner")
        delCorner.CornerRadius = UDim.new(1, 0)
        delCorner.Parent = delBtn
        
        delBtn.Parent = card
        
        delBtn.MouseButton1Click:Connect(function()
            RemoveFromInventory(id)
            refreshInventory()
            updateStats()
        end)
        
        card.Parent = invScroll
    end
    
    updateStats()
end

local function refreshSpawnList()
    -- Clear existing
    for _, child in ipairs(spawnScroll:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    
    local allPets = GetAllPetNames()
    
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
            local id = AddToInventory(petName)
            if id then
                refreshInventory()
                updateStats()
                
                btn.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
                task.wait(0.2)
                btn.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
                
                -- Auto-switch to inventory tab
                invTab.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
                invTab.TextColor3 = Color3.fromRGB(255, 255, 255)
                spawnTab.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
                spawnTab.TextColor3 = Color3.fromRGB(200, 200, 200)
                invContent.Visible = true
                spawnContent.Visible = false
                refreshInventory()
            end
        end)

        btn.Parent = spawnScroll
    end
end

-- Tab switching
invTab.MouseButton1Click:Connect(function()
    invTab.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    invTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    spawnTab.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
    spawnTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    invContent.Visible = true
    spawnContent.Visible = false
    refreshInventory()
end)

spawnTab.MouseButton1Click:Connect(function()
    spawnTab.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    spawnTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    invTab.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
    invTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    spawnContent.Visible = true
    invContent.Visible = false
    refreshSpawnList()
end)

-- Clear All button
local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0, 80, 0, 28)
clearBtn.Position = UDim2.new(1, -92, 0, 7)
clearBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
clearBtn.Text = "Clear All"
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.TextSize = 11
clearBtn.Font = Enum.Font.GothamBold

local clCorner = Instance.new("UICorner")
clCorner.CornerRadius = UDim.new(0, 8)
clCorner.Parent = clearBtn

clearBtn.Parent = titleBar

clearBtn.MouseButton1Click:Connect(function()
    ClearInventory()
    refreshInventory()
    updateStats()
end)

-- Unequip All button
local unequipAllBtn = Instance.new("TextButton")
unequipAllBtn.Size = UDim2.new(0, 90, 0, 28)
unequipAllBtn.Position = UDim2.new(1, -186, 0, 7)
unequipAllBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 40)
unequipAllBtn.Text = "Unequip All"
unequipAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
unequipAllBtn.TextSize = 11
unequipAllBtn.Font = Enum.Font.GothamBold

local uaCorner = Instance.new("UICorner")
uaCorner.CornerRadius = UDim.new(0, 8)
uaCorner.Parent = unequipAllBtn

unequipAllBtn.Parent = titleBar

unequipAllBtn.MouseButton1Click:Connect(function()
    UnequipAll()
    refreshInventory()
    updateStats()
end)

-- ═══════════════════════════════════════════════════════════════
--  TOGGLE GUI
-- ═══════════════════════════════════════════════════════════════

local function toggleGUI()
    if mainFrame.Visible then
        TweenService:Create(mainFrame, TweenInfo.new(0.18), {
            Size = UDim2.new(0, 350, 0, 0),
            Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 0.5, 0)
        }):Play()
        task.wait(0.18)
        mainFrame.Visible = false
    else
        mainFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 350, 0, 0)
        TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 350, 0, 450),
            Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset)
        }):Play()
        refreshInventory()
    end
end

toggleBtn.MouseButton1Click:Connect(toggleGUI)
closeBtn.MouseButton1Click:Connect(toggleGUI)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.P then
        toggleGUI()
    end
end)

-- Character reset cleanup
player.CharacterRemoving:Connect(function()
    UnequipAll()
end)

-- ═══════════════════════════════════════════════════════════════
--  INIT
-- ═══════════════════════════════════════════════════════════════

refreshSpawnList()
refreshInventory()

print("🐾 GAG 2 Pet Spawner v2 loaded!")
print("📋 Pets available:", #GetAllPetNames())
print("📦 Inventory system active | Press P or click 🐾")
