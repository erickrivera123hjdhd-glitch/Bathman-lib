--[[
    Player Hub — example script for Crimson UI
]]

--========================== CONFIG =========================
local CONFIG = {
    -- Background image served straight from the repo (works in the UK, no imgur)
    -- Format: https://raw.githubusercontent.com/USER/REPO/refs/heads/BRANCH/path/to/image.png
    BACKGROUND_URL = "https://raw.githubusercontent.com/erickrivera123hjdhd-glitch/Bathman-lib/refs/heads/Main/CrimsonUI/IMG_1736%202.png",
    BACKGROUND_TRANSPARENCY = 0.15, -- 0 = solid image, 1 = invisible
    TINT_TRANSPARENCY = 0.8,        -- dark overlay over the image (lower = darker)

    TITLE = "Player Hub",
    THEME = "Crimson",
    TOGGLE_KEY = Enum.KeyCode.RightShift,
}
--===========================================================

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/erickrivera123hjdhd-glitch/Bathman-lib/refs/heads/Main/CrimsonUI/CrimsonUI.lua"
))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local DEFAULT_WALKSPEED = 16
local DEFAULT_JUMPPOWER = 50

local WalkSpeed = DEFAULT_WALKSPEED
local JumpPower = DEFAULT_JUMPPOWER
local InfiniteJump = false

local Window = Library.new({
    Title = CONFIG.TITLE,
    Theme = CONFIG.THEME,
    ToggleKey = CONFIG.TOGGLE_KEY,

    BackgroundUrl = CONFIG.BACKGROUND_URL,
    BackgroundTransparency = CONFIG.BACKGROUND_TRANSPARENCY,
    TintTransparency = CONFIG.TINT_TRANSPARENCY,
})

-- You can also swap the background at any time:
-- Window:SetBackground("rbxassetid://123456")
-- Window:SetBackground(CONFIG.BACKGROUND_URL)
-- Window:ClearBackground()

local Main = Window:AddTab("Main")

local function getHumanoid()
    local Character = Player.Character

    if not Character then
        return nil
    end

    return Character:FindFirstChildOfClass("Humanoid")
end

local function applyMovement()
    local Humanoid = getHumanoid()

    if not Humanoid then
        return
    end

    Humanoid.WalkSpeed = WalkSpeed
    Humanoid.UseJumpPower = true
    Humanoid.JumpPower = JumpPower
end

Main:AddSection("Movement")

local WalkSpeedSlider = Main:AddSlider({
    Name = "WalkSpeed",
    Flag = "walkspeed",
    Min = 0,
    Max = 200,
    Default = DEFAULT_WALKSPEED,
    Suffix = " speed",

    Callback = function(value)
        WalkSpeed = value
        applyMovement()
    end
})

local JumpPowerSlider = Main:AddSlider({
    Name = "JumpPower",
    Flag = "jumppower",
    Min = 0,
    Max = 200,
    Default = DEFAULT_JUMPPOWER,
    Suffix = " power",

    Callback = function(value)
        JumpPower = value
        applyMovement()
    end
})

Main:AddToggle({
    Name = "Infinite Jump",
    Flag = "infinitejump",
    Default = false,

    Callback = function(enabled)
        InfiniteJump = enabled
    end
})

UserInputService.JumpRequest:Connect(function()
    if not InfiniteJump then
        return
    end

    local Humanoid = getHumanoid()

    if Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Keep WalkSpeed applied if the game changes it
RunService.Heartbeat:Connect(function()
    local Humanoid = getHumanoid()

    if not Humanoid then
        return
    end

    if Humanoid.WalkSpeed ~= WalkSpeed then
        Humanoid.WalkSpeed = WalkSpeed
    end

    if Humanoid.UseJumpPower ~= true then
        Humanoid.UseJumpPower = true
    end

    if Humanoid.JumpPower ~= JumpPower then
        Humanoid.JumpPower = JumpPower
    end
end)

-- Re-apply settings after respawning
Player.CharacterAdded:Connect(function(Character)
    local Humanoid = Character:WaitForChild("Humanoid", 10)

    if Humanoid then
        task.wait()
        applyMovement()
    end
end)

Main:AddSection("Character")

Main:AddButton({
    Text = "Reset Character",
    Confirm = true,
    Cooldown = 2,

    Callback = function()
        local Humanoid = getHumanoid()

        if Humanoid then
            Humanoid.Health = 0
        end
    end
})

Main:AddButton({
    Text = "Restore Defaults",

    Callback = function()
        WalkSpeed = DEFAULT_WALKSPEED
        JumpPower = DEFAULT_JUMPPOWER
        InfiniteJump = false

        applyMovement()

        if WalkSpeedSlider then
            WalkSpeedSlider:Set(DEFAULT_WALKSPEED, true)
        end

        if JumpPowerSlider then
            JumpPowerSlider:Set(DEFAULT_JUMPPOWER, true)
        end

        Window:Notify({
            Title = "Restored",
            Text = "All movement settings restored"
        })
    end
})

Window:AddSettingsTab()
