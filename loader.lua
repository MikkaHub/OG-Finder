if not game:IsLoaded() then game.Loaded:Wait() end

-- ============================================================
-- FinderUI -- DIVISION 3 ONLY  (Faded style)
-- ============================================================

local CoreGui            = game:GetService("CoreGui")
local UIS                = game:GetService("UserInputService")
local TS                 = game:GetService("TweenService")
local Players            = game:GetService("Players")
local LocalPlayer        = Players.LocalPlayer
local RunService         = game:GetService("RunService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local HttpService        = game:GetService("HttpService")
local SoundService       = game:GetService("SoundService")

if CoreGui:FindFirstChild("FinderUI") then CoreGui:FindFirstChild("FinderUI"):Destroy() end

local DIVISION_MODE = 3
local PLACE_ID = game.PlaceId
local RS = ReplicatedStorage

-- ============================================================
-- TRADE REMOTES
-- ============================================================
local SearchUser = nil
local Invite     = nil

task.spawn(function()
    local children = ReplicatedStorage:GetDescendants()
    for i, obj in ipairs(children) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local nextObj = children[i + 1]
            if nextObj then
                if obj.Name == "RF/TradeService/SearchUser" then SearchUser = nextObj end
                if obj.Name == "RF/TradeService/Invite"     then Invite     = nextObj end
            end
        end
        if i % 50 == 0 then task.wait() end
    end
end)

local SEARCH_UUID = "792baf13-54a1-4663-92c4-1edd9da1e3e2"
local INVITE_UUID = "afb005f9-6e81-4e0a-8bb0-3555938a9658"

local function invokeTrade(userId, onResult)
    if not (SearchUser and Invite) then
        if onResult then onResult(false, "Remotes not ready") end
        return
    end
    task.spawn(function()
        local ok1, found, inGame, canInvite = pcall(function()
            return SearchUser:InvokeServer(SEARCH_UUID, userId)
        end)
        if not (ok1 and found and inGame and canInvite) then
            if onResult then onResult(false, "Not found / offline / busy") end
            return
        end
        local ok2, result = pcall(function()
            return Invite:InvokeServer(INVITE_UUID, userId)
        end)
        if onResult then onResult(ok2 and result, ok2 and "Sent" or "Invite failed") end
    end)
end

-- ============================================================
-- HTTP / PRESENCE / SERVER FINDER
-- ============================================================
local function httpRequest(data)
    if syn and syn.request then return syn.request(data)
    elseif http_request then return http_request(data)
    elseif request then return request(data) end
end

local function httpGet(url, maxRetries)
    maxRetries = maxRetries or 3
    for attempt = 1, maxRetries do
        local ok, res = pcall(function() return httpRequest({Url=url, Method="GET"}) end)
        if ok and res and res.Body and res.Body ~= "" then
            local code = res.StatusCode or res.Status
            if code == 429 or (res.Body:find("TooManyRequests") or res.Body:find("rate limit")) then
                task.wait(0.5 * attempt)
            else
                return res.Body
            end
        else
            task.wait(0.3 * attempt)
        end
    end
    return nil
end

local function normalizeThumb(url)
    if not url then return nil end
    return url:match("^([^?]+)") or url
end

local function getAvatarThumb(userId)
    local ok, res = pcall(function()
        return httpRequest({
            Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..tostring(userId).."&size=150x150&format=Png&isCircular=false",
            Method = "GET",
        })
    end)
    if ok and res and res.Body then
        local d; pcall(function() d = HttpService:JSONDecode(res.Body) end)
        if d and d.data and d.data[1] then return d.data[1].imageUrl end
    end
    return nil
end

local _csrfToken = nil
local _csrfFetchedAt = 0

local function extractCSRF(headers)
    if not headers then return nil end
    local t = headers["X-CSRF-Token"] or headers["x-csrf-token"]
              or headers["X-Csrf-Token"] or headers["x-Csrf-token"]
    if t and t ~= "" then return t end
    return nil
end

local function refreshCSRF()
    local ok, res = pcall(function()
        return httpRequest({
            Url    = "https://auth.roblox.com/v2/logout",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body   = "{}"
        })
    end)
    if ok and res then
        local t = extractCSRF(res.Headers)
        if t then
            _csrfToken = t
            _csrfFetchedAt = tick()
            return t
        end
    end
    return _csrfToken
end

local function fetchPresence(userId)
    if not userId or not httpRequest then return nil end
    local body = HttpService:JSONEncode({userIds = {userId}})
    local url  = "https://presence.roblox.com/v1/presence/users"
    local function doPresenceRequest(token)
        local hdrs = {["Content-Type"] = "application/json"}
        if token then hdrs["X-CSRF-Token"] = token end
        return pcall(function()
            return httpRequest({Url = url, Method = "POST", Headers = hdrs, Body = body})
        end)
    end
    local function parsePresence(res)
        if not (res and res.Body) then return nil end
        local d; pcall(function() d = HttpService:JSONDecode(res.Body) end)
        if d and d.userPresences and d.userPresences[1] then
            local p = d.userPresences[1]
            return {
                presenceType = p.userPresenceType,
                placeId      = tonumber(p.placeId) or 0,
                rootPlaceId  = tonumber(p.rootPlaceId) or 0,
                lastLocation = p.lastLocation or ""
            }
        end
        return nil
    end
    local csrf = (_csrfToken and (tick() - _csrfFetchedAt) < 270) and _csrfToken or nil
    local ok, res = doPresenceRequest(csrf)
    if ok and res then
        local code = tonumber(res.StatusCode or res.Status) or 200
        if code == 403 then
            local newToken = extractCSRF(res.Headers)
            if newToken then
                _csrfToken = newToken
                _csrfFetchedAt = tick()
            else
                newToken = refreshCSRF()
            end
            if newToken then ok, res = doPresenceRequest(newToken) end
        end
    end
    return ok and parsePresence(res) or nil
end

local _pollingDots = {}
local showOnlineToast
local showOfflineToast
local showSpawnToast
local addToOnlineTab
local removeFromOnlineTab

local function startPresencePolling(dotFrame, userId, onComeOnline, onGoOffline)
    if not (dotFrame and userId) then return end
    if _pollingDots[dotFrame] then return end
    _pollingDots[dotFrame] = true
    task.spawn(function()
        local lastOnline = nil
        while dotFrame and dotFrame.Parent do
            local presence = fetchPresence(userId)
            if dotFrame and dotFrame.Parent then
                if presence ~= nil then
                    local isOnline = (presence.presenceType == 2)
                    dotFrame.BackgroundColor3 = isOnline
                        and Color3.fromRGB(120, 220, 130)
                        or  Color3.fromRGB(230, 110, 110)
                    if isOnline and lastOnline ~= true then
                        lastOnline = true
                        task.spawn(function()
                            while dotFrame and dotFrame.Parent and _pollingDots[dotFrame] do
                                TS:Create(dotFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                                    {BackgroundTransparency = 0.45}):Play()
                                task.wait(0.8)
                                if not (dotFrame and dotFrame.Parent) then break end
                                TS:Create(dotFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                                    {BackgroundTransparency = 0}):Play()
                                task.wait(0.8)
                            end
                        end)
                        if onComeOnline then task.spawn(onComeOnline) end
                    elseif (not isOnline) and lastOnline == true then
                        lastOnline = false
                        if dotFrame and dotFrame.Parent then dotFrame.BackgroundTransparency = 0 end
                        if onGoOffline then task.spawn(onGoOffline) end
                    elseif lastOnline == nil then
                        lastOnline = isOnline
                        if isOnline and onComeOnline then task.spawn(onComeOnline) end
                    end
                end
            end
            task.wait(3.5)
        end
        _pollingDots[dotFrame] = nil
    end)
end

local function findUserServer(userId)
    local presence = fetchPresence(userId)
    if presence and presence.presenceType == 2 then end
    local targetThumb = normalizeThumb(getAvatarThumb(userId))
    if not targetThumb then return nil end
    local allServers = {}
    local cursor = nil
    for _ = 1, 1000 do
        local url = "https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100"
        if cursor then url = url.."&cursor="..cursor end
        local body = httpGet(url, 4)
        if not body then break end
        local data; pcall(function() data = HttpService:JSONDecode(body) end)
        if not data or not data.data then break end
        for _, server in ipairs(data.data) do
            if server.id and server.playing and server.playing > 0 then
                table.insert(allServers, {id=server.id, tokens=server.playerTokens or {}})
            end
        end
        cursor = data.nextPageCursor
        if not cursor then break end
    end
    if #allServers == 0 then return nil end
    local BATCH = 20
    local foundJob = nil
    local i = 1
    while i <= #allServers and not foundJob do
        local batchEnd = math.min(i + BATCH - 1, #allServers)
        local completed, batchSize = 0, batchEnd - i + 1
        for j = i, batchEnd do
            local entry = allServers[j]
            task.spawn(function()
                if foundJob then completed = completed + 1; return end
                if #entry.tokens > 0 then
                    local reqs = {}
                    for k, tok in ipairs(entry.tokens) do
                        table.insert(reqs, {requestId=tostring(k), type="AvatarHeadShot", token=tok, size="150x150", format="png"})
                    end
                    local ok, res = pcall(function()
                        return httpRequest({
                            Url = "https://thumbnails.roblox.com/v1/batch",
                            Method = "POST",
                            Headers = {["Content-Type"]="application/json"},
                            Body = HttpService:JSONEncode(reqs),
                        })
                    end)
                    if ok and res and res.Body then
                        local bd; pcall(function() bd = HttpService:JSONDecode(res.Body) end)
                        if bd and bd.data then
                            for _, item in ipairs(bd.data) do
                                if item.imageUrl and normalizeThumb(item.imageUrl) == targetThumb then
                                    foundJob = entry.id; break
                                end
                            end
                        end
                    end
                end
                completed = completed + 1
            end)
        end
        local ws = tick()
        while completed < batchSize and not foundJob and (tick()-ws) < 15 do task.wait(0.05) end
        i = batchEnd + 1
    end
    return foundJob
end

local function getUserIdFromUsername(username)
    local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(username) end)
    if ok and id then return id end
    local ok2, res = pcall(function()
        return httpRequest({
            Url = "https://users.roblox.com/v1/usernames/users",
            Method = "POST",
            Headers = {["Content-Type"]="application/json"},
            Body = HttpService:JSONEncode({usernames={username}, excludeBannedUsers=false}),
        })
    end)
    if ok2 and res and res.Body then
        local d; pcall(function() d = HttpService:JSONDecode(res.Body) end)
        if d and d.data and d.data[1] then return d.data[1].id end
    end
    return nil
end

-- ============================================================
-- THEME (Faded grayscale)
-- ============================================================
local T = {
    BG          = Color3.fromRGB(18,  18,  18),
    Header      = Color3.fromRGB(8,   8,   8),
    Card        = Color3.fromRGB(24,  24,  24),
    CardHover   = Color3.fromRGB(32,  32,  32),
    Border      = Color3.fromRGB(45,  45,  45),
    BorderHover = Color3.fromRGB(70,  70,  70),
    White       = Color3.fromRGB(245, 245, 245),
    Dim         = Color3.fromRGB(110, 110, 110),
    TabActive   = Color3.fromRGB(245, 245, 245),
    TabInact    = Color3.fromRGB(75,  75,  75),
    TrackOn     = Color3.fromRGB(240, 240, 240),
    TrackOff    = Color3.fromRGB(45,  45,  45),
    KnobOn      = Color3.fromRGB(10,  10,  10),
    KnobOff     = Color3.fromRGB(160, 160, 160),
    Good        = Color3.fromRGB(120, 220, 130),
    Bad         = Color3.fromRGB(230, 110, 110),
    Warn        = Color3.fromRGB(220, 180,  90),
    AccentBg    = Color3.fromRGB(245, 245, 245),
    AccentFg    = Color3.fromRGB(15,  15,  15),
    SubCard     = Color3.fromRGB(16,  16,  20),
    SubField    = Color3.fromRGB(20,  20,  24),
}

local F = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local M = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local S = TweenInfo.new(0.5,  Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function Tween(o,i,p) TS:Create(o,i,p):Play() end
local function Corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8); c.Parent = p
    return c
end
local function Stroke(p, col, th, trans)
    local s = Instance.new("UIStroke")
    s.Color = col or T.Border; s.Thickness = th or 1
    s.Transparency = trans or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end
local function Padding(p, t, b, l, r)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, t or 0)
    u.PaddingBottom = UDim.new(0, b or 0)
    u.PaddingLeft   = UDim.new(0, l or 0)
    u.PaddingRight  = UDim.new(0, r or 0)
    u.Parent = p
end
local function Label(p, txt, sz, col, font)
    local l = Instance.new("TextLabel")
    l.Text = txt or ""; l.TextSize = sz or 13
    l.TextColor3 = col or T.White
    l.Font = font or Enum.Font.GothamMedium
    l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = p
    return l
end

-- ============================================================
-- CONFIG
-- ============================================================
local CFG_PATH     = "FinderUI_D3_config.json"
local ONLINE_PATH  = "FinderUI_D3_online.json"
local cfg = {
    notifications = true,
    sounds        = true,
}
local function saveConfig()
    pcall(function() writefile(CFG_PATH, HttpService:JSONEncode(cfg)) end)
end
local function loadConfig()
    pcall(function()
        if isfile(CFG_PATH) then
            local data = HttpService:JSONDecode(readfile(CFG_PATH))
            for _, k in ipairs({"notifications","sounds"}) do
                if data[k] ~= nil then cfg[k] = data[k] end
            end
        end
    end)
end
loadConfig()

local _notifSound = Instance.new("Sound")
_notifSound.SoundId = "rbxassetid://4590662766"
_notifSound.Volume  = 0.6
_notifSound.RollOffMaxDistance = 0
_notifSound.Parent  = SoundService

local function playNotifSound()
    if not cfg.sounds then return end
    pcall(function() SoundService:PlayLocalSound(_notifSound) end)
end

-- ============================================================
-- SIZING
-- ============================================================
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local isPhone = false
if isMobile then
    local _vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
    isPhone = math.min(_vp.X, _vp.Y) < 600
end
local WIN_W = isPhone and 270 or (isMobile and 290 or 370)
local WIN_H = isPhone and 330 or (isMobile and 350 or 430)

-- ============================================================
-- VIEWPORT TICK
-- ============================================================
local activeTab = 1
local vpsByTab = { [1]={}, [2]={}, [3]={}, [4]={} }
local tabs     = {}
local allCards = {}

local _strokeT   = 0   -- 0..1 position of the bright peak travelling the stroke
local WinStrokeGrad    -- forward-declared so RenderStepped closure can see it
local BLACK_C = Color3.fromRGB(0,   0,   0)
local WHITE_C = Color3.fromRGB(255, 255, 255)
local DIM_C   = Color3.fromRGB(55,  55,  55)

local function buildStrokeSeq(t)
    local W = 0.18   -- half-width of the glow
    -- Raw keypoint positions (may wrap past 1, handled below)
    local raw = {
        {0,       BLACK_C},
        {t - W,   BLACK_C},
        {t - W/2, DIM_C},
        {t,       WHITE_C},
        {t + W/2, DIM_C},
        {t + W,   BLACK_C},
        {1,       BLACK_C},
    }
    -- Wrap all positions into 0..1 and sort
    for _, v in ipairs(raw) do v[1] = v[1] % 1 end
    table.sort(raw, function(a,b) return a[1] < b[1] end)
    -- Deduplicate positions that are too close
    local kps = {}
    local prev = -1
    for _, v in ipairs(raw) do
        local p = math.clamp(v[1], 0, 1)
        if p - prev > 0.002 then
            table.insert(kps, ColorSequenceKeypoint.new(p, v[2]))
            prev = p
        end
    end
    if kps[1].Time > 0 then
        table.insert(kps, 1, ColorSequenceKeypoint.new(0, BLACK_C))
    end
    if kps[#kps].Time < 1 then
        table.insert(kps, ColorSequenceKeypoint.new(1, BLACK_C))
    end
    return ColorSequence.new(kps)
end

RunService.RenderStepped:Connect(function(dt)
    -- Rotate + slide the gradient around the stroke: full loop every ~2.5 s
    _strokeT = (_strokeT + dt * 0.4) % 1
    if WinStrokeGrad and WinStrokeGrad.Parent then
        local angle = _strokeT * math.pi * 2
        WinStrokeGrad.Rotation = _strokeT * 360
        WinStrokeGrad.Offset   = Vector2.new(math.cos(angle) * 0.5, math.sin(angle) * 0.5)
    end
    -- Viewport cameras
    local list = vpsByTab[activeTab]
    if not list then return end
    for _, vp in ipairs(list) do
        if vp.cam and vp.cam.Parent then
            vp.angle = vp.angle + dt * 0.75
            vp.cam.CFrame = CFrame.new(
                Vector3.new(
                    vp.centerPos.X + math.sin(vp.angle) * vp.radius,
                    vp.centerPos.Y + vp.size.Y * 0.1,
                    vp.centerPos.Z + math.cos(vp.angle) * vp.radius
                ),
                vp.centerPos
            )
        end
    end
end)

-- ============================================================
-- SCREEN + WINDOW
-- ============================================================
local Screen = Instance.new("ScreenGui")
Screen.Name           = "FinderUI"
Screen.ResetOnSpawn   = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.IgnoreGuiInset = true
Screen.Parent         = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- ANIMATED GRADIENT STROKE
-- UIStroke supports a UIGradient child — this respects the
-- UICorner radius so the stroke follows the rounded corners
-- perfectly.  We rotate the gradient every RenderStepped frame.
-- ============================================================

-- Dummy frame used only for drag position tracking (kept transparent)
local BorderFrame = Instance.new("Frame")
BorderFrame.Name                   = "GradBorder"
BorderFrame.Size                   = UDim2.new(0, WIN_W, 0, WIN_H)
BorderFrame.Position               = isMobile
    and UDim2.new(0.5, -WIN_W/2, 0.06, 4)
    or  UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
BorderFrame.BackgroundTransparency = 1
BorderFrame.BorderSizePixel        = 0
BorderFrame.ZIndex                 = 1
BorderFrame.Parent                 = Screen



local Win = Instance.new("Frame")
Win.Name             = "Win"
Win.Size             = UDim2.new(0, WIN_W, 0, WIN_H)
Win.Position         = isMobile
    and UDim2.new(0.5, -WIN_W/2, 0.06, 4)
    or  UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
Win.BackgroundColor3 = T.BG
Win.BackgroundTransparency = 0.2
Win.BorderSizePixel  = 0
Win.ZIndex           = 2
Win.Parent           = Screen
Corner(Win, 12)

-- Animated gradient stroke on the window — UIGradient parented to
-- UIStroke follows the UICorner radius, so corners are perfectly round.
local WinStroke = Instance.new("UIStroke")
WinStroke.Thickness         = 2
WinStroke.ApplyStrokeMode   = Enum.ApplyStrokeMode.Border
WinStroke.LineJoinMode      = Enum.LineJoinMode.Round
WinStroke.Color             = Color3.fromRGB(255, 255, 255)  -- base; overridden by gradient
WinStroke.Parent            = Win

WinStrokeGrad = Instance.new("UIGradient")
WinStrokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(0,   0,   0)),
    ColorSequenceKeypoint.new(0.3,  Color3.fromRGB(60,  60,  60)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.7,  Color3.fromRGB(60,  60,  60)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(0,   0,   0)),
})
WinStrokeGrad.Rotation = 0
WinStrokeGrad.Parent   = WinStroke

-- ============================================================
-- HEADER
-- ============================================================
local HDR_H = isMobile and 36 or 40
local Hdr = Instance.new("Frame")
Hdr.Size             = UDim2.new(1, 0, 0, HDR_H)
Hdr.BackgroundColor3 = T.Header
Hdr.BackgroundTransparency = 0.2
Hdr.BorderSizePixel  = 0
Hdr.ZIndex           = 5
Hdr.Active           = true
Hdr.Parent           = Win
Corner(Hdr, 12)

local HdrFill = Instance.new("Frame")
HdrFill.Size             = UDim2.new(1, 0, 0, 8)
HdrFill.Position         = UDim2.new(0, 0, 1, -8)
HdrFill.BackgroundColor3 = T.Header
HdrFill.BackgroundTransparency = 0.2
HdrFill.BorderSizePixel  = 0
HdrFill.ZIndex           = 5
HdrFill.Parent           = Hdr

local HdrLine = Instance.new("Frame")
HdrLine.Size             = UDim2.new(1, 0, 0, 1)
HdrLine.Position         = UDim2.new(0, 0, 1, -1)
HdrLine.BackgroundColor3 = T.Border
HdrLine.BorderSizePixel  = 0
HdrLine.ZIndex           = 6
HdrLine.Parent           = Hdr

local Dot = Instance.new("Frame")
Dot.Size             = UDim2.new(0, 7, 0, 7)
Dot.Position         = UDim2.new(0, 14, 0.5, -3)
Dot.BackgroundColor3 = T.White
Dot.BorderSizePixel  = 0
Dot.ZIndex           = 6
Dot.Parent           = Hdr
Corner(Dot, 4)

local TitleLbl = Label(Hdr, "Faded Finder", isMobile and 12 or 14, T.White, Enum.Font.GothamBold)
TitleLbl.Size     = UDim2.new(0, 160, 0, 18)
TitleLbl.Position = UDim2.new(0, 28, 0.5, -10)
TitleLbl.ZIndex   = 6

local VerLbl = Label(Hdr, "DIVISION 3", 10, T.Dim, Enum.Font.Gotham)
VerLbl.Size     = UDim2.new(0, 50, 0, 12)
VerLbl.Position = UDim2.new(0, 28, 0.5, 6)
VerLbl.ZIndex   = 6

-- Close (red) button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size              = UDim2.new(0, 22, 0, 22)
CloseBtn.Position          = UDim2.new(1, -30, 0.5, -11)
CloseBtn.BackgroundColor3  = Color3.fromRGB(160, 40, 40)
CloseBtn.BorderSizePixel   = 0
CloseBtn.Text              = "X"
CloseBtn.TextSize          = 10
CloseBtn.Font              = Enum.Font.GothamBold
CloseBtn.TextColor3        = T.White
CloseBtn.AutoButtonColor   = false
CloseBtn.ZIndex            = 7
CloseBtn.Parent            = Hdr
Corner(CloseBtn, 6)
Stroke(CloseBtn, Color3.fromRGB(200, 60, 60), 1)
CloseBtn.MouseButton1Click:Connect(function() Screen:Destroy() end)

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size              = UDim2.new(0, 22, 0, 22)
MinBtn.Position          = UDim2.new(1, -58, 0.5, -11)
MinBtn.BackgroundColor3  = T.Card
MinBtn.BorderSizePixel   = 0
MinBtn.Text              = "_"
MinBtn.TextSize          = 12
MinBtn.Font              = Enum.Font.GothamBold
MinBtn.TextColor3        = T.White
MinBtn.AutoButtonColor   = false
MinBtn.ZIndex            = 7
MinBtn.Parent            = Hdr
Corner(MinBtn, 6)
Stroke(MinBtn, T.Border, 1)

-- Drag
do
    local dragging, dragStart, winStart, borderStart
    Hdr.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            winStart = Win.Position
            borderStart = BorderFrame.Position
        end
    end)
    Hdr.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dragStart
            Win.Position = UDim2.new(
                winStart.X.Scale, winStart.X.Offset + d.X,
                winStart.Y.Scale, winStart.Y.Offset + d.Y
            )
            BorderFrame.Position = UDim2.new(
                borderStart.X.Scale, borderStart.X.Offset + d.X,
                borderStart.Y.Scale, borderStart.Y.Offset + d.Y
            )
        end
    end)
end

-- ============================================================
-- TAB BAR
-- ============================================================
local TBAR_H = isMobile and 30 or 34
local TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1, 0, 0, TBAR_H)
TabBar.Position         = UDim2.new(0, 0, 0, HDR_H)
TabBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
TabBar.BackgroundTransparency = 0.2
TabBar.BorderSizePixel  = 0
TabBar.ZIndex           = 4
TabBar.Parent           = Win

local TBLine = Instance.new("Frame")
TBLine.Size             = UDim2.new(1, 0, 0, 1)
TBLine.Position         = UDim2.new(0, 0, 0, HDR_H + TBAR_H - 1)
TBLine.BackgroundColor3 = T.Border
TBLine.BorderSizePixel  = 0
TBLine.ZIndex           = 5
TBLine.Parent           = Win

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection       = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
TabLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
TabLayout.Padding             = UDim.new(0, 0)
TabLayout.Parent              = TabBar

-- ============================================================
-- CONTENT AREA
-- ============================================================
local ContentArea = Instance.new("Frame")
ContentArea.Size                = UDim2.new(1, 0, 1, -(HDR_H + TBAR_H))
ContentArea.Position            = UDim2.new(0, 0, 0, HDR_H + TBAR_H)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants    = true
ContentArea.ZIndex              = 2
ContentArea.Parent              = Win

local function MakeScroll(parent)
    local s = Instance.new("ScrollingFrame")
    s.Size                  = UDim2.new(1, 0, 1, 0)
    s.BackgroundTransparency = 1
    s.BorderSizePixel       = 0
    s.ScrollBarThickness    = 3
    s.ScrollBarImageColor3  = Color3.fromRGB(75, 75, 75)
    s.CanvasSize            = UDim2.new(0, 0, 0, 0)
    s.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    s.ScrollingDirection    = Enum.ScrollingDirection.Y
    s.ZIndex                = 2
    s.Parent                = parent
    local layout = Instance.new("UIListLayout")
    layout.FillDirection       = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding             = UDim.new(0, 6)
    layout.Parent              = s
    Padding(s, 10, 10, 8, 8)
    return s
end

-- ============================================================
-- MINIMIZE
-- ============================================================
local MINI_T = TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local minimized = false
local _minibusy = false

MinBtn.MouseButton1Click:Connect(function()
    if _minibusy then return end
    _minibusy = true
    minimized = not minimized

    if minimized then
        -- Snap content hidden so it doesn't peek during shrink
        ContentArea.Visible = false
        TabBar.Visible      = false
        TBLine.Visible      = false
        -- Hide the flat-bottom header filler so the window's own
        -- rounded corners are fully visible when minimized
        HdrFill.Visible     = false
        -- Smooth shrink to header-only height
        local tw = TS:Create(Win, MINI_T, {Size = UDim2.new(0, WIN_W, 0, HDR_H)})
        TS:Create(BorderFrame, MINI_T, {Size = UDim2.new(0, WIN_W, 0, HDR_H)}):Play()
        tw:Play()
        tw.Completed:Connect(function() _minibusy = false end)
        MinBtn.Text = "+"
    else
        -- Smooth expand back to full height
        local tw = TS:Create(Win, MINI_T, {Size = UDim2.new(0, WIN_W, 0, WIN_H)})
        TS:Create(BorderFrame, MINI_T, {Size = UDim2.new(0, WIN_W, 0, WIN_H)}):Play()
        tw:Play()
        tw.Completed:Connect(function()
            -- Restore filler and content only after fully expanded
            HdrFill.Visible     = true
            TabBar.Visible      = true
            TBLine.Visible      = true
            ContentArea.Visible = true
            _minibusy = false
        end)
        MinBtn.Text = "_"
    end
end)

-- ============================================================
-- TABS (4: Live / History / Online / Settings)
-- ============================================================
local Tabs = {}
local ActiveTab = nil
local TabSwiping = false

local function TabIndex(tab)
    for i, t in ipairs(Tabs) do if t == tab then return i end end
    return 0
end

local SLIDE_IN  = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local SLIDE_OUT = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function ActivateTab(tab)
    if ActiveTab == tab then return end
    if TabSwiping then return end
    local oldTab = ActiveTab
    ActiveTab = tab
    activeTab = TabIndex(tab)
    if oldTab then
        Tween(oldTab.lbl,       F, {TextColor3 = T.TabInact})
        Tween(oldTab.indicator, M, {Size = UDim2.new(0, 0, 0, 2)})
    end
    Tween(tab.lbl,       F, {TextColor3 = T.TabActive})
    Tween(tab.indicator, M, {Size = UDim2.new(0.8, 0, 0, 2)})
    if oldTab then
        TabSwiping = true
        local oldIdx, newIdx = TabIndex(oldTab), TabIndex(tab)
        local dir = (newIdx > oldIdx) and 1 or -1
        tab.page.Position = UDim2.new(0, dir * ContentArea.AbsoluteSize.X, 0, 0)
        tab.page.Visible = true
        Tween(oldTab.page, SLIDE_OUT, {Position = UDim2.new(0, -dir * ContentArea.AbsoluteSize.X, 0, 0)})
        local tw = TS:Create(tab.page, SLIDE_IN, {Position = UDim2.new(0, 0, 0, 0)})
        tw:Play()
        tw.Completed:Connect(function()
            oldTab.page.Visible = false
            oldTab.page.Position = UDim2.new(0, 0, 0, 0)
            TabSwiping = false
        end)
    else
        tab.page.Position = UDim2.new(0, 0, 0, 0)
        tab.page.Visible = true
    end
end

local function CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Size                = UDim2.new(0.333, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text                = ""
    btn.ZIndex              = 5
    btn.Parent              = TabBar
    local nameLbl = Label(btn, name, isMobile and 9 or 11, T.TabInact, Enum.Font.GothamMedium)
    nameLbl.Size           = UDim2.new(1, -2, 1, 0)
    nameLbl.Position       = UDim2.new(0, 1, 0, 0)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.ZIndex         = 6
    local indicator = Instance.new("Frame")
    indicator.Size             = UDim2.new(0, 0, 0, 2)
    indicator.Position         = UDim2.new(0.1, 0, 1, -2)
    indicator.BackgroundColor3 = T.White
    indicator.BorderSizePixel  = 0
    indicator.ZIndex           = 7
    indicator.Parent           = btn
    Corner(indicator, 1)
    local page = Instance.new("Frame")
    page.Size                = UDim2.new(1, 0, 1, 0)
    page.Position            = UDim2.new(0, 0, 0, 0)
    page.BackgroundTransparency = 1
    page.Visible             = false
    page.ClipsDescendants    = true
    page.ZIndex              = 2
    page.Parent              = ContentArea
    local scroll = MakeScroll(page)
    local tab = { btn = btn, lbl = nameLbl, indicator = indicator, page = page, scroll = scroll }
    btn.MouseButton1Click:Connect(function() ActivateTab(tab) end)
    table.insert(Tabs, tab)
    return tab
end

local LiveTab     = CreateTab("LIVE")
local OnlineTab   = CreateTab("ONLINE")
local SettingsTab = CreateTab("SETTINGS")

-- History tab removed; keep a stub so existing references don't crash
local HistoryTab  = { scroll = Instance.new("Frame") }

tabs[1] = LiveTab.scroll
tabs[2] = OnlineTab.scroll
tabs[3] = SettingsTab.scroll

vpsByTab[2] = OnlineTab.scroll
vpsByTab[3] = SettingsTab.scroll

ActivateTab(LiveTab)

-- ============================================================
-- SECTION HEADER
-- ============================================================
local function CreateSection(parent, title)
    local f = Instance.new("Frame")
    f.Size                = UDim2.new(1, -16, 0, 26)
    f.BackgroundTransparency = 1
    f.Parent              = parent
    local line = Instance.new("Frame")
    line.Size             = UDim2.new(1, 0, 0, 1)
    line.Position         = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = T.Border
    line.BorderSizePixel  = 0
    line.Parent           = f
    local pill = Instance.new("Frame")
    pill.Size             = UDim2.new(0, #title * 7 + 18, 0, 18)
    pill.Position         = UDim2.new(0, 10, 0.5, -9)
    pill.BackgroundColor3 = T.BG
    pill.BackgroundTransparency = 0.2
    pill.BorderSizePixel  = 0
    pill.ZIndex           = 2
    pill.Parent           = f
    Corner(pill, 6)
    local lbl = Label(pill, title, 10, T.Dim, Enum.Font.GothamBold)
    lbl.Size           = UDim2.new(1, 0, 1, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.ZIndex         = 3
    return f
end

-- ============================================================
-- TOAST SYSTEM (Faded style)
-- ============================================================
local _activeNotifs = {}
local NOTIF_W      = isMobile and 180 or 220
local NOTIF_H      = isMobile and 40 or 44
local NOTIF_GAP    = 6
local NOTIF_PAD_X  = 14
local NOTIF_PAD_Y  = 14
local NOTIF_DUR    = 2.6

local function _shadowTargetY(slotIdx)
    return -(NOTIF_PAD_Y + NOTIF_H + 4 + slotIdx * (NOTIF_H + NOTIF_GAP))
end
local function _repoAll(tweenInfo)
    for i, e in ipairs(_activeNotifs) do
        TS:Create(e.shadow, tweenInfo, {
            Position = UDim2.new(0, NOTIF_PAD_X - 4, 1, _shadowTargetY(i - 1))
        }):Play()
    end
end

local function pushToast(title, statusTxt, statusCol)
    statusCol = statusCol or T.Dim
    local IN_INFO   = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local OUT_INFO  = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    local BAR_INFO  = TweenInfo.new(NOTIF_DUR, Enum.EasingStyle.Linear)
    local FADE_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Linear)
    local REPO_INFO = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local shadow = Instance.new("Frame")
    shadow.Name                   = "ToastShadow"
    shadow.Size                   = UDim2.new(0, NOTIF_W + 8, 0, NOTIF_H + 8)
    shadow.Position               = UDim2.new(0, -(NOTIF_W + 32), 1, _shadowTargetY(0))
    shadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.12
    shadow.BorderSizePixel        = 0
    shadow.ZIndex                 = 199
    shadow.Parent                 = Screen
    Corner(shadow, 12)
    local toast = Instance.new("Frame")
    toast.Size                   = UDim2.new(0, NOTIF_W, 0, NOTIF_H)
    toast.Position               = UDim2.new(0, 4, 0, 4)
    toast.BackgroundColor3       = Color3.fromRGB(18, 18, 18)
    toast.BackgroundTransparency = 1
    toast.BorderSizePixel        = 0
    toast.ZIndex                 = 200
    toast.Parent                 = shadow
    Corner(toast, 10)
    local _stroke = Stroke(toast, Color3.fromRGB(55, 55, 55), 1, 1)
    local pill = Instance.new("Frame")
    pill.Size                   = UDim2.new(0, 3, 0, NOTIF_H - 16)
    pill.Position               = UDim2.new(0, 9, 0.5, -(NOTIF_H - 16) / 2)
    pill.BackgroundColor3       = T.White
    pill.BackgroundTransparency = 0.3
    pill.BorderSizePixel        = 0
    pill.ZIndex                 = 201
    pill.Parent                 = toast
    Corner(pill, 4)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size               = UDim2.new(1, -24, 0, 15)
    nameLabel.Position           = UDim2.new(0, 19, 0, 7)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text               = title
    nameLabel.TextSize           = isMobile and 10 or 11
    nameLabel.Font               = Enum.Font.GothamBold
    nameLabel.TextColor3         = T.White
    nameLabel.TextXAlignment     = Enum.TextXAlignment.Left
    nameLabel.TextTruncate       = Enum.TextTruncate.AtEnd
    nameLabel.TextTransparency   = 1
    nameLabel.ZIndex             = 201
    nameLabel.Parent             = toast
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size               = UDim2.new(1, -24, 0, 11)
    statusLabel.Position           = UDim2.new(0, 19, 0, 23)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text               = statusTxt or ""
    statusLabel.TextSize           = isMobile and 9 or 10
    statusLabel.Font               = Enum.Font.Gotham
    statusLabel.TextColor3         = statusCol
    statusLabel.TextXAlignment     = Enum.TextXAlignment.Left
    statusLabel.TextTruncate       = Enum.TextTruncate.AtEnd
    statusLabel.TextTransparency   = 1
    statusLabel.ZIndex             = 201
    statusLabel.Parent             = toast
    local barTrack = Instance.new("Frame")
    barTrack.Size             = UDim2.new(1, 0, 0, 2)
    barTrack.Position         = UDim2.new(0, 0, 1, -2)
    barTrack.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    barTrack.BorderSizePixel  = 0
    barTrack.ZIndex           = 201
    barTrack.Parent           = toast
    Corner(barTrack, 1)
    local barFill = Instance.new("Frame")
    barFill.Size             = UDim2.new(1, 0, 1, 0)
    barFill.BackgroundColor3 = T.White
    barFill.BorderSizePixel  = 0
    barFill.ZIndex           = 202
    barFill.Parent           = barTrack
    Corner(barFill, 1)
    local entry = { shadow = shadow }
    table.insert(_activeNotifs, 1, entry)
    _repoAll(REPO_INFO)
    TS:Create(shadow, IN_INFO, { Position = UDim2.new(0, NOTIF_PAD_X - 4, 1, _shadowTargetY(0)) }):Play()
    TS:Create(toast,       IN_INFO, {BackgroundTransparency = 0}):Play()
    TS:Create(_stroke,     IN_INFO, {Transparency = 0.3}):Play()
    TS:Create(nameLabel,   IN_INFO, {TextTransparency = 0}):Play()
    TS:Create(statusLabel, IN_INFO, {TextTransparency = 0}):Play()
    task.delay(0.1, function()
        TS:Create(barFill, BAR_INFO, {Size = UDim2.new(0, 0, 1, 0)}):Play()
    end)
    task.delay(NOTIF_DUR + 0.15, function()
        for i, e in ipairs(_activeNotifs) do
            if e == entry then table.remove(_activeNotifs, i); break end
        end
        _repoAll(REPO_INFO)
        local exitY = shadow.Position.Y.Offset
        TS:Create(shadow, OUT_INFO, { Position = UDim2.new(0, -(NOTIF_W + 32), 1, exitY) }):Play()
        TS:Create(toast,       FADE_INFO, {BackgroundTransparency = 1}):Play()
        TS:Create(nameLabel,   FADE_INFO, {TextTransparency = 1}):Play()
        local tw = TS:Create(statusLabel, FADE_INFO, {TextTransparency = 1})
        tw:Play()
        tw.Completed:Connect(function() if shadow and shadow.Parent then shadow:Destroy() end end)
    end)
end

showOnlineToast = function(username)
    if not cfg.notifications then return end
    if not (username and username ~= "") then return end
    pushToast(username, "Came online", T.Good)
end

showOfflineToast = function(username)
    if not cfg.notifications then return end
    if not (username and username ~= "") then return end
    pushToast(username, "Went offline", T.Bad)
end

showSpawnToast = function(modelName, mutation)
    if not cfg.notifications then return end
    local sub = (mutation and mutation ~= "Base") and (modelName .. " - " .. mutation) or modelName
    pushToast("Spawned", sub, T.Warn)
end

-- ============================================================
-- SEARCH (top of LIVE tab) - compact horizontal layout
-- ============================================================
local PAD = 8
local SEARCH_ROW_H = isMobile and 28 or 32
-- Compact profile row: avatar + name/id + stacked buttons, all in one row
local PROF_AV     = isMobile and 40 or 48   -- avatar size
local PROF_ROW_H  = PROF_AV + PAD           -- collapsed when hidden
local CARD_H_COLLAPSED = SEARCH_ROW_H + PAD * 2
local CARD_H_EXPANDED  = CARD_H_COLLAPSED + PROF_ROW_H + PAD

local searchCard = Instance.new("Frame")
searchCard.Name             = "SearchCard"
searchCard.Size             = UDim2.new(1, -16, 0, CARD_H_COLLAPSED)
searchCard.BackgroundColor3 = T.Card
searchCard.BackgroundTransparency = 0.15
searchCard.BorderSizePixel  = 0
searchCard.LayoutOrder      = -1000000
searchCard.ClipsDescendants = true
searchCard.Parent           = LiveTab.scroll
Corner(searchCard, 12)
local searchCardStroke = Stroke(searchCard, T.Border, 1)

local searchRow = Instance.new("Frame")
searchRow.Size                   = UDim2.new(1, -PAD * 2, 0, SEARCH_ROW_H)
searchRow.Position               = UDim2.new(0, PAD, 0, PAD)
searchRow.BackgroundTransparency = 1
searchRow.ZIndex                 = 2
searchRow.Parent                 = searchCard

local SEARCH_BTN_W = isMobile and 56 or 68
local SearchInput = Instance.new("TextBox")
SearchInput.Size                   = UDim2.new(1, -(SEARCH_BTN_W + 8), 1, 0)
SearchInput.Position               = UDim2.new(0, 0, 0, 0)
SearchInput.BackgroundColor3       = T.SubField
SearchInput.BorderSizePixel        = 0
SearchInput.PlaceholderText        = "Search by username..."
SearchInput.Text                   = ""
SearchInput.TextSize               = isMobile and 11 or 13
SearchInput.Font                   = Enum.Font.Gotham
SearchInput.TextColor3             = T.White
SearchInput.PlaceholderColor3      = T.Dim
SearchInput.TextXAlignment         = Enum.TextXAlignment.Left
SearchInput.ClearTextOnFocus       = false
SearchInput.ZIndex                 = 3
SearchInput.Parent                 = searchRow
Corner(SearchInput, 8)
local SearchInputStroke = Stroke(SearchInput, T.Border, 1)
Padding(SearchInput, 0, 0, 12, 12)
SearchInput.Focused:Connect(function()
    Tween(SearchInputStroke, F, { Color = T.White })
end)
SearchInput.FocusLost:Connect(function()
    Tween(SearchInputStroke, F, { Color = T.Border })
end)

local SearchBtn = Instance.new("TextButton")
SearchBtn.Size             = UDim2.new(0, SEARCH_BTN_W, 1, 0)
SearchBtn.Position         = UDim2.new(1, -SEARCH_BTN_W, 0, 0)
SearchBtn.BackgroundColor3 = T.AccentBg
SearchBtn.BorderSizePixel  = 0
SearchBtn.Text             = "Find"
SearchBtn.TextSize         = isMobile and 11 or 13
SearchBtn.Font             = Enum.Font.GothamBold
SearchBtn.TextColor3       = T.AccentFg
SearchBtn.AutoButtonColor  = false
SearchBtn.ZIndex           = 3
SearchBtn.Parent           = searchRow
Corner(SearchBtn, 8)
SearchBtn.MouseEnter:Connect(function() Tween(SearchBtn, F, { BackgroundColor3 = Color3.fromRGB(220,220,220) }) end)
SearchBtn.MouseLeave:Connect(function() Tween(SearchBtn, F, { BackgroundColor3 = T.AccentBg }) end)

-- Profile panel (inside searchCard) - compact horizontal layout
local AV_SIZE = PROF_AV
local BTN_W   = isMobile and 70 or 82
local BTN_H   = isMobile and 22 or 25

local profile = Instance.new("Frame")
profile.Size                   = UDim2.new(1, -PAD * 2, 0, PROF_ROW_H)
profile.Position               = UDim2.new(0, PAD, 0, PAD * 2 + SEARCH_ROW_H)
profile.BackgroundColor3       = T.SubCard
profile.BackgroundTransparency = 0.1
profile.BorderSizePixel        = 0
profile.Visible                = false
profile.ZIndex                 = 2
profile.Parent                 = searchCard
Corner(profile, 10)
Stroke(profile, T.Border, 1)

-- Avatar on the LEFT
local avFrame = Instance.new("Frame")
avFrame.Position              = UDim2.new(0, PAD, 0.5, -AV_SIZE/2)
avFrame.Size                  = UDim2.new(0, AV_SIZE, 0, AV_SIZE)
avFrame.BackgroundColor3      = Color3.fromRGB(24, 24, 28)
avFrame.BorderSizePixel       = 0
avFrame.ClipsDescendants      = true
avFrame.ZIndex                = 3
avFrame.Parent                = profile
Instance.new("UICorner", avFrame).CornerRadius = UDim.new(1, 0)
local avRing = Instance.new("UIStroke", avFrame)
avRing.Color     = T.White
avRing.Thickness = 1
avRing.Transparency = 0.6

local avImg = Instance.new("ImageLabel")
avImg.Size                   = UDim2.new(1, 0, 1, 0)
avImg.BackgroundTransparency = 1
avImg.Image                  = ""
avImg.ZIndex                 = 4
avImg.Parent                 = avFrame

local SDOT = 8
local searchDot = Instance.new("Frame")
searchDot.Size = UDim2.new(0, SDOT, 0, SDOT)
searchDot.Position = UDim2.new(1, -1, 1, -1)
searchDot.AnchorPoint = Vector2.new(1, 1)
searchDot.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
searchDot.BorderSizePixel = 0
searchDot.ZIndex = 5
searchDot.Parent = avFrame
Instance.new("UICorner", searchDot).CornerRadius = UDim.new(1, 0)
local sdotRing = Instance.new("UIStroke", searchDot)
sdotRing.Color = T.SubCard
sdotRing.Thickness = 2
sdotRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Name label (centre, next to avatar)
local TEXT_X = PAD + AV_SIZE + PAD
local BTN_RIGHT_W = BTN_W + PAD
local TEXT_W = -(TEXT_X + BTN_RIGHT_W + PAD)

local nameLbl = Instance.new("TextLabel")
nameLbl.Position              = UDim2.new(0, TEXT_X, 0, PAD - 2)
nameLbl.Size                  = UDim2.new(1, TEXT_W, 0, isMobile and 14 or 16)
nameLbl.BackgroundTransparency = 1
nameLbl.Text                  = ""
nameLbl.TextSize              = isMobile and 12 or 14
nameLbl.Font                  = Enum.Font.GothamBold
nameLbl.TextColor3            = T.White
nameLbl.TextXAlignment        = Enum.TextXAlignment.Left
nameLbl.TextTruncate          = Enum.TextTruncate.AtEnd
nameLbl.ZIndex                = 3
nameLbl.Parent                = profile

-- ID label below name (shows the actual numeric user ID)
local idLbl = Instance.new("TextLabel")
idLbl.Position              = UDim2.new(0, TEXT_X, 0, (isMobile and 18 or 22))
idLbl.Size                  = UDim2.new(1, TEXT_W, 0, isMobile and 11 or 13)
idLbl.BackgroundTransparency = 1
idLbl.Text                  = ""
idLbl.TextSize              = isMobile and 9 or 10
idLbl.Font                  = Enum.Font.Gotham
idLbl.TextColor3            = T.Dim
idLbl.TextXAlignment        = Enum.TextXAlignment.Left
idLbl.TextTruncate          = Enum.TextTruncate.AtEnd
idLbl.ZIndex                = 3
idLbl.Parent                = profile

-- Stacked Copy / Trade buttons on the RIGHT
local function mkProfileBtn(text, bg, fg, yOff, hoverBg)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0, BTN_W, 0, BTN_H)
    b.Position         = UDim2.new(1, -(BTN_W + PAD), 0, yOff)
    b.BackgroundColor3 = bg
    b.BorderSizePixel  = 0
    b.Text             = text
    b.TextSize         = isMobile and 10 or 11
    b.Font             = Enum.Font.GothamBold
    b.TextColor3       = fg
    b.AutoButtonColor  = false
    b.ZIndex           = 4
    b.Parent           = profile
    Corner(b, 7)
    Stroke(b, Color3.fromRGB(70, 70, 76), 1)
    b.MouseEnter:Connect(function() Tween(b, F, { BackgroundColor3 = hoverBg or T.CardHover }) end)
    b.MouseLeave:Connect(function() Tween(b, F, { BackgroundColor3 = bg }) end)
    return b
end
-- Vertically centre the two stacked buttons
local totalBtnH = BTN_H * 2 + 4
local btnStartY = math.floor((PROF_ROW_H - totalBtnH) / 2)
local profCopyBtn  = mkProfileBtn("Copy",  Color3.fromRGB(30,30,34), T.White,    btnStartY,           Color3.fromRGB(46,46,52))
local profTradeBtn = mkProfileBtn("Trade", T.AccentBg,                T.AccentFg, btnStartY + BTN_H + 4, Color3.fromRGB(220,220,220))

local statusLbl = Instance.new("TextLabel")
statusLbl.Position              = UDim2.new(0, TEXT_X, 0, (isMobile and 31 or 38))
statusLbl.Size                  = UDim2.new(1, TEXT_W, 0, isMobile and 10 or 12)
statusLbl.BackgroundTransparency = 1
statusLbl.Text                  = ""
statusLbl.TextSize              = isMobile and 9 or 10
statusLbl.Font                  = Enum.Font.GothamMedium
statusLbl.TextColor3            = T.Dim
statusLbl.TextXAlignment        = Enum.TextXAlignment.Left
statusLbl.ZIndex                = 3
statusLbl.Parent                = profile

local currentUserId   = nil
local currentUserName = nil
local CARD_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function setStatus(text, color)
    statusLbl.Text       = text or ""
    statusLbl.TextColor3 = color or T.Dim
end
local function showProfile(visible)
    if visible == profile.Visible then return end
    profile.Visible = visible
    local target = visible and CARD_H_EXPANDED or CARD_H_COLLAPSED
    TS:Create(searchCard, CARD_TWEEN, { Size = UDim2.new(1, -16, 0, target) }):Play()
end
local function setUser(userId, displayName, username)
    currentUserId   = userId
    currentUserName = username or displayName
    nameLbl.Text  = displayName or username or "Unknown"
    idLbl.Text    = "@" .. (username or "?") .. "  |  ID: " .. tostring(userId)
    avImg.Image   = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=150&h=150"
    showProfile(true)
    startPresencePolling(searchDot, userId, nil, nil)
end
local function clearUser()
    currentUserId, currentUserName = nil, nil
    nameLbl.Text = ""
    idLbl.Text   = ""
    avImg.Image  = ""
    showProfile(false)
end

local _isSearching = false
local function doSearch()
    if _isSearching then return end
    local q = (SearchInput.Text or ""):gsub("^%s+",""):gsub("%s+$","")
    if q == "" then
        clearUser()
        setStatus("Enter a username", T.Warn)
        return
    end
    _isSearching = true
    SearchBtn.Text = "..."
    setStatus("Looking up @" .. q, T.Dim)
    task.spawn(function()
        local uid = getUserIdFromUsername(q)
        if not uid then
            clearUser()
            setStatus("Not found: @" .. q, T.Bad)
            SearchBtn.Text = "Find"
            _isSearching = false
            return
        end
        local dispName, uname = q, q
        pcall(function()
            local info = Players:GetUserInfosByUserIdsAsync({uid})
            if info and info[1] then
                if info[1].DisplayName then dispName = info[1].DisplayName end
                if info[1].Username    then uname    = info[1].Username    end
            end
        end)
        setUser(uid, dispName, uname)
        setStatus("Profile loaded", T.Good)
        SearchBtn.Text = "Find"
        _isSearching = false
    end)
end

SearchBtn.MouseButton1Click:Connect(doSearch)
SearchInput.FocusLost:Connect(function(enter) if enter then doSearch() end end)
SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    if SearchInput.Text == "" then
        clearUser()
        setStatus("", T.Dim)
    end
end)

profCopyBtn.MouseButton1Click:Connect(function()
    if not currentUserId then return end
    profCopyBtn.Text = "..."
    task.spawn(function()
        local fresh = nil
        pcall(function() fresh = Players:GetNameFromUserIdAsync(currentUserId) end)
        local name = (fresh and fresh ~= "") and fresh or currentUserName
        pcall(function() setclipboard(name) end)
        if profCopyBtn and profCopyBtn.Parent then
            profCopyBtn.Text = "Done"
            task.delay(1.5, function() if profCopyBtn and profCopyBtn.Parent then profCopyBtn.Text = "Copy" end end)
        end
    end)
end)

profTradeBtn.MouseButton1Click:Connect(function()
    if not currentUserId then return end
    profTradeBtn.Text = "..."
    invokeTrade(currentUserId, function(success)
        if profTradeBtn and profTradeBtn.Parent then
            profTradeBtn.Text = success and "Sent" or "Failed"
            task.delay(2.5, function() if profTradeBtn and profTradeBtn.Parent then profTradeBtn.Text = "Trade" end end)
        end
    end)
end)

-- ============================================================
-- CARD HELPERS
-- ============================================================
local cardOrder   = 1000000
local seenEntries = {}
local CARD_H        = isMobile and 96 or 108
local LBTN_W = isMobile and 56 or 68
local LBTN_H = isMobile and 22 or 26

local INVALID = {[""]=true,["unclaimed"]=true,["unknown"]=true,["none"]=true,["..."]=true,["null"]=true}
local function isValidUsername(txt)
    if not txt then return false end
    local lower = txt:lower():gsub("%s+","")
    if INVALID[lower] then return false end
    if #txt < 3 then return false end
    if not txt:match("%w") then return false end
    return true
end

local function getUsernameFromId(userId)
    if not userId then return nil end
    local name = nil
    pcall(function() name = Players:GetNameFromUserIdAsync(userId) end)
    return name
end

local function extractUserId(playerBg)
    local headshot = playerBg:FindFirstChild("Headshot")
    if headshot and headshot:IsA("ImageLabel") then
        local id = headshot.Image:match("id=(%d+)")
        if id then return tonumber(id) end
    end
    return nil
end

local function getUsername(filler)
    local playerBg = filler:FindFirstChild("PlayerBg")
    if not playerBg then return nil, nil end
    local uLabel = playerBg:FindFirstChild("Username")
    local labelName = uLabel and uLabel.Visible and isValidUsername(uLabel.Text) and uLabel.Text or nil
    local userId = extractUserId(playerBg)
    local resolvedName = nil
    if userId then resolvedName = getUsernameFromId(userId) end
    local finalName = (isValidUsername(resolvedName) and resolvedName)
                   or (isValidUsername(labelName) and labelName) or nil
    return finalName, userId
end

local function getModelName(filler)
    local brainrotBg = filler:FindFirstChild("BrainrotBg")
    if brainrotBg then
        local vp = brainrotBg:FindFirstChild("BrainrotViewport")
        if vp then
            local wm = vp:FindFirstChild("WorldModel")
            if wm then
                for _, obj in ipairs(wm:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name ~= "" and obj.Name ~= "WorldModel" then return obj.Name end
                end
            end
        end
        local lbl = brainrotBg:FindFirstChildWhichIsA("TextLabel")
        if lbl and lbl.Text ~= "" then return lbl.Text end
    end
    local bar = filler:FindFirstChild("Bar")
    if bar then
        local lbl = bar:FindFirstChildWhichIsA("TextLabel")
        if lbl and lbl.Text ~= "" then return lbl.Text end
    end
    local t = filler:FindFirstChild("Title")
    if t and t.Text and t.Text ~= "" then return t.Text end
    return "Unknown"
end

local function getMutation(filler)
    local brainrotBg = filler:FindFirstChild("BrainrotBg")
    if brainrotBg then
        local vp = brainrotBg:FindFirstChild("BrainrotViewport")
        if vp then
            local wm = vp:FindFirstChild("WorldModel")
            if wm then
                for _, obj in ipairs(wm:GetDescendants()) do
                    local ok, attr = pcall(function() return obj:GetAttribute("__mutation") end)
                    if ok and attr then
                        local s = tostring(attr)
                        if s == "None" or s == "" then return "Base" end
                        return s
                    end
                end
            end
        end
    end
    return "Base"
end

-- ============================================================
-- VIEWPORT BUILDER
-- ============================================================
local function buildViewport(vpBox, modelName, mutationName, tabIdx)
    local animalsFolder = RS:FindFirstChild("Models") and RS.Models:FindFirstChild("Animals")
    local animalModel   = animalsFolder and animalsFolder:FindFirstChild(modelName)
    if not animalModel then
        local ph = Instance.new("TextLabel")
        ph.Size = UDim2.new(1, 0, 1, 0); ph.BackgroundTransparency = 1
        ph.Text = "?"; ph.Font = Enum.Font.GothamBold; ph.TextSize = 16
        ph.TextColor3 = T.Dim
        ph.TextXAlignment = Enum.TextXAlignment.Center
        ph.TextYAlignment = Enum.TextYAlignment.Center
        ph.ZIndex = 7; ph.Parent = vpBox
        return nil
    end
    local vp = Instance.new("ViewportFrame")
    vp.Size = UDim2.new(1, 0, 1, 0); vp.BackgroundTransparency = 1
    vp.LightDirection = Vector3.new(-1, -2, -1)
    vp.Ambient = Color3.fromRGB(200, 200, 200)
    vp.ZIndex = 7; vp.Parent = vpBox
    local wm = Instance.new("WorldModel"); wm.Parent = vp
    local cam = Instance.new("Camera")
    vp.CurrentCamera = cam; cam.Parent = vp
    task.spawn(function()
        local clone = animalModel:Clone()
        clone.Parent = wm
        if mutationName and mutationName ~= "Base" then
            local ok, Mutations = pcall(function()
                return require(RS:WaitForChild("Datas"):WaitForChild("Mutations", 3))
            end)
            if ok and Mutations and Mutations[mutationName] then
                pcall(function()
                    local Trove = require(RS:WaitForChild("Packages"):WaitForChild("Trove"))
                    local trove = Trove.new()
                    trove:Add(clone.Destroying:Connect(function() trove:Destroy() end))
                    local mutData = Mutations[mutationName]
                    local MutSurf = RS:FindFirstChild("MutationSurfaces")
                    local surfTmpl = MutSurf and MutSurf:FindFirstChild(modelName)
                    local palIdx = tonumber(clone:GetAttribute(mutationName .. "*Palette"))
                        or tonumber(clone:GetAttribute("Palette")) or 1
                    if mutData and mutData.Palettes and not mutData.Palettes[palIdx] then palIdx = 1 end
                    if mutationName == "Rainbow" then
                        clone:AddTag("RainbowModel")
                        trove:Add(function() clone:RemoveTag("RainbowModel") end)
                    end
                    if mutData and mutData.Palettes then
                        for _, part in clone:GetDescendants() do
                            if part:IsA("BasePart") then
                                local ig = part:GetAttribute(mutationName .. "*IgnoreColor")
                                if ig == false or not (part:GetAttribute("IgnoreColor") or ig) then
                                    local palette = mutData.Palettes[palIdx]
                                    local ci = tonumber(part:GetAttribute(mutationName .. "*Color") or part:GetAttribute("Color") or 1) or 1
                                    local tc = palette[ci] or palette[math.clamp(ci, 1, #palette)]
                                    local sa = part:FindFirstChildOfClass("SurfaceAppearance")
                                    if sa then
                                        sa:Destroy()
                                        if surfTmpl then
                                            local nsa = surfTmpl:Clone()
                                            nsa.Color = (mutationName == "Divine") and palette[1] or tc
                                            nsa.Parent = part
                                        end
                                    else
                                        local mv = part.MaterialVariant
                                        if mv == "Strawberry Stud Light" or mv == "Strawberry Stud Dark" then
                                            part.MaterialVariant = mutationName .. " Strawberry Stud Light"
                                        elseif tc then
                                            part.Color = tc
                                        end
                                    end
                                    if part:GetAttribute("Neon") then
                                        part.Material = Enum.Material.Neon
                                    end
                                end
                            end
                        end
                    end
                    local VfxF = RS:FindFirstChild("Vfx")
                    local vfxF = VfxF and VfxF:FindFirstChild(mutationName)
                    local vfxI = clone:FindFirstChild("VfxInstance")
                    if vfxF and vfxI then
                        for _, ch in vfxF:GetChildren() do ch:Clone().Parent = vfxI end
                    end
                    clone:SetAttribute("__mutation", mutationName)
                end)
            end
        end
        local cf, size = clone:GetBoundingBox()
        cam.FieldOfView = 60
        local radius = math.max(size.X, size.Y, size.Z) * 1.8 * 0.3
        local entry = {angle = 0, cam = cam, centerPos = cf.Position, radius = radius, size = size}
        table.insert(vpsByTab[tabIdx], entry)
    end)
end

local ALLOWED_MODELS = {["Strawberry Elephant"]=true, ["Meowl"]=true, ["Skibidi Toilet"]=true, ["John Pork"]=true}

-- ============================================================
-- ACTION BTN
-- ============================================================
local function makeActionBtn(parent, w, h, xOff, yOff, label, primary)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0, w, 0, h)
    b.Position         = UDim2.new(1, xOff, 0, yOff)
    b.BackgroundColor3 = primary and T.AccentBg or Color3.fromRGB(30, 30, 34)
    b.BorderSizePixel  = 0
    b.Text             = label
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = isMobile and 10 or 11
    b.TextColor3       = primary and T.AccentFg or T.White
    b.AutoButtonColor  = false
    b.ZIndex           = 7
    b.Parent           = parent
    Corner(b, 8)
    Stroke(b, Color3.fromRGB(70, 70, 76), 1)
    local baseBg = b.BackgroundColor3
    local hoverBg = primary and Color3.fromRGB(220,220,220) or Color3.fromRGB(46,46,52)
    b.MouseEnter:Connect(function() Tween(b, F, { BackgroundColor3 = hoverBg }) end)
    b.MouseLeave:Connect(function() Tween(b, F, { BackgroundColor3 = baseBg }) end)
    return b
end

-- ============================================================
-- HISTORY + ONLINE STATE
-- ============================================================
local historyEntries = {}
local onlineEntries  = {}
local onlineByEntry  = {}
local historyLog     = {}
local onlineLog      = {}
local _skipHistSave  = false
local _skipOnlSave   = false

local function saveHistory()
    if _skipHistSave then return end
    pcall(function() writefile(HISTORY_PATH, HttpService:JSONEncode(historyLog)) end)
end
local function saveOnlineLog()
    if _skipOnlSave then return end
    local list = {}
    for _, v in pairs(onlineLog) do table.insert(list, v) end
    pcall(function() writefile(ONLINE_PATH, HttpService:JSONEncode(list)) end)
end

-- HISTORY ROW - stubbed out (History tab removed)
addToHistory = function(displayName, username, model, mutation, userId)
    -- History tab removed; record in log only
    if not displayName or displayName == "" then return end
    if not _skipHistSave then
        table.insert(historyLog, 1, {dn=displayName, un=username or "", model=model, mut=mutation, uid=userId})
        if #historyLog > 50 then table.remove(historyLog) end
        saveHistory()
    end
end

-- ONLINE ROW
addToOnlineTab = function(displayName, username, userId, entryId, modelName, mutation)
    if not displayName or displayName == "" then return end
    if onlineByEntry[entryId] then return end

    -- Verify actually online before adding
    task.spawn(function()
        local presence = fetchPresence(userId)
        if not presence or presence.presenceType ~= 2 then return end

        local ROW_H = isMobile and 66 or 72
        local row = Instance.new("Frame")
        row.Name = "OnlineRow_" .. tostring(entryId)
        row.Size = UDim2.new(1, -16, 0, ROW_H)
        row.BackgroundColor3 = T.Card
        row.BackgroundTransparency = 0.15
        row.BorderSizePixel = 0
        row.Parent = OnlineTab.scroll
        Corner(row, 10)
        local rowStroke = Stroke(row, T.Border, 1)
        local bar = Instance.new("Frame")
        bar.Size             = UDim2.new(0, 3, 1, -16)
        bar.Position         = UDim2.new(0, 0, 0, 8)
        bar.BackgroundColor3 = T.Good
        bar.BorderSizePixel  = 0
        bar.ZIndex           = 2
        bar.Parent           = row
        Corner(bar, 2)

        local dot = Instance.new("Frame", row)
        dot.Size = UDim2.new(0, 8, 0, 8); dot.Position = UDim2.new(0, 14, 0.5, -4)
        dot.BackgroundColor3 = T.Good; dot.BorderSizePixel = 0
        Corner(dot, 4)

        local nameL = Instance.new("TextLabel", row)
        nameL.Size = UDim2.new(1, -100, 0, 16); nameL.Position = UDim2.new(0, 28, 0, 8)
        nameL.BackgroundTransparency = 1; nameL.TextColor3 = T.White
        nameL.TextSize = isMobile and 11 or 12; nameL.Font = Enum.Font.GothamBold
        nameL.TextXAlignment = Enum.TextXAlignment.Left; nameL.TextTruncate = Enum.TextTruncate.AtEnd
        nameL.Text = displayName

        local subL = Instance.new("TextLabel", row)
        subL.Size = UDim2.new(1, -100, 0, 12); subL.Position = UDim2.new(0, 28, 0, 26)
        subL.BackgroundTransparency = 1; subL.TextColor3 = T.Dim
        subL.TextSize = isMobile and 9 or 10; subL.Font = Enum.Font.Gotham
        subL.TextXAlignment = Enum.TextXAlignment.Left
        subL.Text = "@" .. (username or "?")

        -- Item label (model + mutation)
        if modelName and modelName ~= "" then
            local itemL = Instance.new("TextLabel", row)
            itemL.Size = UDim2.new(1, -100, 0, 12); itemL.Position = UDim2.new(0, 28, 0, 40)
            itemL.BackgroundTransparency = 1; itemL.TextColor3 = T.Good
            itemL.TextSize = isMobile and 9 or 10; itemL.Font = Enum.Font.GothamMedium
            itemL.TextXAlignment = Enum.TextXAlignment.Left; itemL.TextTruncate = Enum.TextTruncate.AtEnd
            local mutStr = (mutation and mutation ~= "" and mutation ~= "Base") and (" · " .. mutation) or ""
            itemL.Text = modelName .. mutStr
        end

        local tradeBtn = Instance.new("TextButton", row)
        tradeBtn.Size = UDim2.new(0, 60, 0, isMobile and 22 or 24)
        tradeBtn.Position = UDim2.new(1, -68, 0.5, -(isMobile and 11 or 12))
        tradeBtn.BackgroundColor3 = T.AccentBg; tradeBtn.BorderSizePixel = 0
        tradeBtn.Text = "Trade"; tradeBtn.TextColor3 = T.AccentFg
        tradeBtn.TextSize = isMobile and 10 or 11; tradeBtn.Font = Enum.Font.GothamBold
        tradeBtn.AutoButtonColor = false
        Corner(tradeBtn, 8)
        Stroke(tradeBtn, Color3.fromRGB(70, 70, 76), 1)
        tradeBtn.MouseEnter:Connect(function() Tween(tradeBtn, F, {BackgroundColor3 = Color3.fromRGB(220,220,220)}) end)
        tradeBtn.MouseLeave:Connect(function() Tween(tradeBtn, F, {BackgroundColor3 = T.AccentBg}) end)
        tradeBtn.ZIndex = 5
        tradeBtn.Activated:Connect(function()
            if not userId then return end
            tradeBtn.Text = "..."
            tradeBtn.Active = false
            invokeTrade(userId, function(success)
                if tradeBtn and tradeBtn.Parent then
                    tradeBtn.Text = success and "Sent!" or "Failed"
                    task.delay(2.5, function()
                        if tradeBtn and tradeBtn.Parent then
                            tradeBtn.Text = "Trade"
                            tradeBtn.Active = true
                        end
                    end)
                end
            end)
        end)

        row.Active = true
        row.MouseEnter:Connect(function() Tween(row, F, {BackgroundColor3 = T.CardHover}); Tween(rowStroke, F, {Color = T.BorderHover}) end)
        row.MouseLeave:Connect(function() Tween(row, F, {BackgroundColor3 = T.Card}); Tween(rowStroke, F, {Color = T.Border}) end)

        onlineByEntry[entryId] = row
        local empty = OnlineTab.scroll:FindFirstChild("OnlineEmpty")
        if empty then empty:Destroy() end
        table.insert(onlineEntries, row)
        if not _skipOnlSave then
            onlineLog[tostring(entryId)] = {dn=displayName, un=username or "", uid=userId, model=modelName or "", mut=mutation or ""}
            saveOnlineLog()
        end

        -- Periodic re-verification: remove row if user goes offline
        task.spawn(function()
            while row and row.Parent do
                task.wait(30)
                if not (row and row.Parent) then break end
                local p = fetchPresence(userId)
                if not p or p.presenceType ~= 2 then
                    removeFromOnlineTab(entryId)
                    break
                end
            end
        end)
    end)
end

removeFromOnlineTab = function(entryId)
    if onlineByEntry[entryId] then
        onlineByEntry[entryId]:Destroy()
        onlineByEntry[entryId] = nil
        onlineLog[tostring(entryId)] = nil
        saveOnlineLog()
    end
    local anyLeft = false
    for _, c in ipairs(OnlineTab.scroll:GetChildren()) do
        if c.Name and c.Name:sub(1, 10) == "OnlineRow_" then anyLeft = true; break end
    end
    if not anyLeft and not OnlineTab.scroll:FindFirstChild("OnlineEmpty") then
        local empty = Instance.new("TextLabel")
        empty.Name = "OnlineEmpty"
        empty.Size = UDim2.new(1, -16, 0, 32)
        empty.BackgroundTransparency = 1
        empty.TextColor3 = T.Dim
        empty.TextSize = 11
        empty.Font = Enum.Font.Gotham
        empty.Text = "No one online right now"
        empty.TextXAlignment = Enum.TextXAlignment.Center
        empty.Parent = OnlineTab.scroll
    end
end

local function loadHistory()
    pcall(function()
        if not isfile(HISTORY_PATH) then return end
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(HISTORY_PATH)) end)
        if not ok or type(data) ~= "table" then return end
        historyLog = data
        _skipHistSave = true
        for _, e in ipairs(data) do
            if e.dn and e.dn ~= "" then
                addToHistory(e.dn, e.un or "", e.model or "?", e.mut or "Base", e.uid)
            end
        end
        _skipHistSave = false
    end)
end

local function loadOnlineLog()
    pcall(function()
        if not isfile(ONLINE_PATH) then return end
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(ONLINE_PATH)) end)
        if not ok or type(data) ~= "table" then return end
        for _, e in ipairs(data) do
            if e.uid then
                task.spawn(function()
                    local presence = fetchPresence(e.uid)
                    if presence and presence.presenceType == 2 then
                        addToOnlineTab(e.dn or "?", e.un or "?", e.uid, e.uid, e.model or "", e.mut or "")
                    else
                        onlineLog[tostring(e.uid)] = nil
                        saveOnlineLog()
                    end
                end)
            end
        end
    end)
end

-- ============================================================
-- shouldShow / animate
-- ============================================================
local function shouldShow(data)
    local model      = data.modelName
    local isUnclaimed = data.isUnclaimed
    if not model or model == "" then return false, false end
    return true, not isUnclaimed
end

local function animateIn(card, cardWrap)
    cardWrap.Visible = true
    card.BackgroundTransparency = 1
    card.Position = UDim2.new(0, 3, 0, 18)
    Tween(card, S, {BackgroundTransparency = 0.15, Position = UDim2.new(0, 3, 0, 0)})
end

local function animateOut(card, cardWrap, cb)
    Tween(card, F, {BackgroundTransparency = 1, Position = UDim2.new(0, 3, 0, 18)})
    task.delay(0.18, function()
        cardWrap.Visible = false
        if cb then cb() end
    end)
end

local function refreshAllCards()
    for _, data in ipairs(allCards) do
        if data.card and data.card.Parent then
            local exists, toLive = shouldShow(data)
            if not exists or data.isUnclaimed then
                if data.cardWrap.Visible then animateOut(data.card, data.cardWrap) end
            elseif toLive then
                data.cardWrap.Parent = LiveTab.scroll
                if not data.cardWrap.Visible then animateIn(data.card, data.cardWrap)
                else data.cardWrap.Visible = true end
            else
                if data.cardWrap.Visible then animateOut(data.card, data.cardWrap) end
            end
        end
    end
end

-- ============================================================
-- LIVE CARD (Faded style)
-- ============================================================
local function makeCard(entryFrame, resolvedUsername, resolvedDisplay, resolvedUserId, resolvedAvatarUrl)
    if seenEntries[entryFrame] and type(seenEntries[entryFrame]) == "table" then return end
    local filler = entryFrame:FindFirstChild("Filler")
    if not filler then return end

    local modelName = getModelName(filler)
    if not ALLOWED_MODELS[modelName] then return end

    local mutation = getMutation(filler)
    local locationObj = filler:FindFirstChild("Location")
    local locationTxt = locationObj and locationObj.Text or ""
    if locationTxt == "[SERVER]" then return end

    local username = (resolvedUsername and resolvedUsername ~= "" and resolvedUsername) or nil
    local userId   = resolvedUserId or nil
    if not username or not userId then
        local u, uid = getUsername(filler)
        username = username or u
        userId   = userId   or uid
    end
    local isUnclaimed = not username

    cardOrder = cardOrder - 1

    local cardWrap = Instance.new("Frame")
    cardWrap.Size = UDim2.new(1, -16, 0, CARD_H)
    cardWrap.BackgroundTransparency = 1
    cardWrap.BorderSizePixel = 0
    cardWrap.LayoutOrder = cardOrder
    cardWrap.ZIndex = 4
    cardWrap.Visible = false

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -6, 1, -4)
    card.Position = UDim2.new(0, 3, 0, 18)
    card.BackgroundColor3 = T.Card
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.ZIndex = 5
    card.Parent = cardWrap
    Corner(card, 10)
    local stroke = Stroke(card, T.Border, 1)

    -- left accent bar
    local accentBar = Instance.new("Frame")
    accentBar.Size             = UDim2.new(0, 3, 1, -16)
    accentBar.Position         = UDim2.new(0, 0, 0, 8)
    accentBar.BackgroundColor3 = T.White
    accentBar.BorderSizePixel  = 0
    accentBar.ZIndex           = 6
    accentBar.Parent           = card
    Corner(accentBar, 2)

    -- Viewport box (left)
    local vpSize = CARD_H - 24
    local vpBox = Instance.new("Frame")
    vpBox.Size = UDim2.new(0, vpSize, 0, vpSize)
    vpBox.Position = UDim2.new(0, 12, 0.5, -vpSize/2)
    vpBox.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    vpBox.BorderSizePixel = 0
    vpBox.ZIndex = 6
    vpBox.Parent = card
    Corner(vpBox, 8)
    Stroke(vpBox, T.Border, 1)

    buildViewport(vpBox, modelName, mutation, 1)

    -- Avatar circle
    local AV = isMobile and 32 or 38
    local avatarFrame = Instance.new("Frame")
    avatarFrame.Size = UDim2.new(0, AV, 0, AV)
    avatarFrame.Position = UDim2.new(0, vpSize + 20, 0.5, -AV/2 - 12)
    avatarFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    avatarFrame.BorderSizePixel = 0
    avatarFrame.ClipsDescendants = true
    avatarFrame.ZIndex = 6
    avatarFrame.Parent = card
    Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)
    local avStroke = Instance.new("UIStroke", avatarFrame)
    avStroke.Color = T.White; avStroke.Thickness = 1; avStroke.Transparency = 0.55
    avStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size = UDim2.new(1, 0, 1, 0)
    avatarImg.BackgroundTransparency = 1
    avatarImg.ScaleType = Enum.ScaleType.Crop
    avatarImg.Image = resolvedAvatarUrl or ""
    avatarImg.ZIndex = 7; avatarImg.Parent = avatarFrame
    Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

    -- Status dot
    local dotSz = isMobile and 9 or 11
    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, dotSz, 0, dotSz)
    statusDot.Position = UDim2.new(1, -1, 1, -1)
    statusDot.AnchorPoint = Vector2.new(1, 1)
    statusDot.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    statusDot.BorderSizePixel = 0; statusDot.ZIndex = 8; statusDot.Parent = avatarFrame
    Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)
    local dotRing = Instance.new("UIStroke", statusDot)
    dotRing.Color = T.Card; dotRing.Thickness = 2
    dotRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Text area
    local TX = vpSize + 20 + AV + 10
    local TW = -(TX + LBTN_W + 18)
    local textArea = Instance.new("Frame")
    textArea.Size = UDim2.new(1, TW, 1, 0)
    textArea.Position = UDim2.new(0, TX, 0, 0)
    textArea.BackgroundTransparency = 1
    textArea.BorderSizePixel = 0
    textArea.ZIndex = 6; textArea.Parent = card

    local _row1Text = (resolvedDisplay and resolvedDisplay ~= "" and resolvedDisplay) or username or modelName
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, isMobile and 14 or 16)
    nameLabel.Position = UDim2.new(0, 0, 0, isMobile and 8 or 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = _row1Text
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = isMobile and 11 or 13
    nameLabel.TextColor3 = T.White
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 7; nameLabel.Parent = textArea

    local userLabel = Instance.new("TextLabel")
    userLabel.Size = UDim2.new(1, 0, 0, isMobile and 11 or 13)
    userLabel.Position = UDim2.new(0, 0, 0, isMobile and 23 or 28)
    userLabel.BackgroundTransparency = 1
    if username and userId then
        userLabel.Text = "@" .. username .. "  -  " .. tostring(userId)
        userLabel.TextColor3 = T.Dim
    else
        userLabel.Text = "UNCLAIMED  -  " .. mutation
        userLabel.TextColor3 = T.Dim
    end
    userLabel.Font = Enum.Font.Gotham
    userLabel.TextSize = isMobile and 8 or 10
    userLabel.TextXAlignment = Enum.TextXAlignment.Left
    userLabel.TextTruncate = Enum.TextTruncate.AtEnd
    userLabel.ZIndex = 7; userLabel.Parent = textArea

    local subLabel = Instance.new("TextLabel")
    subLabel.Size = UDim2.new(1, 0, 0, isMobile and 11 or 12)
    subLabel.Position = UDim2.new(0, 0, 0, isMobile and 37 or 44)
    subLabel.BackgroundTransparency = 1
    subLabel.Text = modelName .. "  -  " .. mutation
    subLabel.Font = Enum.Font.GothamMedium
    subLabel.TextSize = isMobile and 8 or 10
    subLabel.TextColor3 = T.Dim
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.TextTruncate = Enum.TextTruncate.AtEnd
    subLabel.ZIndex = 7; subLabel.Parent = textArea

    local profileBtn = Instance.new("TextButton")
    profileBtn.Size = UDim2.new(1, 0, 0, isMobile and 11 or 13)
    profileBtn.Position = UDim2.new(0, 0, 0, isMobile and 51 or 60)
    profileBtn.BackgroundTransparency = 1; profileBtn.BorderSizePixel = 0
    profileBtn.Text = "View Profile  >"
    profileBtn.Font = Enum.Font.GothamMedium
    profileBtn.TextSize = isMobile and 8 or 10
    profileBtn.TextColor3 = T.White
    profileBtn.TextXAlignment = Enum.TextXAlignment.Left
    profileBtn.AutoButtonColor = false
    profileBtn.ZIndex = 7; profileBtn.Parent = textArea
    profileBtn.Visible = not isUnclaimed

    -- Action buttons (right side stacked)
    local _btnY2 = LBTN_H + 6
    local topY   = math.floor((CARD_H - 4 - (LBTN_H * 2 + 6)) / 2)
    local copyBtn  = makeActionBtn(card, LBTN_W, LBTN_H, -(LBTN_W + 12), topY,            "Copy",  false)
    local tradeBtn = makeActionBtn(card, LBTN_W, LBTN_H, -(LBTN_W + 12), topY + _btnY2,   "Trade", true)
    copyBtn.Visible  = not isUnclaimed
    tradeBtn.Visible = not isUnclaimed

    local _ref = {uid = userId, name = username}

    profileBtn.Activated:Connect(function()
        local uid = _ref.uid
        if not uid then return end
        local url = "https://www.roblox.com/users/" .. tostring(uid) .. "/profile"
        pcall(function() setclipboard(url) end)
        profileBtn.Text = "Copied!"
        task.delay(1.5, function() if profileBtn and profileBtn.Parent then profileBtn.Text = "View Profile  >" end end)
    end)

    copyBtn.Activated:Connect(function()
        local uid = _ref.uid
        if not uid then return end
        copyBtn.Text = "..."
        task.spawn(function()
            local fresh = nil
            pcall(function() fresh = Players:GetNameFromUserIdAsync(uid) end)
            local fallback = _ref.name
            local name = (fresh and isValidUsername(fresh)) and fresh or fallback
            if name and isValidUsername(name) then
                pcall(function() setclipboard(name) end)
                if copyBtn and copyBtn.Parent then
                    copyBtn.Text = "Done"
                    task.delay(1.5, function() if copyBtn and copyBtn.Parent then copyBtn.Text = "Copy" end end)
                end
            else
                if copyBtn and copyBtn.Parent then copyBtn.Text = "Copy" end
            end
        end)
    end)

    tradeBtn.Activated:Connect(function()
        local uid = _ref.uid
        if not uid then return end
        tradeBtn.Text = "..."
        invokeTrade(uid, function(success)
            if tradeBtn and tradeBtn.Parent then
                tradeBtn.Text = success and "Sent" or "Failed"
                task.delay(2.5, function() if tradeBtn and tradeBtn.Parent then tradeBtn.Text = "Trade" end end)
            end
        end)
    end)

    card.MouseEnter:Connect(function() Tween(card, F, {BackgroundColor3 = T.CardHover}); Tween(stroke, F, {Color = T.BorderHover}) end)
    card.MouseLeave:Connect(function() Tween(card, F, {BackgroundColor3 = T.Card}); Tween(stroke, F, {Color = T.Border}) end)

    if userId then
        local _notifyName = (resolvedDisplay and resolvedDisplay ~= "" and resolvedDisplay) or username or "Someone"
        startPresencePolling(statusDot, userId,
            function() addToOnlineTab(_notifyName, username, userId, userId, modelName, mutation) end,
            function() removeFromOnlineTab(userId); showOfflineToast(_notifyName) end)
    end

    local data = {
        cardWrap = cardWrap, card = card,
        stroke = stroke, vpBox = vpBox,
        copyBtn = copyBtn, tradeBtn = tradeBtn,
        userLabel = userLabel, nameLabel = nameLabel,
        profileBtn = profileBtn, statusDot = statusDot,
        avatarFrame = avatarFrame, avatarImg = avatarImg,
        isUnclaimed = isUnclaimed, modelName = modelName, mutation = mutation, filler = filler,
        _ref = _ref,
        _resolvedUserId = userId,
    }
    seenEntries[entryFrame] = data
    table.insert(allCards, data)

    if not isUnclaimed then
        cardWrap.Parent = LiveTab.scroll
        animateIn(card, cardWrap)
        playNotifSound()
        showSpawnToast(modelName, mutation)
        if userId then
            local _dn = (resolvedDisplay and resolvedDisplay ~= "" and resolvedDisplay) or username or modelName
            addToHistory(_dn, username or "", modelName, mutation, userId)
        end
    end
end

-- ============================================================
-- WATCHER
-- ============================================================
local function getCorrectSurfaceGui(playerGui)
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui.Name == "SurfaceGui" and gui:FindFirstChild("ScrollingFrame") then
            return gui
        end
    end
    return nil
end

local inflightProcess = {}

local function processEntryForCard(entry)
    if inflightProcess[entry] then return end
    local existingQuick = seenEntries[entry]
    if existingQuick and type(existingQuick) == "table" and existingQuick._resolvedUserId then return end
    inflightProcess[entry] = true
    task.spawn(function()
        local filler = entry:FindFirstChild("Filler")
        if not filler then inflightProcess[entry] = nil; return end
        local playerBg = filler:FindFirstChild("PlayerBg")
        if not playerBg then inflightProcess[entry] = nil; return end

        local usernameLabel = playerBg:FindFirstChild("Username")
        local usernameText  = usernameLabel and usernameLabel.Text or ""
        local displayLabel  = playerBg:FindFirstChild("Display")
        local displayText   = displayLabel and displayLabel.Text or usernameText

        local function looksUnclaimed(t)
            if not t or t == "" then return true end
            local lo = t:lower()
            return lo == "unclaimed" or lo == "unknown" or lo == "..." or lo == "none"
        end

        local userId = nil
        local headshot = playerBg:FindFirstChild("Headshot")
        if headshot and headshot:IsA("ImageLabel") then
            local waited = 0
            while waited < 4 do
                local img = headshot.Image or ""
                if img ~= "" and img:find("id=") then
                    local id = img:match("id=(%d+)")
                    if id then userId = tonumber(id); break end
                end
                task.wait(0.1)
                waited = waited + 0.1
            end
        end

        if not userId and not looksUnclaimed(usernameText) then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name == usernameText then userId = p.UserId; break end
            end
        end

        if not userId and not looksUnclaimed(usernameText) then
            userId = getUserIdFromUsername(usernameText)
        end

        local avatarUrl = userId and ("rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=150&h=150") or nil

        if userId and looksUnclaimed(usernameText) then
            local canon = nil
            pcall(function() canon = Players:GetNameFromUserIdAsync(userId) end)
            if canon and canon ~= "" then
                usernameText = canon
                if looksUnclaimed(displayText) then displayText = canon end
            end
        end

        local existing = seenEntries[entry]
        if existing and type(existing) == "table" then
            inflightProcess[entry] = nil
            if userId and not existing._resolvedUserId then
                existing._resolvedUserId = userId
                if existing._ref then
                    existing._ref.uid = userId
                    existing._ref.name = usernameText
                end
                existing.isUnclaimed = false
                task.defer(function()
                    local _rdn = (existing.nameLabel and existing.nameLabel.Text ~= "" and existing.nameLabel.Text) or usernameText or ""
                    addToHistory(_rdn, usernameText or "", existing.modelName or "?", existing.mutation or "Base", userId)
                end)
                if existing.copyBtn    and existing.copyBtn.Parent    then existing.copyBtn.Visible    = true end
                if existing.tradeBtn   and existing.tradeBtn.Parent   then existing.tradeBtn.Visible   = true end
                if existing.profileBtn and existing.profileBtn.Parent then existing.profileBtn.Visible = true end
                if existing.avatarImg  and existing.avatarImg.Parent  then existing.avatarImg.Image    = avatarUrl end
                if existing.userLabel  and existing.userLabel.Parent  then
                    existing.userLabel.Text = "@" .. usernameText .. "  -  " .. tostring(userId)
                    existing.userLabel.TextColor3 = T.Dim
                end
                if existing.nameLabel and existing.nameLabel.Parent then
                    existing.nameLabel.Text = displayText ~= "" and displayText or usernameText
                end
                if existing.statusDot and existing.statusDot.Parent then
                    local _pName = (existing.nameLabel and existing.nameLabel.Text ~= "" and existing.nameLabel.Text) or usernameText or "Someone"
                    startPresencePolling(existing.statusDot, userId,
                        function() addToOnlineTab(_pName, usernameText, userId, userId, existing.modelName, existing.mutation) end,
                        function() removeFromOnlineTab(userId); showOfflineToast(_pName) end)
                end
                if existing.cardWrap and existing.cardWrap.Parent ~= LiveTab.scroll then
                    if existing.cardWrap.Visible then
                        animateOut(existing.card, existing.cardWrap, function()
                            existing.cardWrap.Parent = LiveTab.scroll
                            animateIn(existing.card, existing.cardWrap)
                            playNotifSound()
                            showSpawnToast(existing.modelName, existing.mutation)
                        end)
                    else
                        existing.cardWrap.Parent = LiveTab.scroll
                        animateIn(existing.card, existing.cardWrap)
                        playNotifSound()
                        showSpawnToast(existing.modelName, existing.mutation)
                    end
                end
            end
            return
        end

        makeCard(entry, usernameText, displayText, userId, avatarUrl)
        inflightProcess[entry] = nil
    end)
end

local function watchEntry(entry)
    task.spawn(processEntryForCard, entry)
    local debounce = false
    entry.DescendantAdded:Connect(function()
        if debounce then return end
        local existing = seenEntries[entry]
        if existing and type(existing) == "table" and existing._resolvedUserId then return end
        debounce = true
        task.delay(0.3, function()
            debounce = false
            task.spawn(processEntryForCard, entry)
        end)
    end)
end

local function initWatcher()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 30)
    if not playerGui then return end

    local surfaceGui = nil
    repeat
        surfaceGui = getCorrectSurfaceGui(playerGui)
        if not surfaceGui then task.wait(1) end
    until surfaceGui

    local scrollingFrame = nil
    repeat
        scrollingFrame = surfaceGui:FindFirstChild("ScrollingFrame")
        if not scrollingFrame then task.wait(1) end
    until scrollingFrame

    local watched = {}
    local function handle(entry)
        if entry.Name ~= "Entry" then return end
        if watched[entry] then return end
        watched[entry] = true
        watchEntry(entry)
    end

    for _, entry in ipairs(scrollingFrame:GetChildren()) do handle(entry) end
    scrollingFrame.ChildAdded:Connect(handle)

    task.spawn(function()
        while true do
            task.wait(1)
            if not surfaceGui.Parent then
                task.spawn(initWatcher)
                task.defer(function()
                    task.wait(0.5)
                    loadHistory()
                    loadOnlineLog()
                end)
                return
            end
            for _, entry in ipairs(scrollingFrame:GetChildren()) do
                handle(entry)
                if entry.Name == "Entry" and not inflightProcess[entry] then
                    local existing = seenEntries[entry]
                    if not existing or (type(existing) == "table" and not existing._resolvedUserId) then
                        task.spawn(processEntryForCard, entry)
                    end
                end
            end
        end
    end)
end

-- ============================================================
-- HISTORY / ONLINE empty placeholders
-- ============================================================
local function makeEmptyLabel(parent, name, text)
    local empty = Instance.new("TextLabel")
    empty.Name = name
    empty.Size = UDim2.new(1, -16, 0, 32)
    empty.BackgroundTransparency = 1
    empty.TextColor3 = T.Dim
    empty.TextSize = 11
    empty.Font = Enum.Font.Gotham
    empty.Text = text
    empty.TextXAlignment = Enum.TextXAlignment.Center
    empty.Parent = parent
    return empty
end
makeEmptyLabel(OnlineTab.scroll,  "OnlineEmpty", "No one online right now")

-- ============================================================
-- SETTINGS TAB
-- ============================================================
local function CreateToggle(parent, name, desc, initial, cb)
    local hasDesc = desc and desc ~= ""
    local cardH   = isMobile and (hasDesc and 56 or 44) or (hasDesc and 56 or 44)
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(1, -16, 0, cardH)
    card.BackgroundColor3 = T.Card
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel  = 0
    card.Parent           = parent
    Corner(card, 8)
    local cStroke = Stroke(card, T.Border, 1)
    -- accent bar
    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 3, 0, cardH - 16)
    bar.Position         = UDim2.new(0, 0, 0, 8)
    bar.BackgroundColor3 = initial and T.TrackOn or T.TrackOff
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 2
    bar.Parent           = card
    Corner(bar, 2)

    local nameY  = hasDesc and 10 or (cardH/2 - 8)
    local nameLbl = Label(card, name, isMobile and 11 or 13, T.White, Enum.Font.GothamMedium)
    nameLbl.Size     = UDim2.new(1, -70, 0, 16)
    nameLbl.Position = UDim2.new(0, 14, 0, nameY)
    nameLbl.ZIndex   = 2
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    if hasDesc then
        local descLbl = Label(card, desc, isMobile and 9 or 11, T.Dim, Enum.Font.Gotham)
        descLbl.Size     = UDim2.new(1, -70, 0, 14)
        descLbl.Position = UDim2.new(0, 14, 0, nameY + 18)
        descLbl.ZIndex   = 2
        descLbl.TextTruncate = Enum.TextTruncate.AtEnd
    end

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(0, 40, 0, 22)
    track.Position         = UDim2.new(1, -52, 0.5, -11)
    track.BackgroundColor3 = initial and T.TrackOn or T.TrackOff
    track.BorderSizePixel  = 0
    track.ZIndex           = 2
    track.Parent           = card
    Corner(track, 11)
    local tStroke = Stroke(track, T.Border, 1)
    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 16, 0, 16)
    knob.Position         = initial and UDim2.new(0, 21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = initial and T.KnobOn or T.KnobOff
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 3
    knob.Parent           = track
    Corner(knob, 8)

    local state = initial and true or false

    card.MouseEnter:Connect(function() Tween(card, F, {BackgroundColor3 = T.CardHover}); Tween(cStroke, F, {Color = T.BorderHover}) end)
    card.MouseLeave:Connect(function() Tween(card, F, {BackgroundColor3 = T.Card}); Tween(cStroke, F, {Color = T.Border}) end)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1
    btn.Text = ""; btn.ZIndex = 4; btn.Parent = card
    btn.AutoButtonColor = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            Tween(knob, M, {Position = UDim2.new(0, 21, 0.5, -8), BackgroundColor3 = T.KnobOn})
            Tween(track, M, {BackgroundColor3 = T.TrackOn})
            Tween(bar, M, {BackgroundColor3 = T.TrackOn})
        else
            Tween(knob, M, {Position = UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = T.KnobOff})
            Tween(track, M, {BackgroundColor3 = T.TrackOff})
            Tween(bar, M, {BackgroundColor3 = T.TrackOff})
        end
        if cb then cb(state) end
    end)
    return card
end

CreateSection(SettingsTab.scroll, "DISPLAY")
CreateToggle(SettingsTab.scroll, "Notifications", "Show toast popups when something spawns or comes online",
    cfg.notifications, function(s) cfg.notifications = s; saveConfig() end)
CreateToggle(SettingsTab.scroll, "Sounds", "Play a chime on new live entries",
    cfg.sounds, function(s) cfg.sounds = s; saveConfig() end)

CreateSection(SettingsTab.scroll, "DIVISION")
do
    local infoCard = Instance.new("Frame")
    infoCard.Size             = UDim2.new(1, -16, 0, 44)
    infoCard.BackgroundColor3 = T.Card
    infoCard.BackgroundTransparency = 0.15
    infoCard.BorderSizePixel  = 0
    infoCard.Parent           = SettingsTab.scroll
    Corner(infoCard, 8)
    Stroke(infoCard, T.Border, 1)
    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 3, 0, 28)
    bar.Position         = UDim2.new(0, 0, 0, 8)
    bar.BackgroundColor3 = T.White
    bar.BorderSizePixel  = 0
    bar.Parent           = infoCard
    Corner(bar, 2)
    local lbl = Label(infoCard, "Locked to Division 3 only", isMobile and 11 or 12, T.White, Enum.Font.GothamMedium)
    lbl.Size     = UDim2.new(1, -20, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.TextYAlignment = Enum.TextYAlignment.Center
end

-- ============================================================
-- DEFERRED INIT
-- ============================================================
task.defer(function()
    task.wait(0.5)
    loadHistory()
    loadOnlineLog()
end)

task.spawn(initWatcher)
