-- MIZ0 Galaxy: refreshed interface and uncropped photo views.
local lib
local sessionClosed = false
do
    local PHOTO_URLS = {
        "https://i.ibb.co/N2q7Lr9C/8.jpg",
    }
    -- A Roblox asset ID (rbxassetid://...) also works here.
    local photoAsset = ""
    local photoState = "Loading your image..."
    local photoBusy = false
    local refreshPhoto = function() end
    local connections, tabs, sections = {}, {}, {}
    local density = "normal"
    local backgroundTransparency = 0.48
    local themeName = "Galaxy"
    local themeAccent = Color3.fromRGB(174, 151, 255)
    local themeListeners = {}

    local function protect(fn, ...)
        if type(fn) ~= "function" then return end
        local ok, result = pcall(fn, ...)
        if not ok then warn("[Miz0] UI callback:", result) end
        return ok and result or nil
    end
    local function track(connection)
        connections[#connections + 1] = connection
        return connection
    end
    local function make(className, properties, parent)
        local object = Instance.new(className)
        for key, value in pairs(properties) do object[key] = value end
        object.Parent = parent
        return object
    end
    local function corner(object, radius)
        make("UICorner", {CornerRadius = UDim.new(0, radius)}, object)
    end

    local windOk, WindUI = pcall(function()
        local source = game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua")
        assert(type(source) == "string" and #source > 100, "WindUI source unavailable")
        return assert(loadstring(source))()
    end)
    if not windOk or type(WindUI) ~= "table" then
        warn("[Miz0] WindUI failed to load:", WindUI)
        return
    end

    local palettes = {
        Galaxy = {background = "11101C", surface = "1B192B", panel = "171524", accent = "AE97FF"},
        Halloween = {background = "17110E", surface = "241B16", panel = "1E1612", accent = "FFAA66"},
        AMOLED = {background = "050508", surface = "101016", panel = "09090E", accent = "9ECFFF"},
    }
    local function registerTheme(name, accent)
        local colors = palettes[name] or palettes.Galaxy
        WindUI:AddTheme({
            Name = "Miz0 " .. name,
            Accent = Color3.fromHex(colors.surface),
            Background = Color3.fromHex(colors.background),
            Dialog = Color3.fromHex(colors.surface),
            Outline = Color3.fromHex("514960"),
            Text = Color3.fromHex("F3F0FF"),
            Placeholder = Color3.fromHex("A59DB8"),
            Button = Color3.fromHex(colors.surface),
            Icon = Color3.fromHex("CEC5E6"),
            Primary = accent, Toggle = accent, Slider = accent, Checkbox = accent,
            PanelBackground = Color3.fromHex(colors.panel), PanelBackgroundTransparency = 0.10,
            LabelBackground = Color3.fromHex(colors.surface), LabelBackgroundTransparency = 0.12,
            ElementBackground = Color3.fromHex(colors.surface), ElementBackgroundTransparency = 0.15,
        })
    end

    local Miz0UI = {Version = "2.0"}
    function Miz0UI:Notify(o)
        protect(function()
            local icons = {Success = "circle-check", Warning = "triangle-alert", Danger = "circle-alert", Info = "info"}
            WindUI:Notify({Title = o.Title or "Miz0", Content = tostring(o.Content or ""),
                Icon = icons[o.Type] or "sparkles", Duration = o.Duration or 4})
        end)
    end
    function Miz0UI:SetTheme(theme)
        if type(theme) == "string" then
            themeName = palettes[theme] and theme or "Galaxy"
            themeAccent = Color3.fromHex(palettes[themeName].accent)
        elseif type(theme) == "table" and typeof(theme.AccentSolid) == "Color3" then
            themeAccent = theme.AccentSolid
        end
        registerTheme(themeName, themeAccent)
        WindUI:SetTheme("Miz0 " .. themeName)
        for _, update in ipairs(themeListeners) do protect(update) end
    end
    function Miz0UI:SetDensity(value)
        local gaps = {compact = 3, normal = 7, comfortable = 12}
        density = gaps[value] and value or "normal"
        local gap = gaps[density]
        for _, tab in ipairs(tabs) do
            tab.Gap = gap
            local container = tab.UIElements and tab.UIElements.ContainerFrame
            local layout = container and container:FindFirstChildOfClass("UIListLayout")
            if layout then layout.Padding = UDim.new(0, gap) end
        end
        for _, section in ipairs(sections) do
            local outline = section.ElementFrame and section.ElementFrame:FindFirstChild("Outline")
            local content = outline and outline:FindFirstChild("Content")
            local layout = content and content:FindFirstChildOfClass("UIListLayout")
            if layout then layout.Padding = UDim.new(0, gap) end
        end
    end

    local function loadPhoto(force)
        if photoBusy or sessionClosed then return end
        photoBusy = true
        photoState = "Loading your image..."
        refreshPhoto()
        task.spawn(function()
            local ok, result = pcall(function()
                local url = PHOTO_URLS[1]
                assert(type(url) == "string" and url ~= "", "No image has been configured.")
                if url:match("^rbxassetid://") or url:match("^rbxthumb://") then return url end
                local assetFn = getcustomasset or getsynasset
                local requestFn = request or http_request or (syn and syn.request)
                assert(type(assetFn) == "function" and type(requestFn) == "function" and type(writefile) == "function",
                    "This environment cannot load web images. Use a Roblox asset ID in PHOTO_URLS.")
                local hash = 5381
                for i = 1, #url do hash = (hash * 33 + url:byte(i)) % 2147483647 end
                local cleanUrl = url:match("^[^?#]+") or url
                local extension = (cleanUrl:match("%.(%w+)$") or "jpg"):lower()
                if extension ~= "png" and extension ~= "webp" and extension ~= "jpeg" then extension = "jpg" end
                local path = "miz0_photo_" .. tostring(hash) .. "." .. extension
                if force or not (type(isfile) == "function" and isfile(path)) then
                    local response = requestFn({Url = url, Method = "GET"})
                    assert(response and (response.StatusCode == 200 or response.StatusCode == 201)
                        and type(response.Body) == "string" and #response.Body > 100, "Image download failed. Try Reload image.")
                    writefile(path, response.Body)
                end
                local asset = assetFn(path)
                assert(type(asset) == "string" and asset ~= "", "Image could not be registered. Try Reload image.")
                return asset
            end)
            photoBusy = false
            if sessionClosed then return end
            photoAsset = ok and result or ""
            photoState = ok and "Full image · original proportions" or tostring(result):gsub("^.-:%d+: ", "")
            if not ok then warn("[Miz0] Photo:", result) end
            refreshPhoto()
        end)
    end

    function Miz0UI:CreateWindow(o)
        local input = game:GetService("UserInputService")
        local touch = input.TouchEnabled and not input.MouseEnabled
        local function viewport()
            return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(900, 650)
        end
        local function bounds()
            local view = viewport()
            local margin = touch and 12 or 24
            return math.max(1, view.X - margin * 2), math.max(1, view.Y - margin * 2 - 40)
        end
        local maxW, maxH = bounds()
        local preferredW = touch and (maxH > maxW and 430 or 760) or (o.Size and o.Size.X.Offset or 840)
        local preferredH = touch and (maxH > maxW and 650 or 440) or (o.Size and o.Size.Y.Offset or 560)
        local w, h = math.min(maxW, preferredW), math.min(maxH, preferredH)
        self:SetTheme(o.Theme or "Galaxy")
        local raw = WindUI:CreateWindow({
            Title = touch and "MIZ0" or (o.Title or "MIZ0 | GALAXY"),
            Author = touch and "MM2" or "Murder Mystery 2", Icon = "moon",
            Folder = "Miz0", Size = UDim2.fromOffset(w, h),
            MinSize = Vector2.new(math.min(w, touch and 300 or 520), math.min(h, 320)),
            MaxSize = Vector2.new(maxW, maxH), Theme = "Miz0 " .. themeName,
            Transparent = false, Resizable = not touch, AutoScale = false,
            SideBarWidth = math.clamp(math.floor(w * 0.25), 100, 168),
            HideSearchBar = false, ScrollBarEnabled = true, Radius = 18,
            Background = "", BackgroundImageTransparency = backgroundTransparency,
            ToggleKey = o.ToggleKeybind or Enum.KeyCode.RightControl,
            OpenButton = {Enabled = true, OnlyMobile = false, Title = "MIZ0", Icon = "moon", Draggable = true, Scale = 0.9},
        })
        local wrapper = {_raw = raw}
        local main = raw.UIElements.Main
        local galleryGui, previewImage, previewStatus, fullImage, fullStatus

        local function applyPhoto()
            if sessionClosed then return end
            raw.BackgroundImageTransparency = backgroundTransparency
            local background = main:FindFirstChild("Background")
            local image = background and background:FindFirstChild("ImageLabel")
            if image and image:IsA("ImageLabel") then
                image.Image = photoAsset
                image.ScaleType = Enum.ScaleType.Fit
                image.ImageRectOffset = Vector2.zero
                image.ImageRectSize = Vector2.zero
                image.ImageTransparency = backgroundTransparency
                image.ImageColor3 = Color3.new(1, 1, 1)
                -- Keep the fitted image inside the rounded window edges.
                image.Position = UDim2.fromOffset(12, 12)
                image.Size = UDim2.new(1, -24, 1, -24)
                local mask = image:FindFirstChildOfClass("UICorner")
                if mask then mask.CornerRadius = UDim.new(0, 0) end
            end
            if previewImage then previewImage.Image = photoAsset end
            if fullImage then fullImage.Image = photoAsset end
            if previewStatus then previewStatus.Text = photoState end
            if fullStatus then fullStatus.Text = photoState end
        end
        refreshPhoto = applyPhoto
        function Miz0UI:SetPhotoTransparency(value)
            backgroundTransparency = math.clamp(value, 0, 1)
            applyPhoto()
        end
        function Miz0UI:ReloadPhoto() loadPhoto(true) end

        local function cleanup()
            if sessionClosed then return end
            sessionClosed = true
            if galleryGui then galleryGui:Destroy() end
            for _, connection in ipairs(connections) do connection:Disconnect() end
            table.clear(connections)
            refreshPhoto = function() end
            protect(o.OnClose)
        end
        function wrapper:Destroy()
            if sessionClosed then return end
            cleanup()
            protect(function() raw:Destroy() end)
        end
        raw:OnDestroy(cleanup)
        track(main.Destroying:Connect(cleanup))

        local hostGui = main:FindFirstAncestorOfClass("ScreenGui")
        galleryGui = make("ScreenGui", {
            Name = "Miz0GalaxyGallery", ResetOnSpawn = false, Enabled = false,
            DisplayOrder = hostGui and hostGui.DisplayOrder + 10 or 100,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = false,
        }, hostGui and hostGui.Parent or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))
        local shade = make("TextButton", {Text = "", AutoButtonColor = false,
            BackgroundColor3 = Color3.fromRGB(4, 4, 9), BackgroundTransparency = 0.14,
            BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 1, Modal = true}, galleryGui)
        local panel = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -32, 1, -32),
            BackgroundColor3 = Color3.fromRGB(17, 16, 28), BorderSizePixel = 0, ZIndex = 2, Active = true}, galleryGui)
        corner(panel, 18)
        make("UISizeConstraint", {MaxSize = Vector2.new(1600, 1100)}, panel)
        local outline = make("UIStroke", {Color = themeAccent, Transparency = 0.55, Thickness = 1}, panel)
        make("TextLabel", {Text = "Your image", Font = Enum.Font.GothamBold, TextSize = 20,
            TextColor3 = Color3.fromRGB(243, 240, 255), TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 12), Size = UDim2.new(1, -90, 0, 28), ZIndex = 3}, panel)
        fullStatus = make("TextLabel", {Text = photoState, Font = Enum.Font.Gotham, TextSize = 12,
            TextColor3 = Color3.fromRGB(185, 177, 206), TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true, BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 42),
            Size = UDim2.new(1, -84, 0, 36), ZIndex = 3}, panel)
        local close = make("TextButton", {Text = "×", Font = Enum.Font.GothamMedium, TextSize = 26,
            TextColor3 = Color3.fromRGB(243, 240, 255), BackgroundColor3 = Color3.fromRGB(36, 32, 52),
            BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12),
            Size = UDim2.fromOffset(44, 44), ZIndex = 4}, panel)
        corner(close, 12)
        fullImage = make("ImageLabel", {Name = "FullPhoto", Image = "", ScaleType = Enum.ScaleType.Fit,
            ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 0, BackgroundTransparency = 1,
            Position = UDim2.fromOffset(20, 88), Size = UDim2.new(1, -40, 1, -108), ZIndex = 3}, panel)
        local function closeGallery()
            if not sessionClosed and galleryGui.Parent then galleryGui.Enabled = false end
        end
        function wrapper:ShowPhoto()
            if sessionClosed then return end
            applyPhoto()
            galleryGui.Enabled = true
        end
        track(close.Activated:Connect(closeGallery))
        track(shade.Activated:Connect(closeGallery))
        track(input.InputBegan:Connect(function(key, processed)
            if not processed and key.KeyCode == Enum.KeyCode.Escape then closeGallery() end
        end))
        raw:OnClose(closeGallery)
        raw:CreateTopbarButton("View full image", "image", function() wrapper:ShowPhoto() end, 990)
        themeListeners[#themeListeners + 1] = function()
            panel.BackgroundColor3 = Color3.fromHex(palettes[themeName].background)
            outline.Color = themeAccent
        end

        local cameraConnection
        local function fitWindow()
            if sessionClosed or raw.IsFullscreen then return end
            local availableW, availableH = bounds()
            if touch then
                local portrait = availableH > availableW
                preferredW, preferredH = portrait and 430 or 760, portrait and 650 or 440
            end
            raw.MinSize = Vector2.new(math.min(availableW, touch and 300 or 520), math.min(availableH, 320))
            raw.MaxSize = Vector2.new(availableW, availableH)
            local size = raw.Size
            raw:SetSize(UDim2.fromOffset(math.min(availableW, touch and preferredW or size.X.Offset),
                math.min(availableH, touch and preferredH or size.Y.Offset)))
            raw:SetToTheCenter()
        end
        local function watchCamera()
            if cameraConnection then cameraConnection:Disconnect() end
            if workspace.CurrentCamera then
                cameraConnection = track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitWindow))
            end
            fitWindow()
        end
        track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera))
        watchCamera()

        function wrapper:CreateTab(cfg)
            local name = tostring(cfg.Name or "Tab")
            local icons = {Home = "house", Gameplay = "gamepad-2", ESP = "eye", Combat = "swords", Movement = "footprints",
                Misc = "layers", Inventory = "backpack", Settings = "settings", Teleports = "map-pin",
                ["Auto Farm"] = "repeat", ["Coin Farm"] = "coins"}
            local tab = raw:Tab({Title = name, Icon = icons[name] or "star"})
            tabs[#tabs + 1] = tab
            Miz0UI:SetDensity(density)
            local proxy = {_tab = tab}
            function proxy:CreateSection(c)
                if type(c) == "string" then c = {Name = c} end
                c = c or {}
                local sec = tab:Section({Title = tostring(c.Name or "Section"), Box = true, Opened = true})
                sections[#sections + 1] = sec
                Miz0UI:SetDensity(density)
                local out = {_section = sec}
                function out:AddButton(x)
                    return sec:Button({Title = tostring(x.Text or "Action"), Desc = x.Tooltip,
                        Callback = function() protect(x.Callback) end})
                end
                function out:AddToggle(x)
                    return sec:Toggle({Title = tostring(x.Text or "Toggle"), Desc = x.Tooltip, Value = x.Default == true,
                        Callback = function(v) protect(x.Callback, v) end})
                end
                function out:AddSlider(x)
                    return sec:Slider({Title = tostring(x.Text or "Slider"), Desc = x.Tooltip or x.Suffix,
                        Step = x.Increment or 1, Value = {Min = x.Min or 0, Max = x.Max or 100, Default = x.Default or x.Min or 0},
                        Callback = function(v) protect(x.Callback, v) end})
                end
                function out:AddDropdown(x)
                    return sec:Dropdown({Title = tostring(x.Text or "Select"), Desc = x.Tooltip, Values = x.Options or {},
                        Value = x.Default, AllowNone = true, Callback = function(v) protect(x.Callback, v) end})
                end
                function out:AddMultiDropdown(x)
                    return sec:Dropdown({Title = tostring(x.Text or "Select"), Desc = x.Tooltip, Values = x.Options or {},
                        Value = x.Default, Multi = true, AllowNone = true, Callback = function(v) protect(x.Callback, v) end})
                end
                function out:AddInput(x)
                    return sec:Input({Title = tostring(x.Text or "Input"), Desc = x.Tooltip, Value = tostring(x.Default or ""),
                        Placeholder = x.Placeholder or "", Callback = function(v) protect(x.Callback, v) end})
                end
                function out:AddColorPicker(x)
                    return sec:Colorpicker({Title = tostring(x.Text or "Color"), Default = x.Default or themeAccent,
                        Callback = function(v) protect(x.Callback, v) end})
                end
                function out:AddParagraph(x)
                    local para = sec:Paragraph({Title = tostring(x.Title or ""), Desc = tostring(x.Content or "")})
                    return {SetTitle = function(_, v) protect(function() para:SetTitle(tostring(v)) end) end,
                        SetContent = function(_, v) protect(function() para:SetDesc(tostring(v)) end) end}
                end
                function out:AddBanner(x)
                    return sec:Paragraph({Title = "MIZ0", Desc = tostring(x.Text or "")})
                end
                return out
            end
            return proxy
        end

        local home = wrapper:CreateTab({Name = "Home"})
        local container = home._tab.UIElements and home._tab.UIElements.ContainerFrame
        if container then
            local card = make("Frame", {Name = "PhotoPreview", Size = UDim2.new(1, 0, 0, math.clamp(h - 280, 160, 300)),
                BackgroundColor3 = Color3.fromRGB(10, 9, 18), BorderSizePixel = 0, LayoutOrder = -10}, container)
            corner(card, 12)
            local cardOutline = make("UIStroke", {Color = themeAccent, Transparency = 0.65, Thickness = 1}, card)
            previewImage = make("ImageLabel", {Name = "Photo", Image = photoAsset, ScaleType = Enum.ScaleType.Fit,
                BackgroundTransparency = 1, ImageTransparency = 0, Position = UDim2.fromOffset(12, 12),
                Size = UDim2.new(1, -24, 1, -58)}, card)
            previewStatus = make("TextLabel", {Text = photoState, Font = Enum.Font.Gotham, TextSize = 12,
                TextColor3 = Color3.fromRGB(195, 186, 216), BackgroundTransparency = 1, TextWrapped = true,
                AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -8), Size = UDim2.new(1, -24, 0, 36)}, card)
            themeListeners[#themeListeners + 1] = function() cardOutline.Color = themeAccent end
        end
        local welcome = home:CreateSection({Name = "Welcome to MIZ0"})
        welcome:AddParagraph({Title = "Your space, your style", Content = "Choose a tab to get started. Search finds controls quickly. Change colors and spacing in Settings."})
        welcome:AddButton({Text = "View full image", Tooltip = "Open the whole photo without cropping or controls over it.", Callback = function() wrapper:ShowPhoto() end})
        welcome:AddButton({Text = "Reload image", Callback = function() Miz0UI:ReloadPhoto() end})
        home._tab:Select()
        applyPhoto()
        loadPhoto(false)
        return wrapper
    end
    lib = Miz0UI
end

local genv = typeof(getgenv) == "function" and getgenv() or _G

if game.GameId ~= 66654135 then
	lib:Notify({
		Title = "Wrong game",
		Content = "This script only works in Murder Mystery 2 (GameId 66654135).",
		Type = "Danger",
		Duration = 6
	})

	return
end

if genv.miz0MM2Loaded then
	lib:Notify({
		Title = "Already loaded",
		Content = "MM2 is already loaded in this session.",
		Type = "Warning",
		Duration = 4
	})

	return
end

genv.miz0MM2Loaded = true

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

repeat
	task.wait()
until game:IsLoaded()

LocalPlayer:WaitForChild("PlayerGui")

local function getCharacter()
	return LocalPlayer.Character
end
local function getHumanoid()
	local v17 = getCharacter()

	return v17 and v17:FindFirstChildOfClass("Humanoid")
end
local function getRootPart()
	local v19 = getCharacter()
	local v20 = v19

	return v20 and v19:FindFirstChild("HumanoidRootPart")
end

local CoinCollected = ReplicatedStorage.Remotes.Gameplay.CoinCollected
local RoundStart = ReplicatedStorage.Remotes.Gameplay.RoundStart
local t1 = {
	"MouseButton1Click",
	"MouseButton1Down",
	"Activated"
}

local function activateGuiButton(p1)
	if not p1 then
		return
	end

	local v25 = false

	for _, v in ipairs(t1) do
		local v28 = p1[v]

		if v28 and typeof(getconnections) == "function" then
			local ok, result = pcall(getconnections, v28)

			if ok then
				for _, v2 in pairs(result) do
					if v2 and typeof(v2.Function) == "function" then
						v25 = true
						pcall(v2.Function)
					end
				end
			end
		end

		if v28 and typeof(firesignal) == "function" then
			v25 = true
			pcall(firesignal, v28)
		end
	end

	if not v25 then
		pcall(function()
			if typeof(p1.Activate) == "function" then
				p1:Activate()
			end
		end)
	end
end

task.spawn(function()
    for _ = 1, 12 do
        if LocalPlayer.PlayerGui:FindFirstChild("MainGUI") then break end
        pcall(function() activateGuiButton(LocalPlayer.PlayerGui.DeviceSelect.Container.Tablet.Button) end)
        pcall(function() activateGuiButton(LocalPlayer.PlayerGui.Join.Friends.Play) end)
        task.wait(1)
    end
end)

local DEFAULT_SETTINGS = {
	AutoRevealRoles = false,
	CoinFarm = {
		StatsOverlay = false,
		State = false,
		Settings = {
			Speed = 22.5,
			DestroyMap = false,
			DestroyPlayers = false,
			Fly = false,
			DieAtFullBag = false
		}
	},
	CoinFarm2 = {
		Disable3DRendering = false,
		State = false,
		Settings = {
			Speed = 22.5,
			DestroyMap = false,
			DestroyPlayers = false,
			DieAtFullBag = false,
			Disable3DRendering = false
		}
	},
	ESP = {
		Players = false,
		Traps = false,
		DroppedGun = false
	},
	Noclip = false,
	Gameplay = {
		AutoPickUpGun = false,
		AutoShooting = false
	},
	AutoFarm = {
		TeleportSpawn = false,
		KillEveryoneAsAMurderer = false,
		AutoFlingMurderer = false,
		AutoFlingSheriff = false,
		AutoPrestige = false,
		KillEveryoneAsAMurdererAtFullBag = false,
		TeleportUnderMap = false,
		AutoTeleportToRandomServerIfServerIsEmpty = false,
		AutoFlingMurdererAtFullBag = false,
		PlayersToAutoServerHop = 2
	},
	AnnoyingStuff = {
		Fling = {
			PickedPlayer = nil,
			LoopFlingAllPlayers = false
		}
	},
	Sliders = {
		Speed = 16,
		Jump = 50
	},
	AutoOpenCrates = {
		State = false,
		Crate = "MysteryBox1",
		CrateType = "MysteryBox"
	},
	VisualGun = false,
	ShuffleWeapons = false,
	Emotes = {
		SelectedEmote = "zen",
		AutoPlayEmotes = false,
		AutoPlaySelectedEmote = false,
		EmoteSpamSpeed = 1
	}
}

local function deepCopySettings(p2)
	local v35 = table.clone(p2)

	for k, v in pairs(v35) do
		if type(v) == "table" then
			v35[k] = deepCopySettings(v)
		end
	end

	return v35
end

local settings = deepCopySettings(DEFAULT_SETTINGS)

LocalPlayer.Idled:Connect(function()
	VirtualUser:ClickButton2(Vector2.new())
end)

local CenteredLabelGui = CoreGui:FindFirstChild("CenteredLabelGui") or Instance.new("ScreenGui")

CenteredLabelGui.Name = "CenteredLabelGui"
CenteredLabelGui.Parent = CoreGui

local CenteredTextLabel = CenteredLabelGui:FindFirstChild("CenteredTextLabel") or Instance.new("TextLabel")

CenteredTextLabel.Name = "CenteredTextLabel"
CenteredTextLabel.Visible = false
CenteredTextLabel.Text = ""
CenteredTextLabel.Size = UDim2.new(0.5, 0, 0.1, 0)
CenteredTextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
CenteredTextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
CenteredTextLabel.BackgroundTransparency = 1
CenteredTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
CenteredTextLabel.TextStrokeTransparency = 0.35
CenteredTextLabel.Font = Enum.Font.SourceSansBold
CenteredTextLabel.TextSize = 42
CenteredTextLabel.Parent = CenteredLabelGui

local now = tick()
local n1 = 0
local n2 = 0
local n3 = 40

CoinCollected.OnClientEvent:Connect(function(p3, p4, p5)
	n1 += 1
	n2 = tonumber(p4) or n2
	n3 = tonumber(p5) or n3
end)
task.spawn(function()
    while not sessionClosed do
        task.wait(0.5)
        if not settings.CoinFarm.StatsOverlay then continue end
	local v45 = math.floor(n1 * 3600 / math.max(tick() - now, 1))

	CenteredTextLabel.Text = ("Coins Collected: %d/%d\nTotal Coins: %d\nCoins Per Hour: %d"):format(n2, n3, n1, v45)
    end
end)

local u46

local function teleportToSafeSpot()
	local v48 = getRootPart()

	if not v48 then
		return
	end

	if Workspace:FindFirstChild("safespot") then
		v48.CFrame = CFrame.new(-106, 87.5, 2)
	else
		local Part = Instance.new("Part")

		Part.Name = "safespot"
		Part.Size = Vector3.new(25, 3, 25)
		Part.Position = Vector3.new(-106, 83, 2)
		Part.Parent = Workspace
		Part.Anchored = true
		Part.CanCollide = true
		Part.Transparency = 0
		task.wait()

		for i = 1, 3 do
			local v51 = getRootPart()

			if not v51 then
				return
			end

			v51.CFrame = CFrame.new(-106, 87.5, 2)
			task.wait(0.1)
		end
	end
end

local EMOTE_NAMES = {
	"sit",
	"ninja",
	"dab",
	"zen",
	"floss",
	"headless",
	"zombie",
	"wave",
	"cheer",
	"laugh"
}

local function playEmote(p6)
	ReplicatedStorage.Remotes.Misc.PlayEmote:Fire(p6)
end

task.spawn(function()
	while true do
		task.wait(1 / math.max(settings.Emotes.EmoteSpamSpeed, 1))

		if settings.Emotes.AutoPlayEmotes then
			playEmote(EMOTE_NAMES[math.random(1, #EMOTE_NAMES)])
		end
	end
end)

local function removeOtherPlayerModels()
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and Workspace:WaitForChild(player.Name, 0.01) then
			Workspace[player.Name]:Destroy()
		end
	end
end
local function removeMapDecorations()
	for _, child in pairs(Workspace:GetChildren()) do
		if child:IsA("Model") and child:FindFirstChild("CoinContainer") then
			for _, child2 in pairs(child:GetChildren()) do
				if child2.Name ~= "CoinContainer" then
					child2:Destroy()
				end
			end
		end
	end
end
local function applyNoclip()
	if not LocalPlayer.Character then
		return
	end

	for _, descendant in pairs(LocalPlayer.Character:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.CanCollide then
			descendant.CanCollide = false
		end
	end
end

RunService.Stepped:Connect(function()
	local v65 = getHumanoid()

	if settings.Noclip and v65 and v65.Health > 0 and getRootPart() then
		applyNoclip()
	end
end)

local function getRandomOwnedWeapon()
	local t4 = {}
	local ok, result = pcall(function()
		return require(ReplicatedStorage.Modules.InventoryModule).MyInventory.Data.Weapons
	end)

	if not ok or not result then
		return nil
	end

	for _, v in pairs(result) do
		for k in pairs(v) do
			table.insert(t4, k)
		end
	end

	if #t4 == 0 then
		return nil
	end

	return t4[math.random(1, #t4)]
end

RunService.Stepped:Connect(function()
	if settings.Emotes.AutoPlaySelectedEmote then
		playEmote(settings.Emotes.SelectedEmote)
	end

	if settings.ShuffleWeapons then
		local v73 = getRandomOwnedWeapon()

		if v73 then
			pcall(function()
				local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
				local Inventory = Remotes and Remotes:FindFirstChild("Inventory")
				local Equip = Inventory and Inventory:FindFirstChild("Equip")

				if Equip then
					Equip:FireServer(v73, "Weapons")
				end
			end)
		end
	end

    if CenteredTextLabel.Visible ~= settings.CoinFarm.StatsOverlay then
        CenteredTextLabel.Visible = settings.CoinFarm.StatsOverlay
    end

	local Character = LocalPlayer.Character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

	if not Character or not Humanoid or not (Humanoid.Health > 0) or not Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	if settings.Sliders.Speed ~= Humanoid.WalkSpeed then
		Humanoid.WalkSpeed = settings.Sliders.Speed
	end

	if settings.Sliders.Jump ~= Humanoid.JumpPower then
		Humanoid.JumpPower = settings.Sliders.Jump
	end
end)
RunService.Stepped:Connect(function()
	if settings.CoinFarm.Settings.DestroyPlayers then
		removeOtherPlayerModels()
	end
end)
RunService.Heartbeat:Connect(function()
	if settings.CoinFarm.Settings.DestroyMap then
		removeMapDecorations()
	end
end)

local function findClosestCoin()
	if not LocalPlayer.Character then
		return
	end

	local HumanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

	if not HumanoidRootPart then
		return
	end

	local t5 = {}

	for _, v in Workspace:GetChildren() do
		if v:IsA("Model") and v:FindFirstChild("CoinContainer") then
			for _, v2 in v.CoinContainer:GetChildren() do
				if v2.Name == "Coin_Server" and not v2:FindFirstChild("CollectedCoin") and v2:FindFirstChild("TouchInterest") then
					local Magnitude = (HumanoidRootPart.Position - v2.Position).Magnitude

					if Magnitude < 100 then
						table.insert(t5, {
							Coin = v2,
							Distance = Magnitude
						})
					end
				end
			end
		end
	end

	table.sort(t5, function(p7, p8)
		return p7.Distance < p8.Distance
	end)

	return t5[1] and t5[1].Coin
end

local connection
local t6 = {}

local function stopCoinFarm()
	for _, v in ipairs(t6) do
		if v then
			pcall(function()
				v:Disconnect()
			end)
		end
	end

	table.clear(t6)
	connection = nil

	local v93 = getRootPart()

	if v93 then
		v93.Anchored = false

		local MM2_CoinFarmVelocity = v93:FindFirstChild("MM2_CoinFarmVelocity")

		if MM2_CoinFarmVelocity then
			MM2_CoinFarmVelocity:Destroy()
		end
	end
end
local function startCoinFarm()
	stopCoinFarm()

	local connection2

	local function v97()
		if not settings.CoinFarm.State then
			return
		end

		local MainGUI = LocalPlayer.PlayerGui:FindFirstChild("MainGUI")
		local Game = MainGUI and MainGUI:FindFirstChild("Game")
		local ok, result, result2 = pcall(function()
			return Game.CoinBags.Visible, Game.CoinBags.Container.Candy.Full.Visible
		end)
		local v103 = getRootPart()

		if ok and result and not result2 and v103 then
			if not v103:FindFirstChild("MM2_CoinFarmVelocity") then
				local BodyVelocity = Instance.new("BodyVelocity", v103)

				BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
				BodyVelocity.Name = "MM2_CoinFarmVelocity"
			end

			applyNoclip()

			local v105 = findClosestCoin()

			if v105 then
				v103.Anchored = false
				task.spawn(function()
					local v106 = getRootPart()

					if not v106 then
						return
					end

					local v107 = (v106.Position - v105.Position).Magnitude / settings.CoinFarm.Settings.Speed
					local cFrame = CFrame.new(v105.Position + Vector3.new(0, -1, 0))

					TweenService:Create(v106, TweenInfo.new(v107, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
						CFrame = cFrame
					}):Play()

					if v105 and v105.Parent then
						local connection3

						connection3 = v105.Touched:Connect(function()
							task.wait(0.1)

							if v105 then
								v105:Destroy()
								connection3:Disconnect()
							end
						end)
					end
				end)
			else
				v103.Anchored = true
			end

			task.wait(0.02)
		end
	end

	local connection3 = RunService.Heartbeat:Connect(v97)
	local connection4 = CoinCollected.OnClientEvent:Connect(function(p9, p10, p11)
		if p10 == p11 then
			stopCoinFarm()
		end
	end)
	local v112 = getHumanoid()

	if v112 then
		connection2 = v112.Died:Connect(function()
			task.wait(1)

			repeat
				task.wait()
			until LocalPlayer.Character ~= nil

			repeat
				task.wait()
			until LocalPlayer.PlayerGui ~= nil

			task.wait(1)

			repeat
				task.wait()
			until LocalPlayer.PlayerGui:FindFirstChild("MainGUI")

			task.wait(1)

			if Teleport_to_map then
				Teleport_to_map()
			end
		end)
	end

	connection = ReplicatedStorage.Remotes.Gameplay.RoundEndFade.OnClientEvent:Connect(function()
		stopCoinFarm()
	end)
	table.insert(t6, connection3)
	table.insert(t6, connection4)

	if connection2 then
		table.insert(t6, connection2)
	end

	table.insert(t6, connection)
end

local vector3 = Vector3.new(1, -100, 1)
local Part = Instance.new("Part", Workspace)

Part.Anchored = true
Part.Position = vector3
Part.Size = Vector3.new(100, 1.2, 100)

local u115 = false

local function moveBelowMap()
	local v117 = getRootPart()

	if v117 then
		v117.CFrame = CFrame.new(Part.Position + Vector3.new(math.random(-10, 5), 5, math.random(-10, 5)))
	end
end
local function moveBelowCoin(p12)
	local v119 = getRootPart()

	if p12 and v119 then
		v119.CFrame = CFrame.new(p12.Position + Vector3.new(0, -6, 0))
	end
end
local function findCoinMap()
	for _, child in ipairs(Workspace:GetChildren()) do
		if child:FindFirstChild("CoinContainer") then
			return child
		end
	end
end

local u123

local function runSecondCoinFarm()
	if u123 then
		return
	end

	u123 = true
	u115 = false

	if settings.CoinFarm2.State then
		moveBelowMap()
	end

	while not u115 do
		local v125 = findCoinMap()

		if not v125 then
			task.wait(1)

			if settings.CoinFarm2.State then
				continue
			end
		elseif settings.CoinFarm2.State then
			task.spawn(function()
				pcall(removeMapDecorations)
			end)

			local v126
			local huge = math.huge

			for _, child in ipairs(v125.CoinContainer:GetChildren()) do
				if child:FindFirstChild("TouchInterest") and child.Position.Y < huge then
					huge = child.Position.Y
					v126 = child
				end
			end

			local v130 = v126

			if not v130 then
				task.wait(0.1)

				continue
			end

			local u131 = false

			moveBelowCoin(v130)

			local connection2 = CoinCollected.OnClientEvent:Connect(function(p13, p14, p15)
				u131 = true

				if p14 == p15 then
					u115 = true
				end
			end)

			if u115 then
				connection2:Disconnect()

				break
			end

			while true do
				task.wait()
				task.spawn(function()
					local v133 = getRootPart()

					if v133 then
						pcall(firetouchinterest, v133, v130, 0)
						pcall(firetouchinterest, v133, v130, 1)
					end
				end)
				task.wait()
				applyNoclip()
				moveBelowCoin(v130)

				if u131 then
					break
				elseif not v130:FindFirstChild("TouchInterest") then
					break
				end
			end

			connection2:Disconnect()
			moveBelowMap()
			task.wait(2)

			continue
		end

		break
	end

	u123 = false
end

ReplicatedStorage.Remotes.Gameplay.RoundStart.OnClientEvent:Connect(function()
	task.spawn(runSecondCoinFarm)
end)
LocalPlayer.CharacterAdded:Connect(function()
	if settings.CoinFarm2.State then
		moveBelowMap()
	end
end)
task.spawn(startCoinFarm)

local function findMurderer()
	for _, player in ipairs(Players:GetPlayers()) do
		if not player:FindFirstChild("Backpack") then
			continue
		end

		if player.Backpack:FindFirstChild("Knife") then
			return player
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if not player.Character then
			continue
		end

		if player.Character:FindFirstChild("Knife") then
			return player
		end
	end

	if u46 then
		for k, v in pairs(u46) do
			if v.Role ~= "Murderer" then
				continue
			end

			if Players:FindFirstChild(k) then
				return Players:FindFirstChild(k)
			end
		end
	end
end
local function findSheriff()
	for _, player in ipairs(Players:GetPlayers()) do
		if not player:FindFirstChild("Backpack") then
			continue
		end

		if player.Backpack:FindFirstChild("Gun") then
			return player
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if not player.Character then
			continue
		end

		if player.Character:FindFirstChild("Gun") then
			return player
		end
	end

	if u46 then
		for k, v in pairs(u46) do
			if v.Role == "Sheriff" and Players:FindFirstChild(k) then
				return Players:FindFirstChild(k)
			end
		end
	end
end
local function refreshPlayerHighlights()
	for _, child in ipairs(Workspace:GetChildren()) do
		if child.Name == "PlayerESP" then
			child:Destroy()
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			if not player.Character:FindFirstChild("PlayerESP") then
				local Highlight = Instance.new("Highlight", Workspace)

				Highlight.Name = "PlayerESP"
				Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				Highlight.Adornee = player.Character
				Highlight.FillColor = Color3.fromRGB(255, 255, 255)
				Highlight.FillTransparency = 0.5
				task.spawn(function()
					if player == findMurderer() then
						Highlight.FillColor = Color3.fromRGB(255, 0, 0)
						Highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
					elseif player == findSheriff() then
						Highlight.FillColor = Color3.fromRGB(0, 150, 255)
						Highlight.OutlineColor = Color3.fromRGB(0, 150, 255)
					else
						Highlight.FillColor = Color3.fromRGB(0, 255, 0)
						Highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
					end

					if Highlight and player then
						Highlight.Adornee = player.Character or player.CharacterAdded:Wait()
					end
				end)
			end
		end
	end
end
local function notifyRoles()
	if not u46 then
		lib:Notify({
			Title = "No data",
			Content = "playerData has not loaded yet.",
			Type = "Warning",
			Duration = 3
		})

		return
	end

	local t7 = {}

	for k, v in pairs(u46) do
		table.insert(t7, ("%s - %s"):format(k, tostring(v.Role)))
	end

	lib:Notify({
		Title = "Roles",
		Content = table.concat(t7, "\n"),
		Type = "Info",
		Duration = 6
	})
end

local Highlight = Instance.new("Highlight")

Highlight.Name = "TrapESP"
Highlight.OutlineTransparency = 1
Highlight.FillColor = Color3.fromRGB(255, 0, 0)
Highlight.FillTransparency = 0.4
Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
Workspace.DescendantAdded:Connect(function(descendant)
	if settings.ESP.Traps and descendant.Name == "Trap" then
		if descendant.Parent:IsDescendantOf(Workspace) then
			descendant.Transparency = 0

			local clone = Highlight:Clone()

			clone.Parent = Workspace
			clone.Adornee = descendant
		end
	end

	if settings.ESP.DroppedGun and descendant.Name == "GunDrop" then
		local GunESP = Workspace:FindFirstChild("GunESP")

		if not GunESP then
			GunESP = Instance.new("Highlight", Workspace)
			GunESP.OutlineTransparency = 1
			GunESP.FillColor = Color3.fromRGB(255, 255, 0)
			GunESP.Name = "GunESP"
			GunESP.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		end

		GunESP.Adornee = descendant
		GunESP.Enabled = true

		if settings.Gameplay.AutoPickUpGun then
			task.wait(0.5)

			for i = 1, 5 do
				if pickupgun then
					pickupgun()
				end
			end
		end
	end
end)
Workspace.DescendantRemoving:Connect(function(descendant)
	if settings.ESP.DroppedGun and descendant.Name == "GunDrop" then
		local GunESP = Workspace:FindFirstChild("GunESP")

		if GunESP then
			GunESP:Destroy()
		end

		task.wait(0.6)

		if settings.ESP.Players then
			for _, child in ipairs(Workspace:GetChildren()) do
				if child:IsA("Highlight") then
					child:Destroy()
				end
			end

			refreshPlayerHighlights()
		end
	end
end)

local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 5)
local Gameplay = Remotes and (Remotes:FindFirstChild("Gameplay") or Remotes:WaitForChild("Gameplay", 5))
local PlayerDataChanged = Gameplay and Gameplay:WaitForChild("PlayerDataChanged", 5)

if PlayerDataChanged then
	PlayerDataChanged.OnClientEvent:Connect(function(p16)
		u46 = p16

		if settings.ESP.Players then
			refreshPlayerHighlights()
		end
	end)
else
	warn("[Miz0] PlayerDataChanged remote was not found; role ESP may be limited.")
end

local function attackAllAsMurderer()
	local ok = not LocalPlayer.Character

	if not ok then
		ok = not LocalPlayer.Character:FindFirstChild("Knife")
	end

	if ok then
		if not LocalPlayer.Backpack:FindFirstChild("Knife") or not LocalPlayer.Character then
			return
		end

		local Humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")

		if Humanoid then
			Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Knife"))
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			if player.Character:FindFirstChild("HumanoidRootPart") then
				local HumanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
				local HumanoidRootPart2 = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

				HumanoidRootPart.Anchored = true
				HumanoidRootPart.CFrame = HumanoidRootPart2.CFrame + HumanoidRootPart2.CFrame.LookVector * 1
			end
		end
	end

	pcall(function()
		LocalPlayer.Character.Knife.Stab:FireServer("Slash")
	end)
end
local function findActiveMap()
	for _, child in ipairs(Workspace:GetChildren()) do
		if not child:FindFirstChild("CoinContainer") then
			continue
		end

		if child:FindFirstChild("Spawns") then
			return child
		end
	end
end

pickupgun = function()
	local v178 = findActiveMap()

	if not v178 then
		return
	end

	local GunDrop = v178:FindFirstChild("GunDrop")

	if not GunDrop then
		return
	end

	if findMurderer() == LocalPlayer then
		return
	end

	if not LocalPlayer.Character then
		return
	end

	local pivot = LocalPlayer.Character:GetPivot()

	LocalPlayer.Character:MoveTo(GunDrop.Position)

	local Gun = LocalPlayer.Backpack:FindFirstChild("Gun")
	local now2 = tick()

	while not Gun and tick() - now2 < 2 do
		Gun = LocalPlayer.Backpack:FindFirstChild("Gun")
		task.wait()
	end

	LocalPlayer.Character:PivotTo(pivot)
end
Teleport_to_lobby = function()
	if Workspace:FindFirstChild("Lobby") then
		if LocalPlayer.Character then
			LocalPlayer.Character:MoveTo(Workspace.Lobby.WorldPivot.Position)
		end
	end
end
Teleport_to_map = function()
	if not findActiveMap() then
		return
	end

	local Spawns = findActiveMap():FindFirstChild("Spawns")

	if not Spawns then
		return
	end

	local children = Spawns:GetChildren()

	if #children > 0 and LocalPlayer.Character then
		LocalPlayer.Character:MoveTo(children[math.random(1, #children)].Position)
	end
end

local function flingTargets(p17)
	local u190 = false

	local function v191(p18)
		local v192 = p18:lower()

		if v192 == "all" or v192 == "others" then
			u190 = true

			return
		end

		if v192 == "random" then
			local players = Players:GetPlayers()
			local v194 = table.find(players, LocalPlayer)

			if v194 then
				table.remove(players, v194)
			end

			if #players == 0 then
				return
			end

			return players[math.random(#players)]
		end

		local players, v196 = Players:GetPlayers()

		for _, v in next, players, v196 do
			if v ~= LocalPlayer then
				if v.Name:lower():match("^" .. v192) then
					return v
				end

				if v.DisplayName:lower():match("^" .. v192) then
					return v
				end
			end
		end
	end
	local function v199(p19)
		local Character = LocalPlayer.Character
		local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		local RootPart = Humanoid and Humanoid.RootPart

		if not Character or not Humanoid or not RootPart then
			return
		end

		local Character2 = p19.Character

		if not Character2 then
			return
		end

		local Humanoid2 = Character2:FindFirstChildOfClass("Humanoid")
		local RootPart2 = Humanoid2 and Humanoid2.RootPart
		local Head = Character2:FindFirstChild("Head")

		if RootPart.Velocity.Magnitude < 50 then
			genv.OldPos = RootPart.CFrame
		end

		if Humanoid2 and Humanoid2.Sit and not u190 then
			return
		end

		if Head then
			Workspace.CurrentCamera.CameraSubject = Head
		elseif Humanoid2 and RootPart2 then
			Workspace.CurrentCamera.CameraSubject = Humanoid2
		end

		if not Character2:FindFirstChildWhichIsA("BasePart") then
			return
		end

		local function v207(p20, p21, p22)
			RootPart.CFrame = CFrame.new(p20.Position) * p21 * p22
			pcall(function()
				Character:SetPrimaryPartCFrame(CFrame.new(p20.Position) * p21 * p22)
			end)
			RootPart.Velocity = Vector3.new(90000000, 900000000, 90000000)
			RootPart.RotVelocity = Vector3.new(900000000, 900000000, 900000000)
		end
		local function v208(p23)
			local now2 = tick()
			local n5 = 0

			while RootPart and Humanoid2 do
				if p23.Velocity.Magnitude < 50 then
					n5 += 100
					v207(p23, CFrame.new(0, 1.5, 0) + Humanoid2.MoveDirection * p23.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(n5), 0, 0))
					task.wait()
					v207(p23, CFrame.new(0, -1.5, 0) + Humanoid2.MoveDirection * p23.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(n5), 0, 0))
					task.wait()
					v207(p23, CFrame.new(2.25, 1.5, -2.25) + Humanoid2.MoveDirection * p23.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(n5), 0, 0))
					task.wait()
					v207(p23, CFrame.new(-2.25, -1.5, 2.25) + Humanoid2.MoveDirection * p23.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(n5), 0, 0))
					task.wait()
					v207(p23, CFrame.new(0, 1.5, 0) + Humanoid2.MoveDirection, CFrame.Angles(math.rad(n5), 0, 0))
					task.wait()
					v207(p23, CFrame.new(0, -1.5, 0) + Humanoid2.MoveDirection, CFrame.Angles(math.rad(n5), 0, 0))
					task.wait()
				else
					v207(p23, CFrame.new(0, 1.5, Humanoid2.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
					task.wait()
					v207(p23, CFrame.new(0, -1.5, -Humanoid2.WalkSpeed), CFrame.Angles(0, 0, 0))
					task.wait()
					v207(p23, CFrame.new(0, 1.5, Humanoid2.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
					task.wait()

					if RootPart2 then
						v207(p23, CFrame.new(0, 1.5, RootPart2.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
						v207(p23, CFrame.new(0, -1.5, -RootPart2.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
						task.wait()
						v207(p23, CFrame.new(0, 1.5, RootPart2.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
					end

					v207(p23, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
					task.wait()
					v207(p23, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
					task.wait()
					v207(p23, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0))
					task.wait()
					v207(p23, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
					task.wait()
				end

				if p23.Velocity.Magnitude > 500 or p23.Parent ~= p19.Character or p19.Parent ~= Players or Humanoid2.Sit or Humanoid.Health <= 0 or now2 + 2 < tick() then
					break
				end
			end
		end

		

		local BodyVelocity = Instance.new("BodyVelocity")

		BodyVelocity.Name = "EpixVel"
		BodyVelocity.Parent = RootPart
		BodyVelocity.Velocity = Vector3.new(900000000, 900000000, 900000000)
		BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

		if RootPart2 then
			v208(RootPart2)
		end

		if BodyVelocity and BodyVelocity.Parent then
			BodyVelocity:Destroy()
		end

		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)

		if genv.OldPos and Humanoid.Health > 0 then
			RootPart.CFrame = genv.OldPos
		end
	end

	for _, v in ipairs(p17) do
		local v214 = v191(v)

		if v214 then
			v199(v214)
		end
	end

	if u190 then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				v199(player)
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(2)

		if settings.AnnoyingStuff.Fling.LoopFlingAllPlayers then
			for _, player in ipairs(Players:GetPlayers()) do
				if player == LocalPlayer then
					continue
				end

				pcall(function()
					flingTargets({ player.Name })
				end)
				task.wait(0.1)
			end
		end
	end
end)
RunService.RenderStepped:Connect(function()
	if not (findSheriff() == LocalPlayer and settings.Gameplay.AutoShooting) then
		return
	end

	local v219 = findMurderer()

	if not v219 or not v219.Character then
		return
	end

	local HumanoidRootPart = v219.Character:FindFirstChild("HumanoidRootPart")

	if not HumanoidRootPart then
		return
	end

	if not LocalPlayer.Character then
		return
	end

	local HumanoidRootPart2 = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

	if not HumanoidRootPart2 then
		return
	end

	local v222 = HumanoidRootPart.Position - HumanoidRootPart2.Position
	local raycastParams = RaycastParams.new()

	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { LocalPlayer.Character }

	local hit = Workspace:Raycast(HumanoidRootPart2.Position, v222, raycastParams)

	if not hit or hit.Instance.Parent == v219.Character then
		local Gun = LocalPlayer.Character:FindFirstChild("Gun")

		Gun = Gun or LocalPlayer.Backpack:FindFirstChild("Gun")

		if Gun then
			local v226 = getHumanoid()

			if v226 and Gun.Parent == LocalPlayer.Backpack then
				v226:EquipTool(Gun)
			end

			local v227 = findMurderer()

			if not v227 or not v227.Character then
				return
			end

			local UpperTorso = v227.Character:FindFirstChild("UpperTorso")
			local Humanoid = v227.Character:FindFirstChild("Humanoid")

			if not UpperTorso or not Humanoid then
				return
			end

			local MoveDirection = Humanoid.MoveDirection
			local v231 = (UpperTorso.Position + UpperTorso.AssemblyLinearVelocity * Vector3.new(0, 0.5, 0) * 0.14 + MoveDirection * 2.8) * (LocalPlayer:GetNetworkPing() * 1000 * 0 + 1)

			pcall(function()
				local Gun2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun")

				if Gun2 then
					Gun2.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(1, v231, "AH2")
				end
			end)
		end
	end
end)
RoundStart.OnClientEvent:Connect(function()
	if settings.AutoRevealRoles then
		notifyRoles()
	end

	if settings.AutoFarm.KillEveryoneAsAMurderer then
		task.wait(1)

		repeat
			attackAllAsMurderer()
			task.wait(1)
		until findMurderer() ~= LocalPlayer
	end

	if settings.AutoFarm.AutoFlingMurderer then
		local v233 = findMurderer()

		if v233 and v233 ~= LocalPlayer then
			flingTargets({ v233.Name })
		end
	end

	if settings.AutoFarm.AutoFlingSheriff then
		local v234 = findSheriff()

		if v234 and v234 ~= LocalPlayer then
			flingTargets({ v234.Name })
		end
	end

	if settings.AutoFarm.TeleportSpawn then
		Teleport_to_lobby()
	end

	task.spawn(startCoinFarm)
end)

local function unlockEmotes()
	pcall(function()
		ReplicatedStorage.Remotes.Extras.GetPlayerData:InvokeServer("GetData")
	end)

	local EmoteModule = ReplicatedStorage.Modules:FindFirstChild("EmoteModule")
	local Emotes = LocalPlayer.PlayerGui.MainGUI.Game:FindFirstChild("Emotes")

	if not EmoteModule or not Emotes then
		return
	end

	local t8 = {
		"headless",
		"zombie",
		"zen",
		"ninja",
		"floss",
		"dab",
		"sit"
	}

	pcall(function()
		require(EmoteModule).GeneratePage(t8, Emotes, "Free Emotes")
	end)
	genv.FreeEmotesOperator = true

	while genv.FreeEmotesOperator do
        local emotePages = Emotes:FindFirstChild("EmotePages")
        if not emotePages then
            break
        end
        if not emotePages:FindFirstChild("Free Emotes") then
            pcall(function()
                require(EmoteModule).GeneratePage(t8, Emotes, "Free Emotes")
            end)
            task.wait(0.5)
        end

		RunService.RenderStepped:Wait()
	end
end
local function hopToPublicServer()
	local t9 = {}

	pcall(function()
		local response = game:HttpGet(("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId))
		local data = HttpService:JSONDecode(response)
		local data2 = data.data or {}

		for _, v in ipairs(data2) do
			if v.id ~= game.JobId and v.playing < v.maxPlayers then
				table.insert(t9, v.id)
			end
		end
	end)

	if #t9 ~= 0 then
		TeleportService:TeleportToPlaceInstance(game.PlaceId, t9[math.random(1, #t9)])

		return
	end

	lib:Notify({
		Title = "ServerHop",
		Content = "No available servers found.",
		Type = "Warning",
		Duration = 3
	})
end

Players.PlayerRemoving:Connect(function()
	task.defer(function()
		if settings.AutoFarm.AutoTeleportToRandomServerIfServerIsEmpty and settings.AutoFarm.PlayersToAutoServerHop > #Players:GetPlayers() then
			hopToPublicServer()
		end
	end)
end)
task.spawn(function()
	while true do
		task.wait(30)

		if settings.AutoFarm.AutoPrestige then
			pcall(function()
				ReplicatedStorage.Remotes.Inventory.Prestige:FireServer()
			end)
		end
	end
end)

local u246 = false

CoinCollected.OnClientEvent:Connect(function(p24, p25, p26)
	if p25 ~= p26 or u246 then
		return
	end

	u246 = true
	task.spawn(function()
		if settings.AutoFarm.KillEveryoneAsAMurdererAtFullBag and findMurderer() == LocalPlayer then
			for i = 1, 10 do
				if findMurderer() ~= LocalPlayer then
					break
				end

				attackAllAsMurderer()
				task.wait(1)
			end
		elseif settings.AutoFarm.AutoFlingMurdererAtFullBag and findMurderer() ~= LocalPlayer then
			for i = 1, 5 do
				local v249 = findMurderer()

				if not v249 or v249 == LocalPlayer then
					break
				end

				flingTargets({ v249.Name })
				task.wait(1)
			end
		elseif settings.AutoFarm.TeleportUnderMap then
			task.wait(0.1)
			teleportToSafeSpot()
		elseif settings.CoinFarm.Settings.DieAtFullBag then
			local v250 = getHumanoid()

			if v250 then
				v250:ChangeState(Enum.HumanoidStateType.Dead)
			end
		end

		task.wait(2)
		u246 = false
	end)
end)

local MainGUI = LocalPlayer.PlayerGui:WaitForChild("MainGUI", 30)
if not MainGUI then
    warn("[Miz0] MainGUI did not appear within 30 seconds")
    genv.miz0MM2Loaded = false
    return
end
local v434 = ReplicatedStorage
local ChangeInventoryItem = v434.Remotes.Inventory.ChangeInventoryItem
local ItemGift = v434:FindFirstChild("ItemGift")

local function v437(p51, p52)
	local ok, result = pcall(require, p51)

	if ok then
		if result ~= nil then
			return result
		end
	end

	return p52
end

local v440 = v437(v434.Modules:FindFirstChild("BoxModule"), {})
local v441 = v437(v434.Database.Sync:FindFirstChild("Item"), {})
local v442 = v437(v434.Modules:FindFirstChild("ProfileData"), {
	Weapons = {
		Owned = {}
	}
})

_G.Cache = _G.Cache or {}
_G.SmallCache = _G.SmallCache or {}

local ItemModule

pcall(function()
	ItemModule = require(v434.Modules.ItemModule)
end)

local t26 = {}
local Owned = (v442.Weapons or {}).Owned or {}

for k, v in pairs(Owned) do
	t26[k] = v
end

local function v448(p53)
	return t26[p53] or 0
end
local function v449(p54, p55)
	if not p54 or p54 == "" then
		return
	end

	local v450 = v448(p54) + p55

	t26[p54] = v450
	pcall(function()
		firesignal(ChangeInventoryItem.OnClientEvent, "Weapons", p54, v450)
	end)

	if ItemGift then
		pcall(function()
			firesignal(ItemGift.OnClientEvent, p54, "Weapons", p55)
		end)
	end
end

local t27 = {
	Common = Color3.fromRGB(134, 142, 150),
	Uncommon = Color3.fromRGB(64, 192, 87),
	Rare = Color3.fromRGB(51, 154, 240),
	Legendary = Color3.fromRGB(250, 176, 5),
	Godly = Color3.fromRGB(190, 75, 219),
	Ancient = Color3.fromRGB(255, 107, 107),
	Unique = Color3.fromRGB(255, 212, 59),
	Classic = Color3.fromRGB(255, 146, 43),
	Vintage = Color3.fromRGB(173, 181, 189),
	Christmas = Color3.fromRGB(32, 201, 151),
	Halloween = Color3.fromRGB(252, 126, 20)
}
local t28 = {
	Unique = 1,
	Ancient = 2,
	Godly = 3,
	Classic = 4,
	Vintage = 5,
	Legendary = 6,
	Rare = 7,
	Uncommon = 8,
	Common = 9
}

local function v453(p56, p57)
	if (p56 == nil or p56 == "") and p57 then
		p56 = tostring(p57)
	end

	if p56 ~= nil then
		if p56 ~= "" then
			if type(p56) == "string" and (string.find(p56, "rbxassetid://", 1, true) == 1 or string.find(p56, "rbxthumb://", 1, true) == 1) then
				return p56
			end

			if ItemModule and type(ItemModule.GetImage) == "function" then
				local ok, result = pcall(function()
					return ItemModule.GetImage(p56)
				end)

				if ok and type(result) == "string" and result ~= "" then
					return result
				end
			end

			if tonumber(p56) then
				return "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=" .. tostring(p56) .. "&bust=" .. tostring(math.random(1, 10000))
			end

			if type(p56) ~= "string" then
				return nil
			end

			if not string.find(p56, "roblox.com/Thumbs/Asset.ashx", 1, true) or string.find(p56, "&bust=", 1, true) then
				return p56
			end

			return p56 .. "&bust=" .. tostring(math.random(1, 10000))
		end
	end

	return nil
end
local function v456(p58)
	local ItemType = p58 and p58.ItemType

	return ItemType == nil or ItemType == "Knife" or ItemType == "Gun"
end
local function v458()
	local t29 = {}

	for k, v in pairs(v441) do
		if type(v) == "table" then
			if v456(v) then
				local ItemName = v.ItemName or k
				local Rarity = v.Rarity or "Unknown"

				table.insert(t29, {
					Id = k,
					Name = ItemName,
					Subtitle = (v.ItemType or "Weapon") .. " / " .. k,
					Badge = Rarity,
					BadgeColor = t27[Rarity],
					Image = v453(v.Image, v.ItemID),
					_SortName = string.lower(ItemName),
					_SortRarity = t28[Rarity] or 99
				})
			end
		end
	end

	table.sort(t29, function(p59, p60)
		if p59._SortRarity == p60._SortRarity then
			return p59._SortName < p60._SortName
		end

		return p59._SortRarity < p60._SortRarity
	end)

	return t29
end

local v464 = v458()

local function v465()
	local v466 = v437(v434.Database.Sync:FindFirstChild("MysteryBox"), {})

	if not v466 or next(v466) == nil then
		return nil
	end

	local t30 = {}

	for k in pairs(v466) do
		table.insert(t30, k)
	end

	return t30[math.random(1, #t30)]
end
local function v469(p61)
	if not p61 or p61 == "" then
		return
	end

	pcall(function()
		v440.OpenBox(v465(), p61)
	end)
	v449(p61, 1)
end

task.spawn(function()
	while true do
		task.wait(0.5)

		if settings.AutoOpenCrates.State then
			if not settings.AutoOpenCrates.Crate then
				continue
			end

			pcall(function()
				ReplicatedStorage.Remotes.MysteryBox.OpenBox:FireServer(unpack({
					"OpenBox",
					settings.AutoOpenCrates.Crate,
					settings.AutoOpenCrates.CrateType
				}))
			end)
		end
	end
end)
game:GetService("Lighting").ChildAdded:Connect(function(child)
	if child.Name == "DepthOfField" then
		child.InFocusRadius = 500
		child:Destroy()
	end
end)

local IS_TOUCH_ONLY = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local function clampValue(p62, p63, p64)
	return math.max(p63, math.min(p64, p62))
end
-- Window sizing is fitted to the current display by the UI adapter.
local uDim2 = UDim2.fromOffset(840, 560)
local vector2 = Vector2.new(300, 320)
local MIZ0_RED = Color3.fromRGB(174, 151, 255)

local function applyMiz0Theme()
    lib:SetTheme("Galaxy")
end

local miz0Window = lib:CreateWindow({
	Title = "MIZ0 | GALAXY",
	Size = uDim2,
	MinSize = vector2,
	MaxSize = Vector2.new(1400, 900),
	MobileScaled = IS_TOUCH_ONLY,
	Resizable = true,
	Theme = "Galaxy",
	ToggleKeybind = Enum.KeyCode.RightControl,
	OnClose = function()
		pcall(function()
			RunService:Set3dRenderingEnabled(true)
		end)
        
        settings.CoinFarm.State = false
        settings.CoinFarm2.State = false
        settings.Noclip = false
        settings.Gameplay.AutoShooting = false
        settings.Emotes.AutoPlayEmotes = false
        settings.Emotes.AutoPlaySelectedEmote = false
        settings.ShuffleWeapons = false
        settings.AutoOpenCrates.State = false
        settings.AutoFarm.AutoPrestige = false
        settings.AnnoyingStuff.Fling.LoopFlingAllPlayers = false
        genv.FreeEmotesOperator = false
        u115 = true
		pcall(stopCoinFarm)
		genv.ValAutoFarmCoins = false
		genv.miz0MM2Loaded = false
		genv.Miz0MM2Window = nil
		print("[Miz0] window closed")
	end
})

applyMiz0Theme()

do
	local v479 = miz0Window:CreateTab({
		Name = "Gameplay"
	})
	local v480 = v479:CreateSection({
		Name = "Tools",
		Side = "Left"
	})

	v480:AddButton({
		Text = "Pick Up Gun",
		Tooltip = "Instant Gun Pick Up",
		Callback = function()
			pickupgun()
		end
	})
	v480:AddToggle({
		Text = "Auto Pick Up Gun",
		Default = false,
		Flag = "AutoPickUpGun",
		Tooltip = "Automatic Instant Gun Pick Up",
		Callback = function(p65)
			settings.Gameplay.AutoPickUpGun = p65
		end
	})

	local v481 = v479:CreateSection({
		Name = "Basic Stuff",
		Side = "Left"
	})

	v481:AddToggle({
		Text = "Noclip",
		Default = false,
		Flag = "Noclip",
		Tooltip = "Walk through walls and objects",
		Callback = function(p66)
			settings.Noclip = p66
		end
	})
	v481:AddButton({
		Text = "Fly GUI",
		Tooltip = "Open the Fly GUI script",
		Callback = function()
			local ok, result = pcall(function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
			end)

			if not ok then
				lib:Notify({
					Title = "Fly GUI failed",
					Content = tostring(result),
					Type = "Danger",
					Duration = 4
				})
			end
		end
	})

	local v484 = v479:CreateSection({
		Name = "More Tools",
		Side = "Left"
	})

	v484:AddButton({
		Text = "Kill Everyone as Murderer",
		Variant = "Danger",
		Tooltip = "Eliminate all players if you are the murderer",
		Callback = function()
			if findMurderer() ~= LocalPlayer then
				lib:Notify({
					Title = "You are not the murderer",
					Content = "You do not have the knife.",
					Type = "Warning",
					Duration = 4
				})
			end

			attackAllAsMurderer()
		end
	})
	v484:AddButton({
		Text = "Bring All Players",
		Tooltip = "Teleport every player to your location (only useful as murderer)",
		Callback = function()
			if findMurderer() ~= LocalPlayer then
				lib:Notify({
					Title = "You are not the murderer",
					Content = "This is only useful when you are the murderer.",
					Type = "Warning",
					Duration = 4
				})

				return
			end

			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character then
					if player.Character:FindFirstChild("HumanoidRootPart") and player ~= LocalPlayer then
						local HumanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
						local HumanoidRootPart2 = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

						HumanoidRootPart.Anchored = true
						HumanoidRootPart.CFrame = HumanoidRootPart2.CFrame + HumanoidRootPart2.CFrame.LookVector * 5
					end
				end
			end

			lib:Notify({
				Title = "Teleported Everyone",
				Content = "All players moved to your position.",
				Type = "Success",
				Duration = 3
			})
		end
	})
	v484:AddToggle({
		Text = "Auto Shoot Murderer",
		Default = false,
		Flag = "AutoShootMurderer",
		Tooltip = "Automatically shoot the murderer when detected",
		Callback = function(p67)
			settings.Gameplay.AutoShooting = p67
		end
	})
	v484:AddButton({
		Text = "Shoot Murderer (manual)",
		Callback = function()
			if not LocalPlayer.Character then
				return
			end

			local Gun = LocalPlayer.Character:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun")

			if Gun then
				local v490 = getHumanoid()

				if v490 and Gun.Parent == LocalPlayer.Backpack then
					v490:EquipTool(Gun)
				end

				local v491 = findMurderer()

				if not v491 or not v491.Character then
					return
				end

				local UpperTorso = v491.Character:FindFirstChild("UpperTorso")
				local Humanoid = v491.Character:FindFirstChild("Humanoid")

				if not UpperTorso or not Humanoid then
					return
				end

				local MoveDirection = Humanoid.MoveDirection
				local v495 = (UpperTorso.Position + UpperTorso.AssemblyLinearVelocity * Vector3.new(0, 0.5, 0) * 0.14 + MoveDirection * 2.8) * (LocalPlayer:GetNetworkPing() * 1000 * 0 + 1)

				pcall(function()
					local Gun2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun")

					if Gun2 then
						Gun2.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(1, v495, "AH2")
					end
				end)
			end
		end
	})

	local v497 = v479:CreateSection({
		Name = "Annoying Stuff",
		Side = "Right"
	})

	local function v498(p68)
		if not p68 or p68 == "" then
			return
		end

		local v499 = p68:lower()

		for _, player in pairs(Players:GetPlayers()) do
			if string.find(player.Name:lower(), v499, 1, true) then
				return player.Name
			end

			if string.find(player.DisplayName:lower(), v499, 1, true) then
				return player.Name
			end
		end
	end

	v497:AddInput({
		Text = "Pick A Player",
		Placeholder = "Enter player name...",
		Default = "",
		Flag = "FlingPick",
		Callback = function(p69)
			settings.AnnoyingStuff.Fling.PickedPlayer = v498(p69)
		end
	})
	v497:AddButton({
		Text = "Fling Chosen Player",
		Callback = function()
			if not settings.AnnoyingStuff.Fling.PickedPlayer then
				return
			end

			flingTargets({ settings.AnnoyingStuff.Fling.PickedPlayer })
		end
	})
	v497:AddButton({
		Text = "Fling Murderer",
		Callback = function()
			local v502 = findMurderer()

			if v502 then
				flingTargets({ v502.Name })
			end
		end
	})
	v497:AddButton({
		Text = "Fling Sheriff",
		Callback = function()
			local v503 = findSheriff()

			if v503 then
				flingTargets({ v503.Name })
			end
		end
	})
	v497:AddButton({
		Text = "Fling All Players",
		Variant = "Danger",
		Callback = function()
			flingTargets({ "All" })
		end
	})
	v497:AddButton({
		Text = "Fling Random Player",
		Callback = function()
			local players = Players:GetPlayers()
			local v505 = table.find(players, LocalPlayer)

			if v505 then
				table.remove(players, v505)
			end

			if #players ~= 0 then
				flingTargets({ players[math.random(#players)].Name })

				return
			end

			lib:Notify({
				Title = "No target",
				Content = "There are no other players in the server.",
				Type = "Warning",
				Duration = 3
			})
		end
	})
	v497:AddToggle({
		Text = "Loop Fling All Players",
		Default = false,
		Flag = "LoopFlingAll",
		Tooltip = "Repeatedly fling all players",
		Callback = function(p70)
			settings.AnnoyingStuff.Fling.LoopFlingAllPlayers = p70
		end
	})

	local v506 = v479:CreateSection({
		Name = "Other Tools",
		Side = "Right"
	})

	v506:AddButton({
		Text = "Teleport to Map",
		Callback = function()
			Teleport_to_map()
		end
	})
	v506:AddButton({
		Text = "Teleport to Lobby",
		Callback = function()
			Teleport_to_lobby()
		end
	})
	v506:AddButton({
		Text = "Notify Murderer Username",
		Callback = function()
			local v507 = findMurderer()

			if not v507 then
				lib:Notify({
					Title = "Murderer",
					Content = "Not found.",
					Type = "Warning",
					Duration = 3
				})

				return
			end

			lib:Notify({
				Title = "Murderer Username",
				Content = v507.Name,
				Type = "Info",
				Duration = 5
			})
		end
	})
	v506:AddButton({
		Text = "Notify Sheriff Username",
		Callback = function()
			local v508 = findSheriff()

			if not v508 then
				lib:Notify({
					Title = "Sheriff",
					Content = "Not found.",
					Type = "Warning",
					Duration = 3
				})

				return
			end

			lib:Notify({
				Title = "Sheriff Username",
				Content = v508.Name,
				Type = "Info",
				Duration = 5
			})
		end
	})
	v506:AddButton({
		Text = "Reveal Roles",
		Callback = function()
			notifyRoles()
		end
	})
	v506:AddToggle({
		Text = "Auto Reveal Roles",
		Default = false,
		Flag = "AutoRevealRoles",
		Tooltip = "Automatically show player roles each round",
		Callback = function(p71)
			settings.AutoRevealRoles = p71
		end
	})

	local v509 = v479:CreateSection({
		Name = "Speed and Jump",
		Side = "Right"
	})

	v509:AddSlider({
		Text = "WalkSpeed",
		Min = 1,
		Max = 100,
		Default = 16,
		Increment = 1,
		Suffix = "studs/s",
		Flag = "WS",
		Callback = function(p72)
			settings.Sliders.Speed = p72
		end
	})
	v509:AddSlider({
		Text = "JumpPower",
		Min = 1,
		Max = 100,
		Default = 50,
		Increment = 1,
		Flag = "JP",
		Callback = function(p73)
			settings.Sliders.Jump = p73
		end
	})
end

local v510 = miz0Window:CreateTab({
	Name = "ESP"
}):CreateSection("ESP Settings")

v510:AddToggle({
	Text = "Players ESP",
	Default = false,
	Flag = "ESPPlayers",
	Tooltip = "Highlight all players on the map",
	Callback = function(p74)
		settings.ESP.Players = p74

		if p74 then
			refreshPlayerHighlights()
		else
			for _, child in ipairs(Workspace:GetChildren()) do
				if child.Name == "PlayerESP" then
					child:Destroy()
				end
			end
		end
	end
})
v510:AddToggle({
	Text = "Dropped Gun ESP",
	Default = false,
	Flag = "ESPGun",
	Tooltip = "Highlight dropped guns",
	Callback = function(p75)
		settings.ESP.DroppedGun = p75
	end
})
v510:AddToggle({
	Text = "Trap ESP",
	Default = false,
	Flag = "ESPTrap",
	Tooltip = "Highlight traps placed by murderer",
	Callback = function(p76)
		settings.ESP.Traps = p76
	end
})

do
	local v513 = miz0Window:CreateTab({
		Name = "Auto Farm"
	})
	local v514 = v513:CreateSection({
		Name = "Autofarm Features",
		Side = "Left"
	})

	v514:AddToggle({
		Text = "Auto Teleport At Spawn",
		Default = false,
		Flag = "AutoTPSpawn",
		Tooltip = "Teleport to spawn when round starts",
		Callback = function(p77)
			settings.AutoFarm.TeleportSpawn = p77
		end
	})
	v514:AddToggle({
		Text = "Auto Kill Everyone As Murderer",
		Default = false,
		Flag = "AutoKillAll",
		Callback = function(p78)
			settings.AutoFarm.KillEveryoneAsAMurderer = p78
		end
	})
	v514:AddToggle({
		Text = "Auto Prestige",
		Default = false,
		Flag = "AutoPrestige",
		Callback = function(p79)
			settings.AutoFarm.AutoPrestige = p79
		end
	})

	local v515 = v513:CreateSection({
		Name = "More Features",
		Side = "Right"
	})

	v515:AddToggle({
		Text = "Auto Fling Murderer",
		Default = false,
		Flag = "AutoFlingM",
		Callback = function(p80)
			settings.AutoFarm.AutoFlingMurderer = p80
		end
	})
	v515:AddToggle({
		Text = "Auto Fling Sheriff",
		Default = false,
		Flag = "AutoFlingS",
		Callback = function(p81)
			settings.AutoFarm.AutoFlingSheriff = p81
		end
	})
	v515:AddToggle({
		Text = "Server Hop If Server Is Empty",
		Default = false,
		Flag = "AutoSH",
		Callback = function(p82)
			settings.AutoFarm.AutoTeleportToRandomServerIfServerIsEmpty = p82
		end
	})
	v515:AddSlider({
		Text = "Players Threshold For Server Hop",
		Min = 1,
		Max = 12,
		Default = 2,
		Increment = 1,
		Flag = "SHThresh",
		Callback = function(p83)
			settings.AutoFarm.PlayersToAutoServerHop = p83
		end
	})
end

do
	local v516 = miz0Window:CreateTab({
		Name = "Coin Farm"
	})
	local v517 = v516:CreateSection({
		Name = "Coin Farm 1 [Fly]",
		Side = "Left"
	})

	v517:AddToggle({
		Text = "Enable Coin Farm 1",
		Default = false,
		Flag = "CF1",
		Tooltip = "Automatically collect coins (fly method)",
		Callback = function(p84)
			settings.CoinFarm.State = p84

			if not p84 then
				local HumanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

				if HumanoidRootPart then
					HumanoidRootPart.Anchored = false

					local MM2_CoinFarmVelocity = HumanoidRootPart:FindFirstChild("MM2_CoinFarmVelocity")

					if MM2_CoinFarmVelocity then
						MM2_CoinFarmVelocity:Destroy()
					end
				end
			end
		end
	})
	v517:AddSlider({
		Text = "Farm Speed",
		Min = 15,
		Max = 25,
		Default = 22.5,
		Increment = 0.5,
		Flag = "CF1Speed",
		Callback = function(p85)
			settings.CoinFarm.Settings.Speed = p85
		end
	})
	v516:CreateSection({
		Name = "Coin Farm 2 [Safe TP]",
		Side = "Left"
	}):AddToggle({
		Text = "Enable Coin Farm 2",
		Default = false,
		Flag = "CF2",
		Tooltip = "Teleport-based safe coin farm",
		Callback = function(p86)
			settings.CoinFarm2.State = p86

			if p86 then
				task.spawn(runSecondCoinFarm)
			end
		end
	})

	local v520 = v516:CreateSection({
		Name = "Coin Settings",
		Side = "Right"
	})

	v520:AddToggle({
		Text = "Destroy Player Models",
		Default = false,
		Flag = "DestroyP",
		Callback = function(p87)
			settings.CoinFarm.Settings.DestroyPlayers = p87
		end
	})
	v520:AddToggle({
		Text = "Destroy Map",
		Default = false,
		Flag = "DestroyM",
		Callback = function(p88)
			settings.CoinFarm.Settings.DestroyMap = p88
		end
	})
	v520:AddToggle({
		Text = "Die At Full Bag",
		Default = false,
		Flag = "DieFull",
		Callback = function(p89)
			settings.CoinFarm.Settings.DieAtFullBag = p89
		end
	})
	v520:AddToggle({
		Text = "Teleport Under Map At Full Bag",
		Default = false,
		Flag = "TPUnderFull",
		Callback = function(p90)
			settings.AutoFarm.TeleportUnderMap = p90
		end
	})
	v520:AddToggle({
		Text = "Auto Fling Murderer At Full Bag",
		Default = false,
		Flag = "AFMFull",
		Callback = function(p91)
			settings.AutoFarm.AutoFlingMurdererAtFullBag = p91
		end
	})
	v520:AddToggle({
		Text = "Disable 3D Rendering",
		Default = false,
		Flag = "Disable3D",
		Callback = function(p92)
			settings.CoinFarm2.Disable3DRendering = p92
			pcall(function()
				RunService:Set3dRenderingEnabled(not p92)
			end)
		end
	})
	v520:AddToggle({
		Text = "Stats Overlay",
		Default = false,
		Flag = "StatsOverlay",
		Callback = function(p93)
			settings.CoinFarm.StatsOverlay = p93
		end
	})

	

end

do
	local n13 = 1

	local function v563()
		if miz0Window and miz0Window._UpdateStatus then
			pcall(miz0Window._UpdateStatus)
		end
	end
	local function v564(p104)
		n13 = clampValue(n13 + p104, 1, 100)
		v563()
	end
	local function v565(p105)
		local v566 = #p105:GetSelected()

		return v566, n13, v566 * n13
	end
	local function v567(p106)
		local selected = p106:GetSelected()

		if #selected == 0 then
			lib:Notify({
				Title = "Nothing selected",
				Content = "Select item cards first. Amount applies to each selected item.",
				Type = "Warning",
				Duration = 3
			})

			return
		end

		local ok, result = pcall(function()
			for _, v in ipairs(selected) do
				v449(v, n13)
			end
		end)

		if not ok then
			lib:Notify({
				Title = "Spawn failed",
				Content = tostring(result),
				Type = "Danger",
				Duration = 4
			})

			return
		end

		lib:Notify({
			Title = "Spawned",
			Content = ("%d selected item(s) x %d each = %d total spawned."):format(#selected, n13, #selected * n13),
			Type = "Success",
			Duration = 3
		})
	end
	local function v573(p107)
		local selected = p107:GetSelected()

		if #selected ~= 0 then
			task.spawn(function()
				local n14 = 0

				for _, v in ipairs(selected) do
					local ok, result = pcall(function()
						v469(v)
					end)

					if ok then
						n14 += 1
					else
						lib:Notify({
							Title = "Crate open failed",
							Content = tostring(result),
							Type = "Danger",
							Duration = 4
						})
					end

					task.wait(0.05)
				end

				if n14 > 0 then
					lib:Notify({
						Title = "Crates opened",
						Content = ("%d item(s)."):format(n14),
						Type = "Success",
						Duration = 3
					})
				end
			end)

			return
		end

		lib:Notify({
			Title = "Nothing selected",
			Content = "Select one or more item cards first.",
			Type = "Warning",
			Duration = 3
		})
	end

	

	

end

do
	local v587 = miz0Window:CreateTab({
		Name = "Misc"
	})
	v587:CreateSection({
		Name = "Unlock Emotes",
		Side = "Left"
	}):AddButton({
		Text = "Unlock All Emotes",
		Callback = function()
			local v589 = getHumanoid()

			if LocalPlayer.PlayerGui:FindFirstChild("MainGUI") then
				if not LocalPlayer.PlayerGui.MainGUI.Game:FindFirstChild("Emotes") or not getRootPart() or not v589 or not (v589.Health > 0) then
					lib:Notify({
						Title = "Not ready",
						Content = "Wait for the game to finish loading.",
						Type = "Warning",
						Duration = 3
					})

					return
				end

				unlockEmotes()
			else
				lib:Notify({
					Title = "Not ready",
					Content = "Wait for the game to finish loading.",
					Type = "Warning",
					Duration = 3
				})
			end
		end
	})

	local v590 = v587:CreateSection({
		Name = "Server Stuff",
		Side = "Right"
	})

	v590:AddButton({
		Text = "Rejoin Server",
		Callback = function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
		end
	})
	v590:AddButton({
		Text = "Server Hop",
		Callback = function()
			hopToPublicServer()
		end
	})

	local v591 = v587:CreateSection({
		Name = "Spam Random Emotes",
		Side = "Right"
	})

	v591:AddToggle({
		Text = "Spam Random Emotes",
		Default = false,
		Flag = "SpamRand",
		Callback = function(p108)
			settings.Emotes.AutoPlayEmotes = p108
		end
	})
	v591:AddSlider({
		Text = "Spam Speed",
		Min = 1,
		Max = 50,
		Default = 1,
		Increment = 1,
		Suffix = "/s",
		Flag = "SpamSpeed",
		Callback = function(p109)
			settings.Emotes.EmoteSpamSpeed = p109
		end
	})

	local v592 = v587:CreateSection({
		Name = "Spam Selected Emote",
		Side = "Right"
	})

	v592:AddToggle({
		Text = "Spam Selected Emote",
		Default = false,
		Flag = "SpamSel",
		Callback = function(p110)
			settings.Emotes.AutoPlaySelectedEmote = p110
		end
	})
	v592:AddDropdown({
		Text = "Pick An Emote",
		Options = EMOTE_NAMES,
		Default = EMOTE_NAMES[1],
		Searchable = true,
		Flag = "PickEmote",
		Callback = function(p111)
			settings.Emotes.SelectedEmote = p111
		end
	})
	v587:CreateSection({
		Name = "Fast Skin Swapper",
		Side = "Right"
	}):AddToggle({
		Text = "Shuffle Weapons",
		Default = false,
		Flag = "ShuffleW",
		Callback = function(p112)
			settings.ShuffleWeapons = p112
		end
	})
end

do
	local v679 = miz0Window:CreateTab({
		Name = "Settings"
	})
	local v680 = v679:CreateSection({
		Name = "Theme",
		Side = "Left"
	})

	v680:AddDropdown({
		Text = "Preset",
		Options = {
			"Galaxy", "Halloween", "AMOLED"
		},
		Default = "Galaxy",
		Searchable = false,
		Flag = "ThemePreset",
		Callback = function(p136)
			lib:SetTheme(p136)
			lib:Notify({
				Title = "Theme",
				Content = p136,
				Type = "Info",
				Duration = 2
			})
		end
	})
	v680:AddDropdown({
		Text = "Density",
		Options = {
			"compact",
			"normal",
			"comfortable"
		},
		Default = "normal",
		Flag = "ThemeDensity",
		Callback = function(p137)
			lib:SetDensity(p137)
			lib:Notify({
				Title = "Density",
				Content = p137,
				Type = "Info",
				Duration = 2
			})
		end
	})
	v680:AddColorPicker({
		Text = "Custom Accent",
		Default = MIZ0_RED,
		Flag = "ThemeAccent",
		Callback = function(p138)
			lib:SetTheme({
				AccentSolid = p138,
				AccentGradientFrom = Color3.new(p138.R * 0.85, p138.G * 0.85, p138.B * 0.85),
				AccentGradientTo = p138
			})
		end
	})

    local photoSettings = v679:CreateSection({Name = "Photo"})
    photoSettings:AddButton({
        Text = "View full image",
        Tooltip = "See the whole photo without any controls covering it.",
        Callback = function() miz0Window:ShowPhoto() end
    })
    photoSettings:AddSlider({
        Text = "Background visibility", Min = 0, Max = 100, Default = 52, Increment = 1,
        Suffix = "%", Callback = function(value) lib:SetPhotoTransparency(1 - value / 100) end
    })
    photoSettings:AddButton({Text = "Reload image", Callback = function() lib:ReloadPhoto() end})

	local v681 = v679:CreateSection({
		Name = "About",
		Side = "Right"
	})

	v681:AddParagraph({
		Title = "Miz0 | MM2",
		Content = "Miz0 Galaxy v" .. lib.Version .. ". Drag the header to move. Use Home or the image icon to see your whole photo. Toggle: RightControl."
	})
	v681:AddParagraph({
		Title = "Credits",
		Content = "Miz0 Galaxy interface, powered by WindUI. Full-image display preserves the photo proportions."
	})
	v681:AddBanner({
		Type = "Info",
		Text = "Murder Mystery 2 only (GameId 66654135). Other games are not supported by this script."
	})
end

local sessionGlobals = genv

if sessionGlobals.Miz0MM2Window then
	pcall(function()
		sessionGlobals.Miz0MM2Window:Destroy()
	end)
end

sessionGlobals.Miz0MM2Window = miz0Window
task.delay(0.4, function()
	lib:Notify({
		Title = "Miz0 | Galaxy ready",
		Content = "Version " .. (lib.Version or "?") .. ". Toggle UI: RightControl.",
		Type = "Success",
		Duration = 5
	})
end)
print("[Miz0] UI ready. Toggle with RightControl.")
