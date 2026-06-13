-- ═══════════════════════════════════════════════════════════════
--  GAG 2 - NATIVE BACKPACK PET INJECTOR
--  Injects pets into: PlayerGui.BackpackGui.Backpack.Inventory
--  Equip from real inventory → spawns in-world with animations
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
    BackpackPath = {"PlayerGui", "BackpackGui", "Backpack", "Inventory"},
    FollowDistance = 4,
    HeightAboveGround = 1,
    FollowSmoothness = 0.1,
    MaxEquipped = 8,
}

-- ═══════════════════════════════════════════════════════════════
--  GET NATIVE BACKPACK INVENTORY
-- ═══════════════════════════════════════════════════════════════

local function GetBackpackInventory()
    local current = player
    for _, name in ipairs(CONFIG.BackpackPath) do
        current = current:FindFirstChild(name)
        if not current then
            warn("❌ Backpack path broken at:", name)
            return nil
        end
    end
    return current
end

local BackpackInventory = GetBackpackInventory()
local HAS_REAL_INVENTORY = BackpackInventory ~= nil

print("🎒 Backpack Inventory:", HAS_REAL_INVENTORY and "✅ FOUND" or "❌ NOT FOUND")
if BackpackInventory then
    print("   Path:", BackpackInventory:GetFullName())
    print("   Children:", #BackpackInventory:GetChildren())
end

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
--  ANALYZE BACKPACK STRUCTURE
-- ═══════════════════════════════════════════════════════════════

local BackpackTemplate = nil
local BackpackItemClass = "Frame" -- Default guess

local function AnalyzeBackpack()
    if not BackpackInventory then return end
    
    print("\n🔍 Analyzing backpack structure...")
    
    local children = BackpackInventory:GetChildren()
    print("   Items in backpack:", #children)
    
    -- Find a template item to clone structure from
    for _, child in ipairs(children) do
        if child:IsA("GuiObject") then
            BackpackTemplate = child
            BackpackItemClass = child.ClassName
            print("   Found template:", child.Name, "| Class:", child.ClassName)
            print("   Template children:")
            for _, desc in ipairs(child:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("ImageLabel") or desc:IsA("TextButton") then
                    print("      -", desc.Name, "(" .. desc.ClassName .. ")")
                end
            end
            break
        end
    end
    
    -- Look for pet-related values
    for _, child in ipairs(children) do
        local name = child.Name:lower()
        if name:find("pet") or name:find("companion") then
            print("   Found existing pet item:", child.Name)
            BackpackTemplate = child
            break
        end
    end
end

if HAS_REAL_INVENTORY then
    AnalyzeBackpack()
end

-- ═══════════════════════════════════════════════════════════════
--  INJECT PET INTO REAL BACKPACK
-- ═══════════════════════════════════════════════════════════════

local InjectedPets = {} -- Track what we injected

local function InjectPetToBackpack(petName)
    if not BackpackInventory then
        return false, "No backpack inventory"
    end
    
    print("\n💉 Injecting", petName, "into backpack...")
    
    -- Check if already injected
    if InjectedPets[petName] then
        print("   ⚠ Already injected, reusing")
        return true, "Already exists"
    end
    
    -- Try to clone existing template
    if BackpackTemplate then
        local clone = BackpackTemplate:Clone()
        clone.Name = petName
        
        -- Update text labels to show pet name
        for _, desc in ipairs(clone:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                if desc.Name:lower():find("name") or desc.Name:lower():find("title") or desc.Name:lower():find("label") then
                    desc.Text = petName
                end
            end
            if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
                if desc.Name:lower():find("icon") or desc.Name:lower():find("image") or desc.Name:lower():find("pet") then
                    -- Try to set pet image if available
                    -- GAG 2 might use asset IDs, we can't guess those
                end
            end
        end
        
        -- Add custom attributes so we can identify our injected pets
        clone:SetAttribute("IsInjectedPet", true)
        clone:SetAttribute("PetName", petName)
        
        -- Add click handler for equipping
        local clickTarget = clone
        if clone:IsA("TextButton") or clone:IsA("ImageButton") then
            clickTarget = clone
        else
            -- Find a button inside
            for _, desc in ipairs(clone:GetDescendants()) do
                if desc:IsA("TextButton") or desc:IsA("ImageButton") then
                    clickTarget = desc
                    break
                end
            end
        end
        
        -- Store original click if any
        local originalClick = nil
        if clickTarget:IsA("GuiButton") then
            -- We can't easily hook existing connections, but we can add our own
            clickTarget.MouseButton1Click:Connect(function()
                print("🖱️ Clicked injected pet:", petName)
                EquipPet(petName)
            end)
        end
        
        clone.Parent = BackpackInventory
        InjectedPets[petName] = clone
        print("   ✅ Cloned template into backpack")
        return true, "TemplateClone"
    end
    
    -- Fallback: Create minimal Frame
    print("   📁 Creating minimal entry...")
    local entry = Instance.new("Frame")
    entry.Name = petName
    entry.Size = UDim2.new(0, 80, 0, 80)
    entry.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    entry:SetAttribute("IsInjectedPet", true)
    entry:SetAttribute("PetName", petName)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = entry
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 1, -20)
    label.BackgroundTransparency = 1
    label.Text = petName
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 10
    label.Font = Enum.Font.GothamBold
    label.Parent = entry
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = entry
    
    btn.MouseButton1Click:Connect(function()
        print("🖱️ Clicked injected pet:", petName)
        EquipPet(petName)
    end)
    
    entry.Parent = BackpackInventory
    InjectedPets[petName] = entry
    print("   ✅ Created minimal entry")
    return true, "MinimalFrame"
end

-- ═══════════════════════════════════════════════════════════════
--  VISUAL PET SPAWNER (World + Animations)
-- ═══════════════════════════════════════════════════════════════

local EquippedPets = {} -- [petName] = { model, followConn, animTracks }

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

-- FIXED ANIMATION SYSTEM
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
        local pName = pet:GetAttribute("PetName") or ""
        if pName == "Bee" or pName == "Firefly" then
            newCF = newCF * CFrame.Angles(0, math.pi, 0)
        end
        
        pet:PivotTo(newCF)
    end)
    return followConn
end

-- ═══════════════════════════════════════════════════════════════
--  EQUIP / UNEQUIP
-- ═══════════════════════════════════════════════════════════════

function EquipPet(petName)
    -- Check if already equipped
    if EquippedPets[petName] then
        print("⚠", petName, "already equipped")
        return true
    end
    
    -- Check max equipped
    local eqCount = 0
    for _ in pairs(EquippedPets) do eqCount += 1 end
    if eqCount >= CONFIG.MaxEquipped then
        warn("❌ Max equipped:", CONFIG.MaxEquipped)
        return false
    end
    
    print("\n========== EQUIPPING:", petName, "==========")
    
    local pet = ClonePetForWorld(petName)
    if not pet then
        print("❌ Clone failed")
        return false
    end
    
    local char = player.Character
    if not char then
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
    
    local followIndex = eqCount + 1
    local hasAnims, animTracks = StartAnimations(pet, petName)
    local followConn = FollowPlayer(pet, followIndex)
    
    EquippedPets[petName] = {
        model = pet,
        followConn = followConn,
        animTracks = animTracks,
    }
    
    -- Highlight in backpack
    local injected = InjectedPets[petName]
    if injected then
        injected.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
    end
    
    -- Cleanup on destroy
    pet.AncestryChanged:Connect(function(_, newParent)
        if not newParent then
            if EquippedPets[petName] then
                UnequipPet(petName)
            end
        end
    end)
    
    print("✅ EQUIPPED:", petName, "| Anims:", hasAnims)
    print("================================\n")
    return true
end

function UnequipPet(petName)
    local petData = EquippedPets[petName]
    if not petData then return false end
    
    if petData.followConn then
        petData.followConn:Disconnect()
    end
    
    if petData.animTracks then
        for _, track in ipairs(petData.animTracks) do
            pcall(function() track:Stop() track:Destroy() end)
        end
    end
    
    if petData.model then
        petData.model:Destroy()
    end
    
    EquippedPets[petName] = nil
    
    -- Unhighlight in backpack
    local injected = InjectedPets[petName]
    if injected then
        injected.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    end
    
    -- Recalculate follow indices
    task.delay(0.1, function()
        local index = 1
        for _, data in pairs(EquippedPets) do
            if data.followConn then
                data.followConn:Disconnect()
                data.followConn = FollowPlayer(data.model, index)
                index += 1
            end
        end
    end)
    
    print("📤 Unequipped:", petName)
    return true
end

function UnequipAll()
    local toUnequip = {}
    for name in pairs(EquippedPets) do
        table.insert(toUnequip, name)
    end
    for _, name in ipairs(toUnequip) do
        UnequipPet(name)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  GUI
-- ═══════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GAG2BackpackInjector"
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

-- Status bar
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, 0, 0, 24)
statusBar.Position = UDim2.new(0, 0, 0, 42)
statusBar.BackgroundColor3 = HAS_REAL_INVENTORY and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 80, 40)
statusBar.BorderSizePixel = 0

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 1, 0)
statusLabel.Position = UDim2.new(0, 5, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = HAS_REAL_INVENTORY and "🟢 BACKPACK INJECTOR ACTIVE" or "🟡 VISUAL MODE ONLY"
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
titleLabel.Text = "🐾 Pet Injector"
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
countLabel.Text = "Equipped: 0 | In Backpack: 0"
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
    arrow.Text = HAS_REAL_INVENTORY and "💉" or "👁️"
    arrow.TextColor3 = HAS_REAL_INVENTORY and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 200, 100)
    arrow.TextSize = 20
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = btn

    btn.MouseButton1Click:Connect(function()
        -- Step 1: Inject to backpack
        if HAS_REAL_INVENTORY then
            InjectPetToBackpack(petName)
        end
        
        -- Step 2: Equip (spawn in world)
        EquipPet(petName)
        
        -- Update count
        local eqCount = 0
        for _ in pairs(EquippedPets) do eqCount += 1 end
        local invCount = 0
        for _ in pairs(InjectedPets) do invCount += 1 end
        countLabel.Text = "Equipped: " .. eqCount .. " | In Backpack: " .. invCount
        
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
    UnequipAll()
    local invCount = 0
    for _ in pairs(InjectedPets) do invCount += 1 end
    countLabel.Text = "Equipped: 0 | In Backpack: " .. invCount
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.P then
        toggleGUI()
    end
end)

player.CharacterRemoving:Connect(function()
    UnequipAll()
end)

print("\n🐾 GAG 2 BACKPACK PET INJECTOR loaded!")
print("📋 Pets:", #allPets)
print("🎒 Backpack:", HAS_REAL_INVENTORY and "ACTIVE" or "NOT FOUND")
print("💡 Click pet in injector → adds to backpack → auto-equips")
print("   Or open GAG 2 backpack and click injected pet to equip")
