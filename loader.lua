-- MIZ0: translucent cards, horizontal tabs, and a full fitted photo.
local lib
local sessionClosed = false
do
    local PHOTO_URLS = {"https://i.ibb.co/N2q7Lr9C/8.jpg"}
    local Players = game:GetService("Players")
    local Input = game:GetService("UserInputService")
    local Tween = game:GetService("TweenService")
    local photoAsset, photoState, photoBusy = "", "Loading image...", false
    local refreshPhoto = function() end
    local themeName, accent = "Reference", Color3.fromRGB(255, 145, 55)
    local backgroundTransparency, density = 0.18, "normal"
    local themeListeners, densityListeners, connections = {}, {}, {}
    local colors = {Reference = "FF9137", Galaxy = "AE97FF", Halloween = "FFAA66", AMOLED = "9ECFFF"}
    local function make(className, properties, parent)
        local object = Instance.new(className)
        for key, value in pairs(properties) do object[key] = value end
        object.Parent = parent
        return object
    end
    local function round(object, radius)
        make("UICorner", {CornerRadius = UDim.new(0, radius)}, object)
    end
    local function stroke(object, transparency)
        return make("UIStroke", {Color = Color3.fromRGB(80, 80, 87), Transparency = transparency or 0.5, Thickness = 1}, object)
    end
    local function text(parent, value, position, size, small)
        return make("TextLabel", {Text = tostring(value or ""), Position = position, Size = size,
            BackgroundTransparency = 1, Font = small and Enum.Font.Gotham or Enum.Font.GothamMedium,
            TextSize = small and 11 or 13, TextColor3 = small and Color3.fromRGB(163, 163, 171) or Color3.fromRGB(235, 235, 240),
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true, BorderSizePixel = 0}, parent)
    end
    local function button(parent, value, position, size)
        local b = make("TextButton", {Text = value, Position = position, Size = size,
            BackgroundColor3 = Color3.fromRGB(39, 39, 44), BackgroundTransparency = 0.25,
            TextColor3 = Color3.fromRGB(225, 225, 230), TextSize = 12, Font = Enum.Font.GothamMedium,
            AutoButtonColor = false, BorderSizePixel = 0}, parent)
        round(b, 9)
        return b
    end
    local function track(connection)
        connections[#connections + 1] = connection
        return connection
    end
    local function protect(fn, ...)
        if type(fn) ~= "function" then return end
        local ok, result = pcall(fn, ...)
        if not ok then warn("[Miz0] Callback:", result) end
        return result
    end
    local function guiParent()
        return Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    local notificationGui
    lib = {Version = "3.0"}
    function lib:Notify(o)
        if not notificationGui or not notificationGui.Parent then
            notificationGui = make("ScreenGui", {Name = "Miz0Notices", ResetOnSpawn = false, DisplayOrder = 105}, guiParent())
        end
        local notice = make("Frame", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20),
            Size = UDim2.fromOffset(300, 92), BackgroundColor3 = Color3.fromRGB(17, 17, 21), BorderSizePixel = 0}, notificationGui)
        round(notice, 12)
        stroke(notice)
        text(notice, o.Title or "MIZ0", UDim2.fromOffset(14, 12), UDim2.new(1, -28, 0, 20))
        text(notice, o.Content or "", UDim2.fromOffset(14, 36), UDim2.new(1, -28, 0, 44), true)
        task.delay(o.Duration or 4, function() if notice.Parent then notice:Destroy() end end)
    end
    function lib:SetTheme(theme)
        if type(theme) == "string" then
            themeName = colors[theme] and theme or "Reference"
            accent = Color3.fromHex(colors[themeName])
        elseif type(theme) == "table" and typeof(theme.AccentSolid) == "Color3" then
            accent = theme.AccentSolid
        end
        for _, update in ipairs(themeListeners) do update() end
    end
    function lib:SetDensity(value)
        density = ({compact = true, normal = true, comfortable = true})[value] and value or "normal"
        for _, update in ipairs(densityListeners) do update() end
    end
    local function loadPhoto(force)
        if photoBusy or sessionClosed then return end
        photoBusy, photoState = true, "Loading image..."
        refreshPhoto()
        task.spawn(function()
            local ok, result = pcall(function()
                local url = PHOTO_URLS[1]
                assert(type(url) == "string" and url ~= "", "No photo configured")
                if url:match("^rbxassetid://") or url:match("^rbxthumb://") then return url end
                local assetFn = getcustomasset or getsynasset
                local requestFn = request or http_request or (syn and syn.request)
                assert(type(assetFn) == "function" and type(requestFn) == "function" and type(writefile) == "function",
                    "Web images unavailable here. Set PHOTO_URLS to a Roblox image asset ID.")
                local hash = 5381
                for i = 1, #url do hash = (hash * 33 + url:byte(i)) % 2147483647 end
                local cleanUrl = url:match("^[^?#]+") or url
                local extension = (cleanUrl:match("%.(%w+)$") or "jpg"):lower()
                if extension ~= "png" and extension ~= "jpeg" and extension ~= "webp" then extension = "jpg" end
                local path = "miz0_photo_" .. tostring(hash) .. "." .. extension
                if force or not (type(isfile) == "function" and isfile(path)) then
                    local response = requestFn({Url = url, Method = "GET"})
                    assert(response and (response.StatusCode == 200 or response.StatusCode == 201)
                        and type(response.Body) == "string" and #response.Body > 100, "Photo download failed. Select Reload image.")
                    writefile(path, response.Body)
                end
                local asset = assetFn(path)
                assert(type(asset) == "string" and asset ~= "", "Could not register photo")
                return asset
            end)
            photoBusy = false
            if sessionClosed then return end
            photoAsset = ok and result or ""
            photoState = ok and "Background ready · original proportions" or tostring(result):gsub("^.-:%d+: ", "")
            refreshPhoto()
        end)
    end
    function lib:ReloadPhoto() loadPhoto(true) end
    function lib:SetPhotoTransparency(value)
        backgroundTransparency = math.clamp(value, 0, 1)
        refreshPhoto()
    end

    function lib:CreateWindow(o)
        local touch = Input.TouchEnabled and not Input.MouseEnabled
        local gui = make("ScreenGui", {Name = "Miz0ReferenceUI", ResetOnSpawn = false,
            DisplayOrder = 90, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, guiParent())
        local main = make("Frame", {Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(760, 480),
            BackgroundColor3 = Color3.fromRGB(9, 9, 12), BackgroundTransparency = 0.12,
            BorderSizePixel = 0, ClipsDescendants = true, Active = true}, gui)
        round(main, 16)
        stroke(main, 0.4)
        local photo = make("ImageLabel", {Name = "FullBackground", Image = "", ScaleType = Enum.ScaleType.Fit,
            BackgroundTransparency = 1, ImageTransparency = backgroundTransparency,
            Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), ZIndex = 1}, main)
        make("Frame", {BackgroundColor3 = Color3.fromRGB(3, 3, 5), BackgroundTransparency = 0.38,
            BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 2}, main)
        local header = make("Frame", {BackgroundColor3 = Color3.fromRGB(12, 12, 15), BackgroundTransparency = 0.28,
            Size = UDim2.new(1, 0, 0, 56), BorderSizePixel = 0, Active = true, ZIndex = 3}, main)
        make("Frame", {Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1),
            BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(70, 70, 76), BackgroundTransparency = 0.65}, header)
        local tabStrip = make("ScrollingFrame", {Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -248, 0, 36),
            BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X}, header)
        make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder}, tabStrip)
        local search = make("TextBox", {Text = "", PlaceholderText = "⌕  Search modules", ClearTextOnFocus = false,
            Position = UDim2.new(1, -230, 0, 11), Size = UDim2.fromOffset(180, 34), BackgroundColor3 = Color3.fromRGB(14, 14, 18),
            BackgroundTransparency = 0.15, TextColor3 = Color3.fromRGB(232, 232, 236), PlaceholderColor3 = Color3.fromRGB(126, 126, 135),
            TextSize = 11, Font = Enum.Font.Gotham, BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Left}, header)
        round(search, 10)
        stroke(search, 0.5)
        make("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8)}, search)
        local close = button(header, "×", UDim2.new(1, -42, 0, 11), UDim2.fromOffset(32, 34))
        close.BackgroundTransparency, close.TextSize = 1, 24
        local footer = make("Frame", {Position = UDim2.new(0, 0, 1, -34), Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Color3.fromRGB(15, 15, 18), BackgroundTransparency = 0.16, BorderSizePixel = 0, ZIndex = 5}, main)
        make("Frame", {Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.fromRGB(67, 67, 73),
            BackgroundTransparency = 0.5, BorderSizePixel = 0}, footer)
        local dot = make("Frame", {Size = UDim2.fromOffset(7, 7), Position = UDim2.fromOffset(14, 14),
            BackgroundColor3 = Color3.fromRGB(66, 217, 135), BorderSizePixel = 0}, footer)
        round(dot, 7)
        local brand = text(footer, "MIZ0", UDim2.fromOffset(28, 10), UDim2.fromOffset(42, 18), true)
        brand.TextColor3 = accent
        local status = text(footer, "0 modules active", UDim2.fromOffset(76, 10), UDim2.new(1, -125, 0, 18), true)
        status.TextWrapped, status.TextTruncate = false, Enum.TextTruncate.AtEnd
        local grip = button(footer, "◢", UDim2.new(1, -34, 0, 3), UDim2.fromOffset(30, 28))
        grip.BackgroundTransparency = 1
        local launcher = button(gui, "☰", UDim2.fromOffset(12, 12), UDim2.fromOffset(40, 40))
        round(launcher, 20)
        stroke(launcher)

        local tabs, allControls, selectedTab = {}, {}, nil
        local dragAction
        local wrapper = {_raw = main}
        local function updateStatus()
            local active, total = 0, 0
            for _, item in ipairs(allControls) do
                if item.Kind == "Toggle" then total += 1; if item.Value then active += 1 end end
            end
            status.Text = ("%d of %d modules active"):format(active, total)
        end
        local function cleanup()
            if sessionClosed then return end
            sessionClosed = true
            dragAction = nil
            for _, connection in ipairs(connections) do connection:Disconnect() end
            table.clear(connections)
            refreshPhoto = function() end
            protect(o.OnClose)
        end
        function wrapper:Destroy()
            if sessionClosed then return end
            cleanup()
            gui:Destroy()
        end
        track(gui.Destroying:Connect(cleanup))
        refreshPhoto = function()
            if sessionClosed then return end
            photo.Image, photo.ImageTransparency = photoAsset, backgroundTransparency
        end
        local function setVisible(value)
            main.Visible = value
        end
        track(close.Activated:Connect(function() setVisible(false) end))
        track(launcher.Activated:Connect(function() setVisible(not main.Visible) end))
        track(Input.InputBegan:Connect(function(key, processed)
            if processed then return end
            if key.KeyCode == (o.ToggleKeybind or Enum.KeyCode.RightControl) then setVisible(not main.Visible) end
        end))
        local function pointer(key)
            return key.UserInputType == Enum.UserInputType.MouseButton1 or key.UserInputType == Enum.UserInputType.Touch
        end
        track(Input.InputChanged:Connect(function(key)
            if dragAction and (key.UserInputType == Enum.UserInputType.MouseMovement or key.UserInputType == Enum.UserInputType.Touch) then
                dragAction(Vector2.new(key.Position.X, key.Position.Y))
            end
        end))
        track(Input.InputEnded:Connect(function(key) if pointer(key) then dragAction = nil end end))
        track(header.InputBegan:Connect(function(key)
            if not pointer(key) then return end
            local start, origin = Vector2.new(key.Position.X, key.Position.Y), main.Position
            local available, size = gui.AbsoluteSize, main.AbsoluteSize
            local center = Vector2.new(origin.X.Scale * available.X + origin.X.Offset, origin.Y.Scale * available.Y + origin.Y.Offset)
            dragAction = function(p)
                local half = size / 2
                local x = math.clamp(center.X + p.X - start.X, half.X, math.max(half.X, available.X - half.X))
                local y = math.clamp(center.Y + p.Y - start.Y, half.Y, math.max(half.Y, available.Y - half.Y))
                main.Position = UDim2.fromOffset(x, y)
            end
        end))

        local function applySearch()
            local query = search.Text:lower()
            for _, tab in ipairs(tabs) do
                for _, section in ipairs(tab.Sections) do
                    local visible = 0
                    for _, item in ipairs(section.Controls) do
                        local match = query == "" or item.Search:find(query, 1, true) ~= nil
                        item.Frame.Visible = match
                        if match then visible += 1 end
                    end
                    section.Frame.Visible = visible > 0
                end
            end
        end
        track(search:GetPropertyChangedSignal("Text"):Connect(applySearch))
        local function responsive()
            local narrow = main.AbsoluteSize.X < 560
            header.Size = UDim2.new(1, 0, 0, narrow and 94 or 56)
            tabStrip.Size = UDim2.new(1, narrow and -24 or -248, 0, 36)
            search.Position = narrow and UDim2.fromOffset(12, 52) or UDim2.new(1, -230, 0, 11)
            search.Size = narrow and UDim2.new(1, -62, 0, 30) or UDim2.fromOffset(180, 34)
            close.Position = UDim2.new(1, -42, 0, narrow and 50 or 11)
            for _, tab in ipairs(tabs) do
                tab.Scroll.Position = UDim2.fromOffset(12, narrow and 106 or 68)
                tab.Scroll.Size = UDim2.new(1, -24, 1, narrow and -150 or -112)
                tab.Flow.FillDirection = narrow and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
                tab.Left.Size = UDim2.new(narrow and 1 or 0.5, narrow and 0 or -7, 0, 0)
                tab.Right.Size = tab.Left.Size
            end
            local left, top = main.AbsolutePosition.X, main.AbsolutePosition.Y
            launcher.Position = UDim2.fromOffset(left >= 54 and left - 50 or 8, left >= 54 and top + 4 or 8)
        end
        local function fitWindow()
            local size = gui.AbsoluteSize
            local width = math.min(760, math.max(1, size.X - 28))
            local height = math.min(480, math.max(1, size.Y - 40))
            if touch and size.Y > size.X then height = math.min(660, size.Y - 72) end
            main.Size, main.Position = UDim2.fromOffset(width, height), UDim2.fromScale(0.5, 0.5)
            responsive()
        end
        track(main:GetPropertyChangedSignal("AbsoluteSize"):Connect(responsive))
        track(main:GetPropertyChangedSignal("AbsolutePosition"):Connect(responsive))
        track(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitWindow))
        track(grip.InputBegan:Connect(function(key)
            if not pointer(key) then return end
            local start, size = Vector2.new(key.Position.X, key.Position.Y), main.AbsoluteSize
            local origin = main.Position
            dragAction = function(p)
                local available = gui.AbsoluteSize
                local width = math.clamp(size.X + p.X - start.X, math.min(320, available.X - 20), available.X - 20)
                local height = math.clamp(size.Y + p.Y - start.Y, math.min(280, available.Y - 20), available.Y - 20)
                main.Size = UDim2.fromOffset(width, height)
                main.Position = origin + UDim2.fromOffset((width - size.X) / 2, (height - size.Y) / 2)
            end
        end))

        local function addThemeListener(fn) themeListeners[#themeListeners + 1] = fn; fn() end
        addThemeListener(function() brand.TextColor3 = accent end)
        function wrapper:CreateTab(cfg)
            local name = tostring(cfg.Name or "Tab")
            local tabButton = button(tabStrip, name == "Home" and "All" or name, UDim2.new(), UDim2.fromOffset(math.max(42, #name * 7 + 22), 34))
            tabButton.BackgroundTransparency = 1
            local scroll = make("ScrollingFrame", {Name = name, Position = UDim2.fromOffset(12, 68), Size = UDim2.new(1, -24, 1, -112),
                BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Color3.fromRGB(114, 114, 123),
                ScrollBarImageTransparency = 0.4, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false, ZIndex = 3}, main)
            local page = make("Frame", {Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1}, scroll)
            local flow = make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14),
                SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Top}, page)
            local function column(order)
                local frame = make("Frame", {Size = UDim2.new(0.5, -7, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1, LayoutOrder = order}, page)
                local layout = make("UIListLayout", {Padding = UDim.new(0, 18), SortOrder = Enum.SortOrder.LayoutOrder}, frame)
                densityListeners[#densityListeners + 1] = function()
                    layout.Padding = UDim.new(0, ({compact = 12, normal = 18, comfortable = 24})[density])
                end
                return frame
            end
            local tab = {Scroll = scroll, Flow = flow, Left = column(1), Right = column(2), Sections = {}, Button = tabButton}
            tabs[#tabs + 1] = tab
            local proxy = {_tab = tab}
            function proxy:Select()
                selectedTab = tab
                for _, item in ipairs(tabs) do
                    local selected = item == tab
                    item.Scroll.Visible = selected
                    item.Button.BackgroundTransparency = selected and 0.06 or 1
                    item.Button.TextColor3 = selected and Color3.fromRGB(245, 245, 248) or Color3.fromRGB(162, 162, 170)
                end
                applySearch()
            end
            track(tabButton.Activated:Connect(function() proxy:Select() end))
            function proxy:CreateSection(c)
                c = type(c) == "string" and {Name = c} or (c or {})
                local side = c.Side == "Right" and tab.Right or (c.Side == "Left" and tab.Left or (#tab.Sections % 2 == 0 and tab.Left or tab.Right))
                local frame = make("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1, LayoutOrder = #tab.Sections + 1}, side)
                local layout = make("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, frame)
                local heading = text(frame, tostring(c.Name or "Modules"):upper(), UDim2.new(), UDim2.new(1, 0, 0, 16), true)
                heading.TextSize, heading.TextColor3, heading.LayoutOrder = 9, Color3.fromRGB(140, 140, 149), -1
                local section = {Frame = frame, Controls = {}}
                tab.Sections[#tab.Sections + 1] = section
                densityListeners[#densityListeners + 1] = function()
                    layout.Padding = UDim.new(0, ({compact = 6, normal = 10, comfortable = 14})[density])
                end
                local out = {}
                local function card(x, kind, height, rightSpace)
                    local f = make("Frame", {Size = UDim2.new(1, 0, 0, height or 76), BackgroundColor3 = Color3.fromRGB(20, 20, 24),
                        BackgroundTransparency = 0.22, BorderSizePixel = 0, LayoutOrder = #section.Controls + 1}, frame)
                    round(f, 13)
                    stroke(f, 0.43)
                    local title = text(f, x.Text or x.Title or "Module", UDim2.fromOffset(14, 12), UDim2.new(1, -(rightSpace or 64), 0, 19))
                    title.TextTruncate, title.TextWrapped = Enum.TextTruncate.AtEnd, false
                    local desc = text(f, x.Tooltip or x.Content or "", UDim2.fromOffset(14, 35), UDim2.new(1, -28, 0, (height or 76) - 42), true)
                    local item = {Frame = f, Kind = kind, Search = ((x.Text or x.Title or "") .. " " .. (x.Tooltip or x.Content or "")):lower()}
                    section.Controls[#section.Controls + 1], allControls[#allControls + 1] = item, item
                    updateStatus()
                    return f, item, title, desc
                end
                function out:AddButton(x)
                    local f = card(x, "Button", x.Tooltip and 86 or 58, 52)
                    local arrow = text(f, "↗", UDim2.new(1, -34, 0, 12), UDim2.fromOffset(24, 24))
                    arrow.TextSize = 19
                    local hit = button(f, "", UDim2.new(), UDim2.fromScale(1, 1))
                    hit.BackgroundTransparency = 1
                    track(hit.Activated:Connect(function() protect(x.Callback) end))
                    return {SetTitle = function(_, value) f:FindFirstChildOfClass("TextLabel").Text = tostring(value) end}
                end
                function out:AddToggle(x)
                    local f, item = card(x, "Toggle", x.Tooltip and 90 or 64, 82)
                    local switch = button(f, "", UDim2.new(1, -58, 0, 12), UDim2.fromOffset(42, 24))
                    round(switch, 24)
                    local knob = make("Frame", {Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(3, 3),
                        BackgroundColor3 = Color3.fromRGB(250, 250, 252), BorderSizePixel = 0}, switch)
                    round(knob, 18)
                    local control = {}
                    function control:Set(value, silent)
                        item.Value = value == true
                        switch.BackgroundColor3 = item.Value and Color3.fromRGB(100, 100, 108) or Color3.fromRGB(53, 53, 61)
                        Tween:Create(knob, TweenInfo.new(0.14), {Position = UDim2.fromOffset(item.Value and 21 or 3, 3)}):Play()
                        updateStatus()
                        if not silent then protect(x.Callback, item.Value) end
                    end
                    track(switch.Activated:Connect(function() control:Set(not item.Value) end))
                    control:Set(x.Default == true, true)
                    return control
                end
                function out:AddSlider(x)
                    local f = card(x, "Slider", 96, 90)
                    local valueText = text(f, "", UDim2.new(1, -80, 0, 12), UDim2.fromOffset(66, 18), true)
                    valueText.TextXAlignment = Enum.TextXAlignment.Right
                    local rail = make("Frame", {Position = UDim2.fromOffset(15, 70), Size = UDim2.new(1, -30, 0, 4),
                        BackgroundColor3 = Color3.fromRGB(60, 60, 68), BorderSizePixel = 0}, f)
                    round(rail, 4)
                    local fill = make("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = accent, BorderSizePixel = 0}, rail)
                    round(fill, 4)
                    local knob = make("Frame", {Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Color3.fromRGB(244, 244, 248), BorderSizePixel = 0}, rail)
                    round(knob, 10)
                    local hit = button(rail, "", UDim2.fromOffset(0, -10), UDim2.new(1, 0, 0, 24))
                    hit.BackgroundTransparency = 1
                    local minimum, maximum, step = x.Min or 0, x.Max or 100, x.Increment or 1
                    local control = {Value = x.Default or minimum}
                    function control:Set(value, silent)
                        local range = math.max(maximum - minimum, 0.0001)
                        value = math.clamp(minimum + math.floor((value - minimum) / step + 0.5) * step, minimum, maximum)
                        self.Value = value
                        local ratio = (value - minimum) / range
                        fill.Size, knob.Position = UDim2.fromScale(ratio, 1), UDim2.fromScale(ratio, 0.5)
                        valueText.Text = tostring(math.floor(value * 100 + 0.5) / 100) .. (x.Suffix and (" " .. x.Suffix) or "")
                        if not silent then protect(x.Callback, value) end
                    end
                    track(hit.InputBegan:Connect(function(key)
                        if not pointer(key) then return end
                        dragAction = function(p)
                            local ratio = math.clamp((p.X - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1), 0, 1)
                            control:Set(minimum + ratio * (maximum - minimum))
                        end
                        dragAction(Vector2.new(key.Position.X, key.Position.Y))
                    end))
                    addThemeListener(function() fill.BackgroundColor3 = accent end)
                    control:Set(control.Value, true)
                    return control
                end
                local function dropdown(x, multi)
                    local f = card(x, "Dropdown", 86, 28)
                    local selectButton = button(f, "", UDim2.fromOffset(13, 39), UDim2.new(1, -26, 0, 30))
                    local menu = make("ScrollingFrame", {Position = UDim2.fromOffset(13, 82), Size = UDim2.new(1, -26, 0, 150),
                        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(),
                        AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false}, f)
                    make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, menu)
                    local choices, chosen, opened, control = x.Options or {}, {}, false, {}
                    local selected = x.Default
                    local optionButtons = {}
                    local function refresh()
                        if multi then
                            local labels = {}
                            for _, value in ipairs(choices) do if chosen[value] then labels[#labels + 1] = tostring(value) end end
                            selectButton.Text = (#labels > 0 and table.concat(labels, ", ") or "Select...") .. "  ⌄"
                        else selectButton.Text = tostring(selected or "Select...") .. "  ⌄" end
                        selectButton.TextTruncate = Enum.TextTruncate.AtEnd
                        for value, option in pairs(optionButtons) do
                            option.BackgroundTransparency = ((multi and chosen[value]) or (not multi and selected == value)) and 0 or 0.7
                        end
                    end
                    local function setOpen(value)
                        opened, menu.Visible = value, value
                        f.Size = UDim2.new(1, 0, 0, value and (96 + math.min(#choices * 30, 150)) or 86)
                        menu.Size = UDim2.new(1, -26, 0, math.min(#choices * 30, 150))
                    end
                    function control:Set(value, silent)
                        if multi then
                            table.clear(chosen)
                            for _, entry in ipairs(type(value) == "table" and value or {}) do chosen[entry] = true end
                        else selected = value end
                        refresh()
                        if not silent then protect(x.Callback, value) end
                    end
                    for i, value in ipairs(choices) do
                        local option = button(menu, tostring(value), UDim2.new(), UDim2.new(1, -4, 0, 26))
                        option.LayoutOrder, optionButtons[value] = i, option
                        track(option.Activated:Connect(function()
                            if multi then
                                chosen[value] = not chosen[value]
                                local selectedValues = {}
                                for _, entry in ipairs(choices) do if chosen[entry] then selectedValues[#selectedValues + 1] = entry end end
                                protect(x.Callback, selectedValues)
                            else selected = value; setOpen(false); protect(x.Callback, value) end
                            refresh()
                        end))
                    end
                    track(selectButton.Activated:Connect(function() setOpen(not opened) end))
                    control:Set(x.Default, true)
                    return control
                end
                function out:AddDropdown(x) return dropdown(x, false) end
                function out:AddMultiDropdown(x) return dropdown(x, true) end
                function out:AddInput(x)
                    local f = card(x, "Input", 90, 28)
                    local entry = make("TextBox", {Text = tostring(x.Default or ""), PlaceholderText = x.Placeholder or "Type here...",
                        ClearTextOnFocus = false, Position = UDim2.fromOffset(13, 40), Size = UDim2.new(1, -26, 0, 32),
                        BackgroundColor3 = Color3.fromRGB(31, 31, 37), TextColor3 = Color3.fromRGB(233, 233, 240),
                        PlaceholderColor3 = Color3.fromRGB(132, 132, 142), TextSize = 12, Font = Enum.Font.Gotham, BorderSizePixel = 0}, f)
                    round(entry, 8)
                    track(entry.FocusLost:Connect(function() protect(x.Callback, entry.Text) end))
                    return {Set = function(_, value) entry.Text = tostring(value); protect(x.Callback, entry.Text) end}
                end
                function out:AddParagraph(x)
                    local f, item, title, desc = card(x, "Paragraph", 116, 28)
                    desc.Size = UDim2.new(1, -28, 0, 68)
                    local control = {}
                    function control:SetTitle(value) title.Text = tostring(value); item.Search = (title.Text .. " " .. desc.Text):lower() end
                    function control:SetContent(value) desc.Text = tostring(value); item.Search = (title.Text .. " " .. desc.Text):lower() end
                    return control
                end
                function out:AddBanner(x) return self:AddParagraph({Title = "MIZ0", Content = x.Text}) end
                function out:AddColorPicker(x)
                    local f = card(x, "Color", 90, 28)
                    local entry = make("TextBox", {Text = "#" .. (x.Default or accent):ToHex(), ClearTextOnFocus = false,
                        Position = UDim2.fromOffset(13, 40), Size = UDim2.new(1, -26, 0, 32),
                        BackgroundColor3 = Color3.fromRGB(31, 31, 37), TextColor3 = x.Default or accent,
                        TextSize = 12, Font = Enum.Font.Gotham, BorderSizePixel = 0}, f)
                    round(entry, 8)
                    local current = x.Default or accent
                    track(entry.FocusLost:Connect(function()
                        local hex = entry.Text:gsub("#", "")
                        if #hex == 6 and hex:match("^%x+$") then current = Color3.fromHex(hex); protect(x.Callback, current) end
                        entry.Text, entry.TextColor3 = "#" .. current:ToHex(), current
                    end))
                    return {Set = function(_, value) current = value; entry.Text = "#" .. value:ToHex(); entry.TextColor3 = value; protect(x.Callback, value) end}
                end
                return out
            end
            responsive()
            if not selectedTab then proxy:Select() end
            return proxy
        end

        local home = wrapper:CreateTab({Name = "Home"})
        local overview = home:CreateSection({Name = "MURDER MYSTERY 2", Side = "Left"})
        overview:AddParagraph({Title = "◉  Session", Content = "MIZ0 interface\nChoose a tab above to find your modules.\nUse the switches to enable a feature.\nRightControl shows or hides the menu."})
        local photoSection = home:CreateSection({Name = "APPEARANCE", Side = "Right"})
        local imageInfo = photoSection:AddParagraph({Title = "Background image", Content = photoState})
        photoSection:AddButton({Text = "Reload image", Tooltip = "Refresh the image behind your modules.", Callback = function() lib:ReloadPhoto() end})
        local baseRefresh = refreshPhoto
        refreshPhoto = function() baseRefresh(); imageInfo:SetContent(photoState) end
        home:Select()
        fitWindow()
        loadPhoto(false)
        return wrapper
    end
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
local uDim2 = UDim2.fromOffset(760, 480)
local vector2 = Vector2.new(300, 320)
local MIZ0_RED = Color3.fromRGB(255, 145, 55)

local function applyMiz0Theme()
    lib:SetTheme("Reference")
end

local miz0Window = lib:CreateWindow({
	Title = "MIZ0",
	Size = uDim2,
	MinSize = vector2,
	MaxSize = Vector2.new(1400, 900),
	MobileScaled = IS_TOUCH_ONLY,
	Resizable = true,
	Theme = "Reference",
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
			"Reference", "Galaxy", "Halloween", "AMOLED"
		},
		Default = "Reference",
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
    photoSettings:AddSlider({
        Text = "Background visibility", Min = 0, Max = 100, Default = 82, Increment = 1,
        Suffix = "%", Callback = function(value) lib:SetPhotoTransparency(1 - value / 100) end
    })
    photoSettings:AddButton({Text = "Reload image", Callback = function() lib:ReloadPhoto() end})

	local v681 = v679:CreateSection({
		Name = "About",
		Side = "Right"
	})

	v681:AddParagraph({
		Title = "Miz0 | MM2",
		Content = "MIZ0 v" .. lib.Version .. ". Drag the top bar to move. RightControl shows or hides the menu. Adjust the background in Settings."
	})
	v681:AddParagraph({
		Title = "Credits",
		Content = "MIZ0 custom interface. Translucent cards, horizontal tabs, and a fitted background image."
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
		Title = "MIZ0 ready",
		Content = "Version " .. (lib.Version or "?") .. ". Toggle UI: RightControl.",
		Type = "Success",
		Duration = 5
	})
end)
print("[Miz0] UI ready. Toggle with RightControl.")
