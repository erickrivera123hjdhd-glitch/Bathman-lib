--[[
    Crimson UI Library  v1.1.0
    A small, themeable Roblox GUI library (client-side / executor).

    Elements : Button (+ toggle / confirm / cooldown), Button rows, Toggle, Slider,
               Textbox, Dropdown (single + multi), Keybind, Label, Section, Divider
    Extras   : Tabs, themes (live switching), toasts, draggable avatar toggle,
               config save/load (flags), UI scale, background images

    Quick start:
        local Library = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/erickrivera123hjdhd-glitch/Bathman-lib/refs/heads/Main/CrimsonUI/CrimsonUI.lua"
        ))()
        local Window  = Library.new({ Title = "My Hub" })
        local Tab     = Window:AddTab("Main")
        Tab:AddButton({ Text = "Hello", Callback = function() print("hi") end })

    Background image:
        -- put your image in the repo (e.g. CrimsonUI/bg.png) and use its raw link:
        local Window = Library.new({
            Title = "My Hub",
            BackgroundUrl = "https://raw.githubusercontent.com/erickrivera123hjdhd-glitch/Bathman-lib/refs/heads/Main/CrimsonUI/bg.png",
            BackgroundTransparency = 0.2,                    -- 0 = solid, 1 = hidden
        })
        Window:SetBackground("rbxassetid://123456") -- swap any time (no download needed)
        Window:ClearBackground()
        http(s) links are downloaded with getcustomasset + writefile and saved
        as "crimsonui_bg.png" (executor only).
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

local Library = { Version = "1.1.0", Folder = "CrimsonUI" }
local Window  = {}  Window.__index  = Window
local Tab     = {}  Tab.__index     = Tab
local Element = {}  Element.__index = Element

--========================== THEMES ================================
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local function makeTheme(o)
    local t = {
        text       = rgb(255, 255, 255),
        textSub    = rgb(232, 238, 248),
        textStatus = rgb(222, 230, 244),
        error      = rgb(255, 205, 120),
        btnText    = rgb(255, 255, 255),
        busyText   = rgb(255, 255, 255),
    }
    for k, v in pairs(o) do t[k] = v end
    t.tabIdle   = t.tabIdle or t.chip
    t.tabActive = t.tabActive or t.btn
    return t
end
Library.MakeTheme = makeTheme

Library.Themes = {
    Crimson = makeTheme({
        panel = rgb(30, 10, 14), tint = rgb(10, 2, 4),
        btn = rgb(193, 18, 31), btnHover = rgb(229, 48, 58),
        btnActive = rgb(122, 11, 20), btnActiveHover = rgb(154, 20, 32),
        busy = rgb(74, 42, 46), accent = rgb(255, 59, 59),
        track = rgb(42, 12, 16), chip = rgb(26, 10, 14),
    }),
    Midnight = makeTheme({
        panel = rgb(12, 16, 30), tint = rgb(4, 6, 14),
        btn = rgb(52, 101, 230), btnHover = rgb(84, 132, 255),
        btnActive = rgb(30, 60, 150), btnActiveHover = rgb(44, 80, 180),
        busy = rgb(40, 46, 66), accent = rgb(96, 150, 255),
        track = rgb(18, 24, 46), chip = rgb(14, 20, 38),
    }),
    Emerald = makeTheme({
        panel = rgb(10, 26, 20), tint = rgb(2, 10, 6),
        btn = rgb(22, 163, 110), btnHover = rgb(46, 196, 138),
        btnActive = rgb(12, 100, 68), btnActiveHover = rgb(18, 128, 88),
        busy = rgb(36, 62, 52), accent = rgb(52, 211, 153),
        track = rgb(12, 40, 30), chip = rgb(10, 30, 22),
    }),
    Mono = makeTheme({
        panel = rgb(24, 24, 26), tint = rgb(8, 8, 10),
        btn = rgb(88, 88, 96), btnHover = rgb(120, 120, 130),
        btnActive = rgb(50, 50, 56), btnActiveHover = rgb(70, 70, 78),
        busy = rgb(46, 46, 50), accent = rgb(220, 220, 230),
        track = rgb(36, 36, 40), chip = rgb(30, 30, 34),
    }),
}

local function resolveTheme(t)
    if type(t) == "string" then
        return Library.Themes[t] or Library.Themes.Crimson, Library.Themes[t] and t or "Crimson"
    end
    if type(t) == "table" then
        -- clone so we never mutate the user's theme table
        local copy = table.clone(t)
        if getmetatable(copy) == nil then
            setmetatable(copy, { __index = Library.Themes.Crimson })
        end
        return copy, "Custom"
    end
    return Library.Themes.Crimson, "Crimson"
end

--========================== HELPERS ===============================
local WHITE = rgb(255, 255, 255)

local function new(class, props, parent)
    local inst = Instance.new(class)
    if props then for k, v in pairs(props) do inst[k] = v end end
    if parent then inst.Parent = parent end
    return inst
end

local function corner(inst, r)
    return new("UICorner", { CornerRadius = UDim.new(0, r) }, inst)
end

local function stroke(inst, color, thickness, transparency)
    return new("UIStroke", {
        Color = color or WHITE, Thickness = thickness or 1, Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, inst)
end

local function padding(inst, l, t, r, b)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
        PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b),
    }, inst)
end

local function tween(inst, time, props)
    TweenService:Create(inst, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function textLabel(parent, props)
    local d = {
        BackgroundTransparency = 1, BorderSizePixel = 0, Text = "",
        Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    }
    for k, v in pairs(props) do d[k] = v end
    return new("TextLabel", d, parent)
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

-- run a user callback in its own thread; errors are warned, never fatal
local function fire(fn, ...)
    if type(fn) ~= "function" then return end
    task.spawn(function(...)
        local ok, err = pcall(fn, ...)
        if not ok then warn("[CrimsonUI] callback error: " .. tostring(err)) end
    end, ...)
end

local function getGuiParent()
    if type(gethui) == "function" then
        local ok, r = pcall(gethui)
        if ok and r then return r end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then
        local writable = pcall(function()
            local f = Instance.new("Folder")
            f.Parent = cg
            f:Destroy()
        end)
        if writable then return cg end
    end
    local lp = Players.LocalPlayer
    return lp and (lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 10))
end

local function hasFS()
    return type(writefile) == "function" and type(readfile) == "function"
end

local function ensureFolder(path)
    if type(isfolder) ~= "function" or type(makefolder) ~= "function" then return end
    if isfolder(path) then return end
    pcall(makefolder, path)
end

local function cleanName(name)
    return (tostring(name or ""):gsub("[^%w_%- ]", ""))
end

-- Downloads an image (executor only) and returns a rbxasset:// url, or nil.
function Library.ResolveAsset(url, filename)
    if type(getcustomasset) ~= "function" or type(writefile) ~= "function" then return nil end
    local ok, data = pcall(function() return game:HttpGet(url) end)
    if not ok or type(data) ~= "string" or #data < 32 then return nil end
    pcall(writefile, filename, data)
    local good, asset = pcall(getcustomasset, filename)
    return good and asset or nil
end

--========================== ELEMENT BASE ==========================
local function newHandle(win, frame, opts)
    return setmetatable({
        Frame = frame, _window = win, _opts = opts or {},
        _subs = {}, _conns = {},
    }, Element)
end

function Element:SetVisible(v) self.Frame.Visible = v end
function Element:SetCallback(fn) self._opts.Callback = fn end

-- theme repaint scoped to this element (removed automatically on Destroy)
function Element:_watch(fn)
    local sub = self._window:_onTheme(fn)
    table.insert(self._subs, sub)
    return sub
end

-- connection scoped to this element (also registered on the window as a safety net)
function Element:_connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(self._conns, c)
    table.insert(self._window._conns, c)
    return c
end

function Element:Destroy()
    local win = self._window
    for _, sub in ipairs(self._subs) do win:_offTheme(sub) end
    for _, c in ipairs(self._conns) do
        c:Disconnect()
        local i = table.find(win._conns, c)
        if i then table.remove(win._conns, i) end
    end
    if self._flag then
        win.Flags[self._flag] = nil
        win.Elements[self._flag] = nil
    end
    self.Frame:Destroy()
end

function Window:_register(flag, handle, initial)
    if not flag then return end
    self.Flags[flag] = initial
    self.Elements[flag] = handle
    handle._flag = flag
end

--========================== WINDOW ================================
function Library.new(config)
    config = config or {}
    local self = setmetatable({}, Window)
    self.Flags, self.Elements = {}, {}
    self._conns, self._themeFns, self._tabs = {}, {}, {}
    self._baseSize = config.Size or Vector2.new(420, 320)
    self._scale = config.Scale or 1
    self._toastN = 0
    self._active = nil
    self.ToggleKey = config.ToggleKey
    self.Name = config.Name or "CrimsonUI"
    self.Theme, self.ThemeName = resolveTheme(config.Theme)

    local parent = config.Parent or getGuiParent()
    if not parent then error("[CrimsonUI] could not find a place to parent the GUI") end
    pcall(function()
        for _, v in ipairs(parent:GetChildren()) do
            if v.Name == self.Name and v:IsA("ScreenGui") then v:Destroy() end
        end
    end)

    local gui = new("ScreenGui", {
        Name = self.Name, ResetOnSpawn = false, DisplayOrder = 999999, IgnoreGuiInset = true,
    })
    gui.Parent = parent
    self.Gui = gui

    -- holder is sized in real pixels, inner is scaled with UIScale (keeps dragging math simple)
    local holder = new("Frame", { Name = "Holder", BackgroundTransparency = 1, BorderSizePixel = 0 }, gui)
    local inner = new("Frame", {
        Name = "Scaled", Size = UDim2.fromOffset(self._baseSize.X, self._baseSize.Y),
        BackgroundTransparency = 1, BorderSizePixel = 0,
    }, holder)
    self.Holder = holder
    self._uiScale = new("UIScale", {}, inner)
    self:SetScale(self._scale)
    holder.Position = UDim2.new(
        0.5, -self._baseSize.X * self._scale / 2,
        0.5, -self._baseSize.Y * self._scale / 2
    )
    if config.StartHidden then holder.Visible = false end

    -- main panel
    local main = new("Frame", {
        Name = "Main", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Active = true,
        ClipsDescendants = true, BackgroundTransparency = config.Transparency or 0.15,
    }, inner)
    corner(main, 18)
    local mainStroke = stroke(main, WHITE, 1.5, 0.5)
    self:_onTheme(function(th)
        main.BackgroundColor3 = th.panel
        mainStroke.Color = th.accent
    end)

    -- optional background image + tint
    local surface = new("Frame", {
        Name = "Surface", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 0,
    }, main)
    corner(surface, 18)
    self._bgImage = new("ImageLabel", {
        Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        ImageTransparency = 1, ScaleType = Enum.ScaleType.Crop, ZIndex = 0,
    }, surface)
    corner(self._bgImage, 18)
    local tint = new("Frame", {
        Name = "Tint", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = 0,
        BackgroundTransparency = config.TintTransparency or 0.85,
    }, surface)
    corner(tint, 18)
    self._tintFrame = tint
    self:_onTheme(function(th) tint.BackgroundColor3 = th.tint end)
    self._bgTransparency = config.BackgroundTransparency or 0
    local bgSource = config.Background or config.BackgroundUrl
    if bgSource then self:SetBackground(bgSource) end

    -- title bar
    local titleBar = new("Frame", {
        Name = "TitleBar", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1,
        BorderSizePixel = 0, Active = true,
    }, main)
    self._titleLabel = textLabel(titleBar, {
        Size = UDim2.new(0.5, -16, 1, 0), Position = UDim2.fromOffset(16, 0),
        Text = config.Title or "Crimson UI", Font = Enum.Font.GothamBold, TextSize = 14,
    })
    self._statusLabel = textLabel(titleBar, {
        Size = UDim2.new(0.5, -16, 1, 0), Position = UDim2.new(0.5, 0, 0, 0),
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    self._statusIsErr = false
    self:_onTheme(function(th)
        self._titleLabel.TextColor3 = th.text
        self._statusLabel.TextColor3 = self._statusIsErr and th.error or th.textStatus
    end)

    -- tab bar + divider + pages
    self._tabBar = new("ScrollingFrame", {
        Name = "Tabs", Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
    }, main)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center,
    }, self._tabBar)
    padding(self._tabBar, 14, 0, 14, 0)

    local divider = new("Frame", {
        Position = UDim2.fromOffset(14, 68), Size = UDim2.new(1, -28, 0, 1),
        BorderSizePixel = 0, BackgroundTransparency = 0.7,
    }, main)
    self:_onTheme(function(th) divider.BackgroundColor3 = th.accent end)

    self._pages = new("Frame", {
        Name = "Pages", Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 1, -70),
        BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
    }, main)

    -- toast holder
    self._toasts = new("Frame", {
        Name = "Toasts", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16),
        Size = UDim2.new(0, 260, 1, -32), BackgroundTransparency = 1, BorderSizePixel = 0,
    }, gui)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, self._toasts)

    -- dragging the window by its title bar
    self:_makeDraggable(titleBar, holder)

    -- slider dragging (one shared handler per window)
    self:_connect(UserInputService.InputChanged, function(input)
        if self._active and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            self._active.update(input)
        end
    end)
    self:_connect(UserInputService.InputEnded, function(input)
        if self._active and isPress(input) then
            local a = self._active
            self._active = nil
            if a.finish then a.finish() end
        end
    end)

    -- keyboard toggle
    self:_connect(UserInputService.InputBegan, function(input, gpe)
        if not gpe and self.ToggleKey and input.KeyCode == self.ToggleKey then
            self:Toggle()
        end
    end)

    -- floating avatar toggle button (draggable)
    if config.ToggleButton ~= false then
        local toggleHolder = new("Frame", {
            Name = "ToggleHolder", Size = UDim2.fromOffset(58, 58),
            Position = UDim2.new(1, -82, 1, -82), BackgroundTransparency = 1,
            BorderSizePixel = 0, ZIndex = 50,
        }, gui)
        local toggleBtn = new("ImageButton", {
            Name = "AvatarToggle", Size = UDim2.fromOffset(58, 58), AutoButtonColor = false,
            BackgroundTransparency = 0.08, BorderSizePixel = 0, ZIndex = 50,
        }, toggleHolder)
        corner(toggleBtn, 29)
        local tStroke = stroke(toggleBtn, WHITE, 2, 0.25)
        local avatar = new("ImageLabel", {
            Name = "Icon", Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4),
            BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop, ZIndex = 51,
            Image = config.ToggleImage or "",
        }, toggleBtn)
        corner(avatar, 25)
        if not config.ToggleImage and Players.LocalPlayer then
            task.spawn(function()
                local ok, img = pcall(function()
                    return Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId,
                        Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                end)
                if ok and avatar.Parent then avatar.Image = img end
            end)
        end
        local hovering = false
        local function paint(animate)
            local target = hovering and self.Theme.btn or self.Theme.chip
            if animate then tween(toggleBtn, 0.16, { BackgroundColor3 = target })
            else toggleBtn.BackgroundColor3 = target end
            tStroke.Color = self.Theme.accent
            tStroke.Transparency = holder.Visible and 0.25 or 0.7
        end
        self:_onTheme(function() paint(false) end)
        self._refreshToggleBtn = paint -- so Show/Hide/Toggle can repaint it too
        toggleBtn.MouseEnter:Connect(function() hovering = true paint(true) end)
        toggleBtn.MouseLeave:Connect(function() hovering = false paint(true) end)
        self:_makeDraggable(toggleBtn, toggleHolder, function()
            self:Toggle()
            paint(true)
        end)
        self._toggleHolder = toggleHolder
    end

    return self
end

--========================== WINDOW: CORE ==========================
function Window:_connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(self._conns, c)
    return c
end

-- registers a repaint function; returns a subscription that can be removed later
function Window:_onTheme(fn)
    local sub = { fn = fn }
    table.insert(self._themeFns, sub)
    fn(self.Theme)
    return sub
end

function Window:_offTheme(sub)
    local i = table.find(self._themeFns, sub)
    if i then table.remove(self._themeFns, i) end
end

function Window:_makeDraggable(handle, target, onClick)
    local dragging, moved, startInput, startAbs = false, false, nil, nil
    handle.InputBegan:Connect(function(input)
        if dragging or not isPress(input) then return end
        dragging, moved = true, false
        startInput, startAbs = input.Position, target.AbsolutePosition
    end)
    self:_connect(UserInputService.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = input.Position - startInput
        if not moved and d.Magnitude < 5 then return end
        moved = true
        local vp, sz = self.Gui.AbsoluteSize, target.AbsoluteSize
        local x = math.clamp(startAbs.X + d.X, 0, math.max(vp.X - sz.X, 0))
        local y = math.clamp(startAbs.Y + d.Y, 0, math.max(vp.Y - sz.Y, 0))
        target.Position = UDim2.fromOffset(x, y)
    end)
    self:_connect(UserInputService.InputEnded, function(input)
        if dragging and isPress(input) then
            dragging = false
            if not moved and onClick then onClick() end
        end
    end)
end

function Window:SetTheme(theme)
    self.Theme, self.ThemeName = resolveTheme(theme)
    for _, sub in ipairs(self._themeFns) do pcall(sub.fn, self.Theme) end
end

function Window:SetScale(s)
    s = math.clamp(s or 1, 0.5, 2)
    self._scale = s
    self._uiScale.Scale = s
    self.Holder.Size = UDim2.fromOffset(self._baseSize.X * s, self._baseSize.Y * s)
end

function Window:SetTitle(text) self._titleLabel.Text = tostring(text) end

function Window:SetStatus(text, isError)
    self._statusIsErr = isError == true
    self._statusLabel.Text = tostring(text or "")
    self._statusLabel.TextColor3 = self._statusIsErr and self.Theme.error or self.Theme.textStatus
end

-- accepts an rbxassetid / rbxasset url, or an http(s) url (executor downloads it)
function Window:SetBackground(source)
    if not source or source == "" then
        self._bgImage.ImageTransparency = 1
        return true
    end
    if type(source) == "number" then source = "rbxassetid://" .. source end
    source = tostring(source)
    if string.match(source, "^%d+$") then source = "rbxassetid://" .. source end

    local function apply(asset)
        if asset and self._bgImage.Parent then
            self._bgImage.Image = asset
            self._bgImage.ImageTransparency = self._bgTransparency
            return true
        end
        return false
    end

    if string.match(source, "^https?://") then
        task.spawn(function()
            if not apply(Library.ResolveAsset(source, "crimsonui_bg.png")) then
                warn("[CrimsonUI] failed to download background: " .. source)
            end
        end)
        return true
    end
    return apply(source)
end

function Window:SetBackgroundTransparency(v)
    self._bgTransparency = math.clamp(tonumber(v) or 0, 0, 1)
    if self._bgImage.Image ~= "" then
        self._bgImage.ImageTransparency = self._bgTransparency
    end
end

function Window:SetTintTransparency(v)
    self._tintFrame.BackgroundTransparency = math.clamp(tonumber(v) or 0.85, 0, 1)
end

function Window:ClearBackground()
    return self:SetBackground(nil)
end

function Window:Show()
    self.Holder.Visible = true
    if self._refreshToggleBtn then self._refreshToggleBtn(false) end
end

function Window:Hide()
    self.Holder.Visible = false
    if self._refreshToggleBtn then self._refreshToggleBtn(false) end
end

function Window:Toggle()
    self.Holder.Visible = not self.Holder.Visible
    if self._refreshToggleBtn then self._refreshToggleBtn(true) end
end

function Window:IsVisible() return self.Holder.Visible end
function Window:SetToggleKey(keyCode) self.ToggleKey = keyCode end

function Window:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    if self._active then -- restore scroll state if a slider was being dragged
        if self._active.finish then pcall(self._active.finish) end
        self._active = nil
    end
    for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    self._conns = {}
    if self.Gui then self.Gui:Destroy() end
end

function Window:Notify(opts)
    if type(opts) == "string" then opts = { Text = opts } end
    opts = opts or {}
    local th = self.Theme

    -- cap the stack so toasts can't pile up forever
    local frames = {}
    for _, c in ipairs(self._toasts:GetChildren()) do
        if c:IsA("Frame") then table.insert(frames, c) end
    end
    if #frames > 5 then frames[1]:Destroy() end

    self._toastN += 1
    local toast = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = th.panel, BackgroundTransparency = 1, BorderSizePixel = 0,
        LayoutOrder = self._toastN,
    }, self._toasts)
    corner(toast, 10)
    local toastStroke = stroke(toast, opts.Error and th.error or th.accent, 1.5, 1)
    padding(toast, 12, 8, 12, 8)
    new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, toast)
    if opts.Title then
        textLabel(toast, {
            Size = UDim2.new(1, 0, 0, 16), Text = opts.Title, Font = Enum.Font.GothamBold,
            TextColor3 = th.text, TextTransparency = 1, LayoutOrder = 1,
        })
    end
    textLabel(toast, {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
        Text = opts.Text or "", TextColor3 = th.textSub, TextSize = 12, TextTransparency = 1,
        TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2,
    })

    task.defer(function() -- fade in
        if not toast.Parent then return end
        tween(toast, 0.15, { BackgroundTransparency = 0.05 })
        tween(toastStroke, 0.15, { Transparency = 0.3 })
        for _, d in ipairs(toast:GetDescendants()) do
            if d:IsA("TextLabel") then tween(d, 0.15, { TextTransparency = 0 }) end
        end
    end)
    task.delay(opts.Duration or 4, function() -- fade out, then remove
        if not toast.Parent then return end
        tween(toast, 0.2, { BackgroundTransparency = 1 })
        tween(toastStroke, 0.2, { Transparency = 1 })
        for _, d in ipairs(toast:GetDescendants()) do
            if d:IsA("TextLabel") then tween(d, 0.2, { TextTransparency = 1 }) end
        end
        task.wait(0.25)
        if toast.Parent then toast:Destroy() end
    end)
end

--========================== WINDOW: TABS ==========================
function Window:AddTab(name)
    local win = self
    local tab = setmetatable({ Window = win, Name = name, _order = 0 }, Tab)

    local btn = new("TextButton", {
        Name = name, Text = name, AutoButtonColor = false, BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24),
        Font = Enum.Font.GothamBold, TextSize = 12, LayoutOrder = #win._tabs + 1,
    }, win._tabBar)
    corner(btn, 6)
    padding(btn, 12, 0, 12, 0)

    local page = new("ScrollingFrame", {
        Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false,
    }, win._pages)
    new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    padding(page, 14, 8, 14, 12)

    tab.Button, tab.Page = btn, page

    local function refresh(th)
        local active = win._selected == tab
        btn.BackgroundColor3 = active and th.tabActive or th.tabIdle
        btn.BackgroundTransparency = active and 0 or 0.4
        btn.TextColor3 = active and th.text or th.textSub
        page.ScrollBarImageColor3 = th.accent
    end
    tab._refresh = function() refresh(win.Theme) end
    win:_onTheme(refresh)

    btn.MouseButton1Click:Connect(function() win:SelectTab(tab) end)
    table.insert(win._tabs, tab)
    if not win._selected then win:SelectTab(tab) end
    return tab
end

function Window:SelectTab(target)
    if type(target) == "string" then
        for _, t in ipairs(self._tabs) do
            if t.Name == target then target = t break end
        end
    end
    if type(target) ~= "table" then return end
    self._selected = target
    for _, t in ipairs(self._tabs) do
        t.Page.Visible = (t == target)
        t._refresh()
    end
end

function Tab:Select() self.Window:SelectTab(self) end

function Tab:_newElement(height)
    self._order += 1
    return new("Frame", {
        Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1,
        BorderSizePixel = 0, LayoutOrder = self._order,
    }, self.Page)
end

--========================== ELEMENT: LABEL / SECTION / DIVIDER ====
function Tab:AddLabel(text)
    local win = self.Window
    self._order += 1
    local lbl = textLabel(self.Page, {
        Size = UDim2.new(1, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
        Text = tostring(text or ""), TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = self._order,
    })
    local handle = newHandle(win, lbl)
    handle:_watch(function(th) lbl.TextColor3 = th.textSub end)
    function handle:SetText(t) lbl.Text = tostring(t) end
    function handle:GetText() return lbl.Text end
    return handle
end

function Tab:AddSection(text)
    local win = self.Window
    local frame = self:_newElement(22)
    local lbl = textLabel(frame, {
        Size = UDim2.new(1, 0, 0, 18), Text = string.upper(tostring(text or "Section")),
        Font = Enum.Font.GothamBold, TextSize = 11,
    })
    local line = new("Frame", {
        Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0, BackgroundTransparency = 0.6,
    }, frame)
    local handle = newHandle(win, frame)
    handle:_watch(function(th)
        lbl.TextColor3 = th.accent
        line.BackgroundColor3 = th.accent
    end)
    function handle:SetText(t) lbl.Text = string.upper(tostring(t)) end
    return handle
end

function Tab:AddDivider()
    local win = self.Window
    local frame = self:_newElement(6)
    local line = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, BackgroundTransparency = 0.7,
    }, frame)
    local handle = newHandle(win, frame)
    handle:_watch(function(th) line.BackgroundColor3 = th.textSub end)
    return handle
end

--========================== ELEMENT: BUTTON =======================
--[[ opts: Text, Style ("Primary" | "Secondary" | "Active"), Callback, Disabled,
          Toggle (bool), ToggledText, Confirm (bool), ConfirmText, Cooldown (sec), Height ]]
function Window:_buildButton(parent, opts, size)
    local win = self
    local state = {
        style = opts.Style or "Primary", disabled = opts.Disabled == true,
        toggled = false, confirming = false, text = opts.Text or "Button", last = 0,
    }
    local btn = new("TextButton", {
        Size = size, BorderSizePixel = 0, AutoButtonColor = false, Text = state.text,
        Font = Enum.Font.GothamBold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
    corner(btn, 8)
    local scale = new("UIScale", {}, btn)
    local handle = newHandle(win, btn, opts)
    local hovering = false

    local function colors()
        local t = win.Theme
        if state.disabled then return t.busy, t.busy, t.busyText end
        local style = state.toggled and "Active" or state.style
        if style == "Active" then return t.btnActive, t.btnActiveHover, t.btnText end
        if style == "Secondary" then return t.chip, t.btn, t.btnText end
        return t.btn, t.btnHover, t.btnText
    end
    local function refresh(animate)
        local rest, hover, txt = colors()
        local target = hovering and hover or rest
        btn.TextColor3 = txt
        if animate then tween(btn, 0.14, { BackgroundColor3 = target }) else btn.BackgroundColor3 = target end
    end
    local function renderText()
        if state.confirming then
            btn.Text = opts.ConfirmText or "Click again to confirm"
        elseif state.toggled and opts.ToggledText then
            btn.Text = opts.ToggledText
        else
            btn.Text = state.text
        end
    end
    handle:_watch(function() refresh(false) end)

    local function press()
        if state.disabled then return end
        if opts.Cooldown and os.clock() - state.last < opts.Cooldown then return end
        if opts.Confirm and not state.confirming then
            state.confirming = true
            renderText()
            task.delay(2, function()
                if state.confirming then state.confirming = false renderText() end
            end)
            return
        end
        state.confirming = false
        state.last = os.clock()
        if opts.Toggle then state.toggled = not state.toggled refresh(true) end
        renderText()
        if opts.Toggle then fire(opts.Callback, state.toggled, handle)
        else fire(opts.Callback, handle) end
    end

    btn.MouseEnter:Connect(function() hovering = true refresh(true) end)
    btn.MouseLeave:Connect(function()
        hovering = false
        refresh(true)
        tween(scale, 0.1, { Scale = 1 })
    end)
    btn.MouseButton1Down:Connect(function()
        if not state.disabled then tween(scale, 0.08, { Scale = 0.96 }) end
    end)
    btn.MouseButton1Up:Connect(function() tween(scale, 0.1, { Scale = 1 }) end)
    btn.MouseButton1Click:Connect(press)

    function handle:SetText(t) state.text = tostring(t) renderText() end
    function handle:SetStyle(s) state.style = s refresh(true) end
    function handle:SetDisabled(d) state.disabled = d == true refresh(true) end
    function handle:GetToggled() return state.toggled end
    function handle:SetToggled(v, silent)
        state.toggled = v == true
        refresh(true)
        renderText()
        if not silent then fire(opts.Callback, state.toggled, handle) end
    end
    function handle:Fire() press() end
    return handle
end

function Tab:AddButton(opts)
    if type(opts) == "string" then opts = { Text = opts } end
    opts = opts or {}
    local frame = self:_newElement(opts.Height or 34)
    local handle = self.Window:_buildButton(frame, opts, UDim2.fromScale(1, 1))
    handle.Frame = frame -- hiding/destroying removes the whole row
    return handle
end

-- Tab:AddButtonRow({ {Text="A"}, {Text="B"} }) -> array of button handles
function Tab:AddButtonRow(list, height)
    list = list or {}
    local gap, n = 8, #list
    if n == 0 then return {} end -- empty row would crash on 1/n
    local frame = self:_newElement(height or 34)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, gap),
        SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center,
    }, frame)
    local handles = {}
    for i, o in ipairs(list) do
        if type(o) == "string" then o = { Text = o } end
        local h = self.Window:_buildButton(frame, o, UDim2.new(1 / n, -gap * (n - 1) / n, 1, 0))
        h.Frame.LayoutOrder = i
        handles[i] = h
    end
    return handles, frame
end

--========================== ELEMENT: TOGGLE =======================
--[[ opts: Name, Default, Callback(value), Flag ]]
function Tab:AddToggle(opts)
    opts = opts or {}
    local win, flag = self.Window, opts.Flag
    local frame = self:_newElement(30)
    local lbl = textLabel(frame, { Size = UDim2.new(1, -54, 1, 0), Text = opts.Name or "Toggle" })
    local track = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(42, 22), BorderSizePixel = 0,
    }, frame)
    corner(track, 11)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2,
    }, track)
    corner(knob, 8)
    local click = new("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 3,
    }, frame)

    local value = opts.Default == true
    local handle = newHandle(win, frame, opts)

    local function render(animate)
        local col = value and win.Theme.accent or win.Theme.track
        local pos = value and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        if animate then
            tween(track, 0.12, { BackgroundColor3 = col })
            tween(knob, 0.12, { Position = pos })
        else
            track.BackgroundColor3, knob.Position = col, pos
        end
    end
    handle:_watch(function(th)
        lbl.TextColor3 = th.textSub
        render(false)
    end)

    function handle:Set(v, silent)
        value = v == true
        render(true)
        if flag then win.Flags[flag] = value end
        if not silent then fire(opts.Callback, value) end
    end
    function handle:Get() return value end
    function handle:SetText(t) lbl.Text = tostring(t) end
    handle._serialize = function() return value end
    handle._deserialize = function(v) handle:Set(v == true) end

    click.MouseButton1Click:Connect(function() handle:Set(not value) end)
    win:_register(flag, handle, value)
    return handle
end

--========================== ELEMENT: SLIDER =======================
--[[ opts: Name, Min, Max, Step, Default, Decimals, Suffix, Callback(value), Flag ]]
function Tab:AddSlider(opts)
    opts = opts or {}
    local win, flag, page = self.Window, opts.Flag, self.Page
    local minV = tonumber(opts.Min) or 0
    local maxV = tonumber(opts.Max) or 100
    if minV > maxV then minV, maxV = maxV, minV end -- swapped range broke the math
    local step = tonumber(opts.Step) or 1
    if step <= 0 then step = 1 end                  -- step 0 = division by zero
    local decimals = math.clamp(tonumber(opts.Decimals) or (step < 1 and 2 or 0), 0, 6)
    local suffix = opts.Suffix or ""

    local frame = self:_newElement(40)
    local nameLbl = textLabel(frame, { Size = UDim2.new(0.6, 0, 0, 16), Text = opts.Name or "Slider" })
    local valLbl = textLabel(frame, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(90, 16),
        TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamBold, TextSize = 13,
    })
    local hit = new("Frame", {
        Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
    }, frame)
    local track = new("Frame", {
        Position = UDim2.new(0, 0, 0.5, -3), Size = UDim2.new(1, 0, 0, 6),
        BorderSizePixel = 0, BackgroundTransparency = 0.2,
    }, hit)
    corner(track, 3)
    local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, track)
    corner(fill, 3)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2,
    }, track)
    corner(knob, 7)
    local knobStroke = stroke(knob, WHITE, 2, 0)

    local function snap(v)
        return math.clamp(math.floor((v - minV) / step + 0.5) * step + minV, minV, maxV)
    end
    local value = snap(opts.Default or minV)
    local handle = newHandle(win, frame, opts)

    local function render()
        local range = maxV - minV
        local a = range > 0 and (value - minV) / range or 0
        fill.Size = UDim2.fromScale(a, 1)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        valLbl.Text = string.format("%." .. decimals .. "f", value) .. suffix
    end
    handle:_watch(function(th)
        nameLbl.TextColor3 = th.textSub
        valLbl.TextColor3 = th.text
        track.BackgroundColor3 = th.track
        fill.BackgroundColor3 = th.accent
        knobStroke.Color = th.accent
    end)
    render()

    function handle:Set(v, silent)
        value = snap(tonumber(v) or value)
        render()
        if flag then win.Flags[flag] = value end
        if not silent then fire(opts.Callback, value) end
    end
    function handle:Get() return value end
    function handle:SetText(t) nameLbl.Text = tostring(t) end
    handle._serialize = function() return value end
    handle._deserialize = function(v) handle:Set(v) end

    local function update(input)
        local a = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local nv = snap(minV + (maxV - minV) * a)
        if nv ~= value then handle:Set(nv) end
    end
    local function begin(input)
        if not isPress(input) then return end
        page.ScrollingEnabled = false
        win._active = {
            update = update,
            finish = function()
                if page.Parent then page.ScrollingEnabled = true end
            end,
        }
        update(input)
    end
    hit.InputBegan:Connect(begin)
    track.InputBegan:Connect(begin)
    knob.InputBegan:Connect(begin)

    win:_register(flag, handle, value)
    return handle
end

--========================== ELEMENT: TEXTBOX ======================
--[[ opts: Name, Default, Placeholder, ClearOnFocus, Numeric, Callback(value, enterPressed), Flag ]]
function Tab:AddTextbox(opts)
    opts = opts or {}
    local win, flag = self.Window, opts.Flag
    local frame = self:_newElement(32)
    local lbl = textLabel(frame, { Size = UDim2.new(0.4, 0, 1, 0), Text = opts.Name or "Textbox" })
    local box = new("TextBox", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.58, 0, 1, 0),
        BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 13, ClipsDescendants = true,
        ClearTextOnFocus = opts.ClearOnFocus == true, PlaceholderText = opts.Placeholder or "",
        Text = tostring(opts.Default or ""), TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)
    corner(box, 8)
    padding(box, 8, 0, 8, 0)

    -- numeric box with missing/invalid default no longer falls back to a string
    local value
    if opts.Numeric then
        value = tonumber(opts.Default) or 0
    else
        value = tostring(opts.Default or "")
    end
    local handle = newHandle(win, frame, opts)
    handle:_watch(function(th)
        lbl.TextColor3 = th.textSub
        box.BackgroundColor3 = th.chip
        box.TextColor3 = th.text
        box.PlaceholderColor3 = th.textSub
    end)

    function handle:Set(v, silent)
        if opts.Numeric then
            v = tonumber(v)
            if v == nil then return end
            box.Text = tostring(v)
        else
            v = tostring(v)
            box.Text = v
        end
        value = v
        if flag then win.Flags[flag] = value end
        if not silent then fire(opts.Callback, value, false) end
    end
    function handle:Get() return value end
    function handle:SetText(t) lbl.Text = tostring(t) end
    handle._serialize = function() return value end
    handle._deserialize = function(v) handle:Set(v) end

    box.FocusLost:Connect(function(enter)
        if opts.Numeric then
            local n = tonumber(box.Text)
            if n == nil then box.Text = tostring(value) return end
            value = n
            box.Text = tostring(n)
        else
            value = box.Text
        end
        if flag then win.Flags[flag] = value end
        fire(opts.Callback, value, enter)
    end)

    win:_register(flag, handle, value)
    return handle
end

--========================== ELEMENT: DROPDOWN =====================
--[[ opts: Name, Options = {..}, Default (string, or array when Multi), Multi, MaxVisible,
          Callback(value), Flag ]]
function Tab:AddDropdown(opts)
    opts = opts or {}
    local win, flag = self.Window, opts.Flag
    local multi = opts.Multi == true
    local maxVisible = math.max(tonumber(opts.MaxVisible) or 5, 1)
    local options = table.clone(opts.Options or {})
    local single, selected, open = nil, {}, false

    local frame = self:_newElement(32)
    frame.ClipsDescendants = true
    local header = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 32), Text = "", AutoButtonColor = false, BorderSizePixel = 0,
    }, frame)
    corner(header, 8)
    local nameLbl = textLabel(header, {
        Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.45, -10, 1, 0), Text = opts.Name or "Dropdown",
    })
    local valLbl = textLabel(header, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -26, 0, 0), Size = UDim2.new(0.55, -30, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamBold,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local arrow = textLabel(header, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.fromOffset(14, 32),
        Text = "v", Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center,
    })
    local list = new("ScrollingFrame", {
        Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, frame)
    new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)

    local handle = newHandle(win, frame, opts)
    local buttons = {}

    local function listHeight()
        return math.max(math.min(#options, maxVisible) * 28 - 2, 0)
    end
    local function display()
        if multi then
            local names = {}
            for _, o in ipairs(options) do if selected[o] then table.insert(names, o) end end
            return #names > 0 and table.concat(names, ", ") or "None"
        end
        return single or "None"
    end
    local function paint()
        local th = win.Theme
        nameLbl.TextColor3, valLbl.TextColor3, arrow.TextColor3 = th.textSub, th.text, th.accent
        header.BackgroundColor3 = th.chip
        list.ScrollBarImageColor3 = th.accent
        for o, b in pairs(buttons) do
            local on = multi and selected[o] or (not multi and single == o)
            b.BackgroundColor3 = on and th.btnActive or th.track
            b.TextColor3 = on and th.text or th.textSub
        end
        valLbl.Text = display()
    end
    handle:_watch(paint)

    local function value()
        if multi then
            local out = {}
            for _, o in ipairs(options) do if selected[o] then table.insert(out, o) end end
            return out
        end
        return single
    end
    local function commit(silent)
        paint()
        if flag then win.Flags[flag] = value() end
        if not silent then fire(opts.Callback, value()) end
    end
    local function setOpen(o)
        open = o
        arrow.Text = o and "^" or "v"
        local h = o and (36 + listHeight()) or 32
        tween(frame, 0.15, { Size = UDim2.new(1, 0, 0, h) })
        list.Size = UDim2.new(1, 0, 0, listHeight())
    end

    local function rebuild()
        for _, b in pairs(buttons) do b:Destroy() end
        buttons = {}
        for i, o in ipairs(options) do
            local b = new("TextButton", {
                Size = UDim2.new(1, -6, 0, 26), Text = tostring(o), AutoButtonColor = false,
                BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 12, LayoutOrder = i,
            }, list)
            corner(b, 6)
            b.MouseButton1Click:Connect(function()
                if multi then
                    selected[o] = not selected[o] or nil
                else
                    single = o
                    setOpen(false)
                end
                commit(false)
            end)
            buttons[o] = b
        end
        paint()
        if open then setOpen(true) end
    end

    -- defaults
    if multi then
        for _, o in ipairs(opts.Default or {}) do selected[o] = true end
    else
        single = opts.Default
    end
    rebuild()

    function handle:Get() return value() end
    function handle:SetText(t) nameLbl.Text = tostring(t) end
    function handle:Set(v, silent)
        if multi then
            selected = {}
            for _, o in ipairs(type(v) == "table" and v or {}) do selected[o] = true end
        else
            single = v
        end
        commit(silent)
    end
    function handle:SetOptions(list2)
        options = table.clone(list2 or {})
        if multi then
            for o in pairs(selected) do if not table.find(options, o) then selected[o] = nil end end
        elseif single ~= nil and not table.find(options, single) then
            single = nil
        end
        rebuild()
        if flag then win.Flags[flag] = value() end
    end
    handle._serialize = function() return value() end
    handle._deserialize = function(v) handle:Set(v) end

    header.MouseButton1Click:Connect(function() setOpen(not open) end)
    win:_register(flag, handle, value())
    return handle
end

--========================== ELEMENT: KEYBIND ======================
--[[ opts: Name, Default (Enum.KeyCode), Callback(key) on press, ChangedCallback(key), Flag ]]
function Tab:AddKeybind(opts)
    opts = opts or {}
    local win, flag = self.Window, opts.Flag
    local frame = self:_newElement(30)
    local lbl = textLabel(frame, { Size = UDim2.new(1, -110, 1, 0), Text = opts.Name or "Keybind" })
    local btn = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(100, 24),
        AutoButtonColor = false, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 12,
    }, frame)
    corner(btn, 6)

    local key, listening = opts.Default, false
    local handle = newHandle(win, frame, opts)

    local function render()
        btn.Text = listening and "..." or (key and key.Name or "None")
    end
    handle:_watch(function(th)
        lbl.TextColor3 = th.textSub
        btn.BackgroundColor3 = th.chip
        btn.TextColor3 = th.text
        render()
    end)

    function handle:Set(v, silent)
        if type(v) == "string" then
            local ok, k = pcall(function() return Enum.KeyCode[v] end)
            v = ok and k or nil
        end
        key = v
        render()
        if flag then win.Flags[flag] = key end
        if not silent then fire(opts.ChangedCallback, key) end
    end
    function handle:Get() return key end
    function handle:SetText(t) lbl.Text = tostring(t) end
    handle._serialize = function() return key and key.Name or nil end
    handle._deserialize = function(v) handle:Set(v) end

    btn.MouseButton1Click:Connect(function()
        listening = true
        render()
    end)
    -- scoped to the element (used to leak on the window after Destroy)
    handle:_connect(UserInputService.InputBegan, function(input, gpe)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                handle:Set(input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode or nil)
            elseif isPress(input) then
                listening = false -- clicking away no longer leaves it stuck in "..."
                render()
            end
            return
        end
        if key and not gpe and input.KeyCode == key then fire(opts.Callback, key) end
    end)

    render()
    win:_register(flag, handle, key)
    return handle
end

--========================== CONFIGS ===============================
function Window:ExportConfig()
    local data = {}
    for flag, el in pairs(self.Elements) do
        if el._serialize then
            local ok, v = pcall(el._serialize)
            if ok then data[flag] = v end
        end
    end
    return HttpService:JSONEncode(data)
end

function Window:ImportConfig(json)
    local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
    if not ok or type(data) ~= "table" then return false, "invalid config data" end
    for flag, v in pairs(data) do
        local el = self.Elements[flag]
        if el and el._deserialize then pcall(el._deserialize, v) end
    end
    return true
end

local function cfgPath(name) return Library.Folder .. "/" .. name .. ".json" end

function Window:SaveConfig(name)
    if not hasFS() then return false, "file functions unavailable in this environment" end
    name = cleanName(name)
    if name == "" then return false, "invalid config name" end
    ensureFolder(Library.Folder)
    return pcall(writefile, cfgPath(name), self:ExportConfig())
end

function Window:LoadConfig(name)
    if not hasFS() then return false, "file functions unavailable in this environment" end
    name = cleanName(name)
    if type(isfile) == "function" and not isfile(cfgPath(name)) then return false, "config not found" end
    local ok, data = pcall(readfile, cfgPath(name))
    if not ok then return false, "could not read config" end
    return self:ImportConfig(data)
end

function Window:DeleteConfig(name)
    if type(delfile) ~= "function" then return false, "delfile unavailable" end
    return pcall(delfile, cfgPath(cleanName(name)))
end

function Window:ListConfigs()
    local out = {}
    if type(listfiles) == "function" and type(isfolder) == "function" and isfolder(Library.Folder) then
        local ok, files = pcall(listfiles, Library.Folder)
        if ok then
            for _, path in ipairs(files) do
                local n = string.match(path, "([^/\\]+)%.json$")
                if n then table.insert(out, n) end
            end
        end
    end
    table.sort(out)
    return out
end

-- Ready-made settings tab: theme, UI scale, background, toggle key, config manager, unload
function Window:AddSettingsTab(name)
    local win = self
    local tab = self:AddTab(name or "Settings")

    tab:AddSection("Interface")
    local themeNames = {}
    for k in pairs(Library.Themes) do table.insert(themeNames, k) end
    table.sort(themeNames)
    tab:AddDropdown({
        Name = "Theme", Options = themeNames, Default = self.ThemeName,
        Callback = function(v) win:SetTheme(v) end,
    })
    tab:AddSlider({
        Name = "UI Scale", Min = 0.6, Max = 1.6, Step = 0.05, Decimals = 2, Default = self._scale,
        Callback = function(v) win:SetScale(v) end,
    })
    tab:AddKeybind({
        Name = "Toggle Key", Default = self.ToggleKey,
        ChangedCallback = function(k) win.ToggleKey = k end,
    })

    -- live background image controls
    tab:AddSection("Background")
    local bgBox = tab:AddTextbox({
        Name = "Image", Placeholder = "rbxassetid://… or https://…",
    })
    tab:AddSlider({
        Name = "Image Transparency", Min = 0, Max = 1, Step = 0.05, Decimals = 2,
        Default = win._bgTransparency,
        Callback = function(v) win:SetBackgroundTransparency(v) end,
    })
    tab:AddSlider({
        Name = "Background Tint", Min = 0, Max = 1, Step = 0.05, Decimals = 2,
        Default = win._tintFrame.BackgroundTransparency,
        Callback = function(v) win:SetTintTransparency(v) end,
    })
    tab:AddButtonRow({
        { Text = "Apply", Callback = function()
            local ok = win:SetBackground(bgBox:Get())
            win:Notify({
                Title = "Background",
                Text = ok and "Applied." or "Could not use that image source.",
                Error = not ok,
            })
        end },
        { Text = "Clear", Style = "Secondary", Callback = function()
            win:ClearBackground()
            bgBox:Set("", true)
        end },
    })

    tab:AddSection("Configs")
    local nameBox = tab:AddTextbox({ Name = "Config name", Default = "default" })
    local saved = tab:AddDropdown({
        Name = "Saved", Options = self:ListConfigs(),
        Callback = function(v) if v then nameBox:Set(v, true) end end,
    })
    tab:AddButtonRow({
        { Text = "Save", Callback = function()
            local ok, err = win:SaveConfig(nameBox:Get())
            win:Notify({ Title = "Config", Text = ok and "Saved." or tostring(err), Error = not ok })
            saved:SetOptions(win:ListConfigs())
        end },
        { Text = "Load", Callback = function()
            local ok, err = win:LoadConfig(nameBox:Get())
            win:Notify({ Title = "Config", Text = ok and "Loaded." or tostring(err), Error = not ok })
        end },
        { Text = "Refresh", Style = "Secondary", Callback = function()
            saved:SetOptions(win:ListConfigs())
        end },
    })

    tab:AddSection("Danger zone")
    tab:AddButton({ Text = "Unload UI", Confirm = true, Callback = function() win:Destroy() end })
    return tab
end

return Library
