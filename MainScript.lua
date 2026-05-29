-- ╔══════════════════════════════════════════════╗
-- ║   [DUELS] Murderers VS Sheriffs              ║
-- ║   Powered by Rayfield — sirius.menu/rayfield ║
-- ╚══════════════════════════════════════════════╝

local RayfieldLibrary = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = RayfieldLibrary:CreateWindow({
    Name            = "[DUELS] Murderers VS Sheriffs",
    LoadingTitle    = "FluxGui",
    LoadingSubtitle = "by Phemonaz",
    Theme           = "Teal",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
})

local GunTab = Window:CreateTab("Gun",         4483362458)
local SettingsTab = Window:CreateTab("UI Settings", 4483362458)

GunTab:CreateSection("🔫  Only Gun")

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local Workspace   = game:GetService("Workspace")
local mouse       = LocalPlayer:GetMouse()

-- ── Auto Kill All Players ──────────────────────
do
    local running      = false
    local MAX_DISTANCE = 150

    local function inMatch()
        return LocalPlayer:GetAttribute("Map") ~= nil
    end

    local function getGunTool()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if not backpack then return nil end
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("showBeam") then
                if tool.showBeam:IsA("RemoteEvent") then return tool end
            end
        end
        return nil
    end

    local function equipGun()
        if not inMatch() then return end
        local character = LocalPlayer.Character
        local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local tool = getGunTool()
        if tool then humanoid:EquipTool(tool) end
    end

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if running and inMatch() then equipGun() end
    end)

    local function setupBackpackWatcher()
        local backpack = LocalPlayer:WaitForChild("Backpack")
        backpack.ChildAdded:Connect(function(child)
            if running and inMatch() and child:IsA("Tool") then
                task.wait(0.1)
                equipGun()
            end
        end)
    end
    setupBackpackWatcher()

    GunTab:CreateToggle({
        Name         = "Auto Kill All Players",
        CurrentValue = false,
        Flag         = "AutoKill",
        Callback     = function(state)
            running = state
            if running then
                task.spawn(function()
                    while running do
                        task.wait(0.1)
                        if not inMatch() then continue end
                        local character = LocalPlayer.Character
                        local rootPart  = character and character:FindFirstChild("HumanoidRootPart")
                        if not rootPart then continue end
                        local equippedTool = character:FindFirstChildOfClass("Tool")
                        if not equippedTool or not equippedTool:FindFirstChild("showBeam") then
                            equipGun()
                        end
                        local myTeam        = LocalPlayer:GetAttribute("Team")
                        local closestPlayer = nil
                        local shortestDist  = MAX_DISTANCE
                        for _, player in ipairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer and player:GetAttribute("Team") ~= myTeam then
                                local ec = player.Character
                                local er = ec and ec:FindFirstChild("HumanoidRootPart")
                                if er then
                                    local d = (er.Position - rootPart.Position).Magnitude
                                    if d <= MAX_DISTANCE and d < shortestDist then
                                        shortestDist  = d
                                        closestPlayer = player
                                    end
                                end
                            end
                        end
                        local tool = character:FindFirstChildOfClass("Tool")
                        if closestPlayer and tool then
                            local killEvent = tool:FindFirstChild("kill")
                            if killEvent and killEvent:IsA("RemoteEvent") then
                                killEvent:FireServer(
                                    closestPlayer,
                                    Vector3.new(
                                        0.149008110165596,
                                        0.019326409325003624,
                                        0.9886471033096313
                                    )
                                )
                            end
                        end
                    end
                end)
            end
        end,
    })
end

-- ── Auto Shoot When Visible ────────────────────
do
    local enabled      = false
    local MAX_DISTANCE = 150
    local FIRE_DELAY   = 0.12

    local function getGunTool()
        local character = LocalPlayer.Character
        local backpack  = LocalPlayer:FindFirstChild("Backpack")
        if character then
            for _, tool in ipairs(character:GetChildren()) do
                if tool:IsA("Tool") and tool:FindFirstChild("showBeam") and tool:FindFirstChild("kill") then
                    return tool
                end
            end
        end
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and tool:FindFirstChild("showBeam") and tool:FindFirstChild("kill") then
                    return tool
                end
            end
        end
        return nil
    end

    local function equipGun()
        local character = LocalPlayer.Character
        local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return nil end
        local tool = getGunTool()
        if tool and tool.Parent ~= character then
            humanoid:EquipTool(tool)
            task.wait(0.05)
        end
        return tool
    end

    local function canSeeTarget(targetCharacter)
        local myCharacter = LocalPlayer.Character
        if not myCharacter then return false end
        local myRoot     = myCharacter:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
        if not myRoot or not targetRoot then return false end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { myCharacter, targetCharacter }
        return Workspace:Raycast(myRoot.Position, targetRoot.Position - myRoot.Position, params) == nil
    end

    local function getClosestToCursor()
        if not enabled then return nil end
        if not LocalPlayer:GetAttribute("Map") then return nil end
        local myCharacter = LocalPlayer.Character
        local myRoot      = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
        local myTeam   = LocalPlayer:GetAttribute("Team")
        local myGame   = LocalPlayer:GetAttribute("Game")
        local mousePos = Vector2.new(mouse.X, mouse.Y)
        local closest  = nil
        local shortest = math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = player.Character
                local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
                local root      = character and character:FindFirstChild("HumanoidRootPart")
                if humanoid and humanoid.Health > 0 and root
                    and player:GetAttribute("Game") == myGame
                    and player:GetAttribute("Team") ~= myTeam then
                    local wd = (root.Position - myRoot.Position).Magnitude
                    if wd <= MAX_DISTANCE and canSeeTarget(character) then
                        local sp, onScreen = Camera:WorldToViewportPoint(root.Position)
                        if onScreen then
                            local cd = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                            if cd < shortest then
                                shortest = cd
                                closest  = player
                            end
                        end
                    end
                end
            end
        end
        return closest
    end

    local oldIndex1
    oldIndex1 = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if enabled and not checkcaller() and self == mouse and key == "Hit" then
            local target = getClosestToCursor()
            if target then
                local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                if root then return CFrame.new(root.Position) end
            end
        end
        return oldIndex1(self, key)
    end))

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if enabled then equipGun() end
    end)

    local bp = LocalPlayer:WaitForChild("Backpack")
    bp.ChildAdded:Connect(function(child)
        if enabled and child:IsA("Tool") then
            task.wait(0.1)
            equipGun()
        end
    end)

    task.spawn(function()
        while true do
            task.wait(FIRE_DELAY)
            if not enabled then continue end
            if not LocalPlayer:GetAttribute("Map") then continue end
            local target = getClosestToCursor()
            if target then
                local tool = equipGun()
                if tool and tool.Parent == LocalPlayer.Character then
                    tool:Activate()
                end
            end
        end
    end)

    GunTab:CreateToggle({
        Name         = "Auto Shoot When Visible",
        CurrentValue = false,
        Flag         = "AutoShootVisible",
        Callback     = function(state)
            enabled = state
            if enabled then equipGun() end
        end,
    })
end

-- ── Silent Aim ─────────────────────────────────
do
    local enabled      = false
    local MAX_DISTANCE = 150

    local function getClosestToCursor()
        if not enabled then return nil end
        if not LocalPlayer:GetAttribute("Map") then return nil end
        local myCharacter = LocalPlayer.Character
        local myRoot      = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
        local mousePos = Vector2.new(mouse.X, mouse.Y)
        local myTeam   = LocalPlayer:GetAttribute("Team")
        local myGame   = LocalPlayer:GetAttribute("Game")
        local closest  = nil
        local shortest = math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = player.Character
                local root      = character and character:FindFirstChild("HumanoidRootPart")
                if root
                    and player:GetAttribute("Game") == myGame
                    and player:GetAttribute("Team") ~= myTeam then
                    local wd = (root.Position - myRoot.Position).Magnitude
                    if wd <= MAX_DISTANCE then
                        local sp, onScreen = Camera:WorldToViewportPoint(root.Position)
                        if onScreen then
                            local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                            if d < shortest then
                                shortest = d
                                closest  = player
                            end
                        end
                    end
                end
            end
        end
        return closest
    end

    local oldIndex2
    oldIndex2 = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if enabled and not checkcaller() and self == mouse and key == "Hit" then
            local target = getClosestToCursor()
            if target then
                local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                if root then return CFrame.new(root.Position) end
            end
        end
        return oldIndex2(self, key)
    end))

    GunTab:CreateToggle({
        Name         = "Silent Aim",
        CurrentValue = false,
        Flag         = "SilentAim",
        Callback     = function(state)
            enabled = state
        end,
    })
end

-- ── UI Settings Tab ────────────────────────────
SettingsTab:CreateSection("Theme")

SettingsTab:CreateDropdown({
    Name          = "UI Theme",
    Options       = { "Default", "Red", "Green", "Purple", "Cyan", "Blue", "Pink", "Yellow", "Teal", "Magenta", "Orange", "Rose", "Gold" },
    CurrentOption = { "Teal" },
    Flag          = "UITheme",
    Callback      = function(option)
        Window:SetTheme(option[1])
    end,
})

SettingsTab:CreateSection("Keybind")

SettingsTab:CreateKeybind({
    Name           = "Toggle UI",
    CurrentKeybind = "P",
    HoldToInteract = false,
    Flag           = "ToggleKey",
    Callback       = function(keybind)
        -- fires when pressed
    end,
})

RayfieldLibrary:LoadConfiguration()
