Crimson UI

A small, themeable Roblox GUI library for client-side / executor use.

Elements: Button (toggle / confirm / cooldown), Button rows, Toggle, Slider, Textbox, Dropdown (single + multi), Keybind, Label, Section, DividerExtras: Tabs, live theme switching, fading toasts, draggable avatar toggle, config save/load via flags, UI scale, background images

Quick start

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/CrimsonUI/main/CrimsonUI.lua"))()local Window = Library.new({ Title = "My Hub" })local Tab    = Window:AddTab("Main")Tab:AddButton({ Text = "Hello", Callback = function() print("hi") end })Window:AddSettingsTab()
See examples/example.lua for a fuller demo.

Window options (Library.new)

Option	Description
Title	Title bar text
Name	ScreenGui name (default "CrimsonUI")
Theme	Theme name (Crimson, Midnight, Emerald, Mono) or a custom theme table
Size	Vector2, default 420x320
Scale	UI scale, default 1
ToggleKey	Enum.KeyCode to show/hide the window
ToggleButton	false to hide the floating avatar button
ToggleImage	Custom image for the avatar button
StartHidden	true to open with the window hidden (avatar button still works)
BackgroundUrl / Background	Background image: "rbxassetid://123", a bare id number, or an https:// image link
BackgroundTransparency	Background image transparency, 0 (solid) - 1 (hidden), default 0
TintTransparency	Dark overlay strength over the background, default 0.85
Transparency	Panel transparency, default 0.15
Parent	Override where the GUI is parented
Background images

-- at creationlocal Window = Library.new({    Title = "My Hub",    BackgroundUrl = "https://i.imgur.com/xxxxx.png", -- direct image link    BackgroundTransparency = 0.2,})-- or any time laterWindow:SetBackground("rbxassetid://123456")   -- decal/image id, loads instantlyWindow:SetBackground(123456)                  -- bare id also worksWindow:SetBackground("https://i.imgur.com/x.png")Window:SetBackgroundTransparency(0.5)Window:SetTintTransparency(0.7)Window:ClearBackground()
rbxassetid sources work everywhere and need no download.
http(s) links are downloaded via Library.ResolveAsset(url, "crimsonui_bg.png") (game:HttpGet -> writefile -> getcustomasset) and require an executor with those functions; failures warn in the console.
Use a direct image link (https://i.imgur.com/abc.png), not a page link (https://imgur.com/abc).
SetBackground returns true/false for whether the source was accepted.
The Settings tab has a Background section to set/clear the image and tune transparency/tint live.
Window methods

AddTab, SelectTab, AddSettingsTab, SetTheme, SetScale, SetTitle, SetStatus(text, isError), SetBackground(source), SetBackgroundTransparency, SetTintTransparency, ClearBackground, Notify({Title, Text, Duration, Error}), Show, Hide, Toggle, IsVisible, SetToggleKey, Destroy

Config: SaveConfig, LoadConfig, DeleteConfig, ListConfigs, ExportConfig, ImportConfig

Elements

All elements return a handle with SetVisible, SetCallback, SetText and Destroy. Elements that pass a Flag are stored in Window.Flags[flag] and included in saved configs.

Method	Key options	Handle
Tab:AddButton	Text, Style, Callback, Disabled, Toggle, ToggledText, Confirm, ConfirmText, Cooldown, Height	SetText, SetStyle, SetDisabled, GetToggled, SetToggled, Fire
Tab:AddButtonRow(list)	array of button option tables (empty lists are safe)	array of handles
Tab:AddToggle	Name, Default, Callback, Flag	Set, Get, SetText
Tab:AddSlider	Name, Min, Max, Step, Default, Decimals, Suffix, Callback, Flag	Set, Get, SetText
Tab:AddTextbox	Name, Default, Placeholder, ClearOnFocus, Numeric, Callback, Flag	Set, Get, SetText
Tab:AddDropdown	Name, Options, Default, Multi, MaxVisible, Callback, Flag	Set, Get, SetText, SetOptions
Tab:AddKeybind	Name, Default, Callback, ChangedCallback, Flag	Set, Get, SetText
Tab:AddLabel / AddSection / AddDivider	text	SetText
Custom themes

local theme = Library.MakeTheme({    panel = Color3.fromRGB(20, 20, 30), tint = Color3.fromRGB(5, 5, 10),    btn = Color3.fromRGB(120, 60, 200), btnHover = Color3.fromRGB(150, 90, 230),    btnActive = Color3.fromRGB(80, 30, 150), btnActiveHover = Color3.fromRGB(100, 50, 180),    busy = Color3.fromRGB(50, 50, 60), accent = Color3.fromRGB(170, 110, 255),    track = Color3.fromRGB(30, 30, 44), chip = Color3.fromRGB(24, 24, 36),})Window:SetTheme(theme)
Notes

Background image downloads need writefile + getcustomasset and are saved as crimsonui_bg.png in the workspace root. Config saving needs writefile/readfile. Without those the UI still works; those features just report unavailable (rbxassetid backgrounds always work).
Configs are saved to the CrimsonUI/ workspace folder (change with Library.Folder).
Keybind capture cancels if you click away instead of pressing a key.
Toasts fade in/out and cap at 5 on screen.
