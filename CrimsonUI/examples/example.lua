-- Replace the URL with your own raw GitHub link
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/CrimsonUI/main/CrimsonUI.lua"))()

local Window = Library.new({
	Title = "My Hub",
	Theme = "Crimson",
	ToggleKey = Enum.KeyCode.RightShift,
})

local Main = Window:AddTab("Main")
Main:AddSection("Buttons")
Main:AddButton({ Text = "Hello", Callback = function() Window:Notify({ Title = "Hi", Text = "Button clicked" }) end })
Main:AddButton({ Text = "Toggle me", Toggle = true, ToggledText = "ON", Callback = function(on) print("toggled", on) end })
Main:AddButton({ Text = "Dangerous", Confirm = true, Cooldown = 3, Callback = function() print("confirmed") end })

Main:AddSection("Controls")
Main:AddToggle({ Name = "Enabled", Flag = "enabled", Default = true })
Main:AddSlider({ Name = "Speed", Flag = "speed", Min = 0, Max = 100, Default = 16, Suffix = " studs" })
Main:AddTextbox({ Name = "Name", Flag = "name", Placeholder = "type here" })
Main:AddDropdown({ Name = "Mode", Flag = "mode", Options = { "Easy", "Normal", "Hard" }, Default = "Normal" })
Main:AddDropdown({ Name = "Targets", Flag = "targets", Options = { "A", "B", "C" }, Multi = true })
Main:AddKeybind({ Name = "Action", Flag = "action", Default = Enum.KeyCode.E, Callback = function() print("pressed") end })

Window:AddSettingsTab()
