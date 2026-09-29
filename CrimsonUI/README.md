# CrimsonUI

A lightweight, themeable Roblox UI library built for clean and responsive interfaces.

CrimsonUI provides a simple API for creating polished menus with tabs, controls, notifications, themes, keybinds, and configuration support.

## Features

### Elements

* Buttons
* Button rows
* Toggles
* Sliders
* Textboxes
* Single-select dropdowns
* Multi-select dropdowns
* Keybinds
* Labels
* Sections
* Dividers

### Library Features

* Multiple built-in themes
* Custom themes
* Live theme switching
* Tabs
* Animated notifications
* Draggable toggle button
* UI scaling
* Config save/load
* Config export/import
* Element flags
* Runtime UI controls

## Quick Start

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YOUR_USER/CrimsonUI/main/CrimsonUI.lua"
))()

local Window = Library.new({
    Title = "My Hub"
})

local Main = Window:AddTab("Main")

Main:AddButton({
    Text = "Hello",
    Callback = function()
        print("Hello from CrimsonUI")
    end
})

Window:AddSettingsTab()
```

For a complete example, see [`examples/example.lua`](examples/example.lua).

## Built-in Themes

CrimsonUI includes several ready-to-use themes:

* `Crimson`
* `Midnight`
* `Emerald`
* `Mono`

Themes can be changed while the UI is running.

```lua
Window:SetTheme("Midnight")
```

Custom themes are also supported through `Library.MakeTheme()`.

## Configuration

Elements can use flags to automatically include their values in configurations.

```lua
Main:AddToggle({
    Name = "Auto Farm",
    Flag = "AutoFarm",
    Default = false,

    Callback = function(Value)
        print(Value)
    end
})
```

Available configuration methods:

```lua
Window:SaveConfig()
Window:LoadConfig()
Window:DeleteConfig()
Window:ListConfigs()
Window:ExportConfig()
Window:ImportConfig()
```

## Example

```lua
local Main = Window:AddTab("Main")

Main:AddSection("Player")

Main:AddSlider({
    Name = "WalkSpeed",
    Flag = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,

    Callback = function(Value)
        print("WalkSpeed:", Value)
    end
})

Main:AddToggle({
    Name = "Infinite Jump",
    Flag = "InfiniteJump",
    Default = false,

    Callback = function(Value)
        print("Infinite Jump:", Value)
    end
})
```

## Project Structure

```text
CrimsonUI/
├── CrimsonUI.lua
├── README.md
├── LICENSE
└── examples/
    └── example.lua
```

## Requirements

CrimsonUI is designed to work without requiring external UI frameworks.

Configuration features use the executor's file functions when available:

* `writefile`
* `readfile`
* `isfile`
* `makefolder`

The core UI does not depend on configuration functionality.
