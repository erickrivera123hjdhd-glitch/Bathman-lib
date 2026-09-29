# Crimson UI

A small, themeable Roblox GUI library for client-side / executor use.

**Elements:** Button (toggle / confirm / cooldown), Button rows, Toggle, Slider, Textbox, Dropdown (single + multi), Keybind, Label, Section, Divider
**Extras:** Tabs, live theme switching, toasts, draggable avatar toggle, config save/load via flags, UI scale, optional background image

## Quick start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/CrimsonUI/main/CrimsonUI.lua"))()

local Window = Library.new({ Title = "My Hub" })
local Tab    = Window:AddTab("Main")

Tab:AddButton({ Text = "Hello", Callback = function() print("hi") end })
Window:AddSettingsTab()
```

See [`examples/example.lua`](examples/example.lua) for a fuller demo.

## Window options (`Library.new`)

| Option | Description |
|---|---|
| `Title` | Title bar text |
| `Name` | ScreenGui name (default `"CrimsonUI"`) |
| `Theme` | Theme name (`Crimson`, `Midnight`, `Emerald`, `Mono`) or a custom theme table |
| `Size` | `Vector2`, default `420x320` |
| `Scale` | UI scale, default `1` |
| `ToggleKey` | `Enum.KeyCode` to show/hide the window |
| `ToggleButton` | `false` to hide the floating avatar button |
| `ToggleImage` | Custom image for the avatar button |
| `BackgroundUrl` | Image URL or asset id for the panel background |
| `Transparency`, `TintTransparency`, `BackgroundTransparency` | Look tuning |
| `Parent` | Override where the GUI is parented |

## Window methods

`AddTab`, `SelectTab`, `AddSettingsTab`, `SetTheme`, `SetScale`, `SetTitle`, `SetStatus(text, isError)`, `SetBackground`, `Notify({Title, Text, Duration, Error})`, `Show`, `Hide`, `Toggle`, `IsVisible`, `SetToggleKey`, `Destroy`

Config: `SaveConfig`, `LoadConfig`, `DeleteConfig`, `ListConfigs`, `ExportConfig`, `ImportConfig`

## Elements

All elements return a handle with `SetVisible`, `SetCallback` and `Destroy`. Elements that pass a `Flag` are stored in `Window.Flags[flag]` and included in saved configs.

| Method | Key options | Handle |
|---|---|---|
| `Tab:AddButton` | `Text, Style, Callback, Disabled, Toggle, ToggledText, Confirm, ConfirmText, Cooldown, Height` | `SetText, SetStyle, SetDisabled, GetToggled, SetToggled, Fire` |
| `Tab:AddButtonRow(list)` | array of button option tables | array of handles |
| `Tab:AddToggle` | `Name, Default, Callback, Flag` | `Set, Get` |
| `Tab:AddSlider` | `Name, Min, Max, Step, Default, Decimals, Suffix, Callback, Flag` | `Set, Get` |
| `Tab:AddTextbox` | `Name, Default, Placeholder, ClearOnFocus, Numeric, Callback, Flag` | `Set, Get` |
| `Tab:AddDropdown` | `Name, Options, Default, Multi, MaxVisible, Callback, Flag` | `Set, Get, SetOptions` |
| `Tab:AddKeybind` | `Name, Default, Callback, ChangedCallback, Flag` | `Set, Get` |
| `Tab:AddLabel` / `AddSection` / `AddDivider` | text | `SetText` |

## Custom themes

```lua
local theme = Library.MakeTheme({
	panel = Color3.fromRGB(20, 20, 30), tint = Color3.fromRGB(5, 5, 10),
	btn = Color3.fromRGB(120, 60, 200), btnHover = Color3.fromRGB(150, 90, 230),
	btnActive = Color3.fromRGB(80, 30, 150), btnActiveHover = Color3.fromRGB(100, 50, 180),
	busy = Color3.fromRGB(50, 50, 60), accent = Color3.fromRGB(170, 110, 255),
	track = Color3.fromRGB(30, 30, 44), chip = Color3.fromRGB(24, 24, 36),
})
Window:SetTheme(theme)
```

## Notes

- Config saving and background image download need executor file functions (`writefile`, `readfile`, `getcustomasset`). Without them the UI still works; those features just report unavailable.
- Configs are saved to the `CrimsonUI/` workspace folder (change with `Library.Folder`).

## License

MIT, see [LICENSE](LICENSE).
