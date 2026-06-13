-- ═══════════════════════════════════════════════════════════════
--  GAG 2 - NATIVE INVENTORY PET SPAWNER
--  Targets: PlayerGui.BackpackGui.Backpack.Inventory.SideBar.Pets
--           PlayerGui.EquipPet
--  Injects pets into REAL GAG 2 inventory, then equips with animations
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
    InventoryPath = {"PlayerGui", "BackpackGui", "Backpack", "Inventory", "SideBar", "Pets"},
    EquipGuiPath = {"PlayerGui", "EquipPet"},
    FollowDistance = 4,
    HeightAboveGround = 1,
    FollowSmoothness = 0.1,
    MaxEquipped = 8,
}

-- ═══════════════════════════════════════════════════════════════
--  GET NATIVE INVENTORY
-- ═══════════════════════════════════════════════════════════════

local function GetInventory()
    local current = player
    for _, name in ipairs(CONFIG.InventoryPath) do
        current = current:FindFirstChild(name)
        if not current then
            warn("❌ Inventory path broken at: " .. name)
            return nil
        end
    end
    return current
end

local function GetEquipGui()
    local current = player
    for _, name in ipairs(CONFIG.EquipGuiPath) do
        current = current:FindFirstChild(name)
        if not current then
            return nil
        end
    end
    return current
end

local NativeInventory = GetInventory()
local EquipGui = GetEquipGui()
local HAS_NATIVE_INVENTORY = NativeInventory ~= nil

print("🎒 Native Inventory:", HAS_NATIVE_INVENTORY and "✅ FOUND" or "❌ NOT FOUND")
if NativeInventory then
    print("   Path:", NativeInventory:GetFullName())
    print("   Children:", #NativeInventory:GetChildren())
end
print("🖥️ Equip GUI:", EquipGui and "✅ FOUND" or "❌ NOT FOUND")
if EquipGui then
    print("   Path:", EquipGui:GetFullName())
end

-- ═══════════════════════════════════════════════════════════════
--  ANALYZE INVENTORY STRUCTURE
-- ═══════════════════════════════════════════════════════════════

local InventoryTemplate = nil
local InventoryItemClass = "Frame"

local function AnalyzeInventory()
    if not NativeInventory then return end
    
    print("\n🔍 Analyzing inventory structure...")
    
    local children = NativeInventory:GetChildren()
    print("   Items in inventory:", #children)
    
    -- Find template
    for _, child in ipairs(children) do
        if child:IsA("GuiObject") then
            InventoryTemplate = child
            InventoryItemClass = child.ClassName
            print("   Found template:", child.Name, "| Class:", child.ClassName)
            print("   Template children:")
            for _, desc in ipairs(child:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("ImageLabel") or desc:IsA("TextButton") or desc:IsA("ViewportFrame") then
                    print("      -", desc.Name, "(" .. desc.ClassName .. ")")
                end
            end
            break
        end
    end
end

if HAS_NATIVE_INVENTORY then
    AnalyzeInventory()
end

-- ═══════════════════════════════════════════════════════════════
--  GET PET FOLDER
-- ═══════════════════════════════════════════════════════════════

local PetFolder = ReplicatedStorage
for _, folderName in ipairs(CONFIG.PetFolderPath) do
    PetFolder = PetFolder:FindFirstChild(folderName)
    if not PetFolder then
        warn("❌ Pet folder path broken at: " .. folderName)
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
--  INJECT PET INTO NATIVE INVENTORY
-- ═══════════════════════════════════════════════════════════════

local InjectedPets = {} -- [petName] = guiElement

local function InjectPetToInventory(petName)
    if not NativeInventory then
        return false, "No native inventory"
    end
    
    print("\n💉 Injecting", petName, "into native inventory...")
    
    -- Check if already exists
    if InjectedPets[petName] then
        print("   ⚠ Already injected")
        return true, "Already exists"
    end
    
    -- Try to clone existing template
    if InventoryTemplate then
        local clone = InventoryTemplate:Clone()
        clone.Name = petName
        
        -- Update all text to show pet name
        for _, desc in ipairs(clone:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                if desc.Name:lower():find("name") or desc.Name:lower():find("title") or 
                   desc.Name:lower():find("label") or desc.Name:lower():find("text") then
                    desc.Text = petName
                end
            end
            if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
                if desc.Name:lower():find("icon") or desc.Name:lower():find("image") or 
                   desc.Name:lower():find("pet") or desc.Name:lower():find("thumbnail") then
                    -- Try to set pet image - GAG 2 might use specific asset IDs
                    -- We can't guess these, but the template might already have it
                end
            end
        end
        
        -- Add custom attributes
        clone:SetAttribute("IsInjectedPet", true)
        clone:SetAttribute("PetName", petName)
        clone:SetAttribute("PetType", petName)
        
        -- Add click handler
        local clickTarget = clone
        if not (clone:IsA("TextButton") or clone:IsA("ImageButton")) then
            for _, desc in ipairs(clone:GetDescendants()) do
                if desc:IsA("TextButton") or desc:IsA("ImageButton") then
                    clickTarget = desc
                    break
                end
            end
        end
        
        if clickTarget:IsA("GuiButton") then
            clickTarget.MouseButton1Click:Connect(function()
                print("🖱️ Clicked injected pet in inventory:", petName)
                EquipPet(petName)
            end)
        end
        
        -- Also add right-click or double-click for equip
        clone.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Right click
                print("🖱️ Right-clicked pet:", petName)
                EquipPet(petName)
            end
        end)
        
        clone.Parent = NativeInventory
        InjectedPets[petName] = clone
        print("   ✅ Cloned template into inventory")
        return true, "TemplateClone"
    end
    
    -- Fallback: Create minimal entry
    print("   📁 Creating minimal entry...")
    local entry = Instance.new("Frame")
    entry.Name = petName
    entry.Size = UDim2.new(0, 80, 0, 80)
    entry.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    entry:SetAttribute("IsInjectedPet", true)
    entry:SetAttribute("PetName", petName)
    
    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 8)
    
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
    
    entry.Parent = NativeInventory
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
    for _, data in pairs(EquippedPets) do
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

-- ═══════════════════════════════════════════════════════════════
--  EQUIP / UNEQUIP
-- ═══════════════════════════════════════════════════════════════

function EquipPet(petName)
    if EquippedPets[petName] then
        print("⚠", petName, "already equipped")
        return true
    end
    
    local eqCount = 0
    for _ in pairs(EquippedPets) do eqCount += 1 end
    if eqCount >= CONFIG.MaxEquipped then
        warn("❌ Max equipped:", CONFIG.MaxEquipped)
        return false
    end
    
    print("\n🚀 EQUIPPING:", petName)
    
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
    
    EquippedPets[petName] = {
        model = pet,
        followConn = followConn,
        animTracks = animTracks,
    }
    
    -- Highlight in inventory
    local injected = InjectedPets[petName]
    if injected then
        injected.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
    end
    
    -- Trigger EquipPet GUI if it exists
    if EquipGui then
        -- Try to find and trigger equip functionality
        for _, desc in ipairs(EquipGui:GetDescendants()) do
            if desc:IsA("TextButton") and desc.Name:lower():find("equip") then
                -- Don't auto-click, just highlight
                print("   🖥️ Found equip button in GUI")
            end
        end
    end
    
    pet.AncestryChanged:Connect(function(_, newParent)
        if not newParent and EquippedPets[petName] then
            task.defer(function()
                UnequipPet(petName)
            end)
        end
    end)
    
    print("✅ EQUIPPED:", petName, "| Anims:", hasAnims)
    return true
end

function UnequipPet(petName)
    local petData = EquippedPets[petName]
    if not petData then return false end
    
    if petData.followConn then petData.followConn:Disconnect() end
    if petData.animTracks then
        for _, track in ipairs(petData.animTracks) do
            pcall(function() track:Stop() track:Destroy() end)
        end
    end
    if petData.model then petData.model:Destroy() end
    
    EquippedPets[petName] = nil
    
    -- Unhighlight in inventory
    local injected = InjectedPets[petName]
    if injected then
        injected.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    end
    
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
screenGui.Name = "GAG2NativeInventory"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local toggleBtn = Instance.new("TextButton")
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
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
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
statusBar.BackgroundColor3 = HAS_NATIVE_INVENTORY and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 80, 40)
statusBar.BorderSizePixel = 0

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 1, 0)
statusLabel.Position = UDim2.new(0, 5, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = HAS_NATIVE_INVENTORY and "🟢 NATIVE INVENTORY ACTIVE" or "🟡 VISUAL MODE ONLY"
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
countLabel.Text = "Injected: 0 | Equipped: 0"
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

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(75, 75, 95)
    stroke.Thickness = 1
    stroke.Parent = btn

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 28, 0, 28)
    arrow.Position = UDim2.new(1, -34, 0.5, -14)
    arrow.BackgroundTransparency = 1
    arrow.Text = HAS_NATIVE_INVENTORY and "💉" or "👁️"
    arrow.TextColor3 = HAS_NATIVE_INVENTORY and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 200, 100)
    arrow.TextSize = 20
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = btn

    btn.MouseButton1Click:Connect(function()
        -- Step 1: Inject to native inventory
        if HAS_NATIVE_INVENTORY then
            InjectPetToInventory(petName)
        end
        
        -- Step 2: Equip (spawn visual)
        task.delay(0.2, function()
            EquipPet(petName)
        end)
        
        -- Update count
        local injectedCount = 0
        for _ in pairs(InjectedPets) do injectedCount += 1 end
        local eqCount = 0
        for _ in pairs(EquippedPets) do eqCount += 1 end
        countLabel.Text = "Injected: " .. injectedCount .. " | Equipped: " .. eqCount
        
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
    countLabel.Text = "Injected: " .. #InjectedPets .. " | Equipped: 0"
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.P then
        toggleGUI()
    end
end)

player.CharacterRemoving:Connect(function()
    UnequipAll()
end)

print("\n🐾 GAG 2 NATIVE INVENTORY INJECTOR loaded!")
print("📋 Pets:", #allPets)
print("🎒 Inventory:", HAS_NATIVE_INVENTORY and "ACTIVE" or "NOT FOUND")
print("💡 Click pet → injects to native inventory → auto-equips")
