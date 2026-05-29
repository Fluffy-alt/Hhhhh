-- ╔══════════════════════════════════════════════╗
-- ║   [DUELS] Murderers VS Sheriffs              ║
-- ║   Powered by Rayfield — sirius.menu/rayfield ║
-- ╚══════════════════════════════════════════════╝

local RayfieldLibrary = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = RayfieldLibrary:CreateWindow({
    Name               = "[DUELS] Murderers VS Sheriffs",
    LoadingTitle       = "FluxGui",
    LoadingSubtitle    = "by Phemonaz",
    Theme              = "Teal",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
})

local GunTab      = Window:CreateTab("Gun",         4483362458)
local SettingsTab = Window:CreateTab("UI Settings", 4483362458)

GunTab:CreateSection("Only Gun")

-- ── Services & Variables ───────────────────────
local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
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
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local tool = getGunTool()
        if tool then hum:EquipTool(tool) end
    end

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if running and inMatch() then equipGun() end
    end)

    local bp = LocalPlayer:WaitForChild("Backpack")
    bp.ChildAdded:Connect(function(child)
        if running and inMatch() and child:IsA("Tool") then
            task.wait(0.1)
            equipGun()
        end
    end)

    GunTab:CreateToggle({
        Name         = "Auto Kill All Players",
        CurrentValue = false,
        Flag         = "AutoKill",
        Callback     = function(state)
            running = state
            if not running then return end
            task.spawn(function()
                while running do
                    task.wait(0.1)
                    if not inMatch() then continue end
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if not root then continue end
                    if not char:FindFirstChild("showBeam", true) then
                        equipGun()
                    end
                    local myTeam    = LocalPlayer:GetAttribute("Team")
                    local closest   = nil
                    local shortest  = MAX_DISTANCE
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p:GetAttribute("Team") ~= myTeam then
                            local ec = p.Character
                            local er = ec and ec:FindFirstChild("HumanoidRootPart")
                            if er then
                                local d = (er.Position - root.Position).Magnitude
                                if d <= MAX_DISTANCE and d < shortest then
                                    shortest = d
                                    closest  = p
                                end
                            end
                        end
                    end
                    local tool = char:FindFirstChildOfClass("Tool")
                    if closest and tool then
                        local killEvent = tool:FindFirstChild("kill")
                        if killEvent and killEvent:IsA("RemoteEvent") then
                            killEvent:FireServer(
                                closest,
                                Vector3.new(0.149008110165596, 0.019326409325003624, 0.9886471033096313)
                            )
                        end
                    end
                end
            end)
        end,
    })
end

-- ── Auto Shoot When Visible ────────────────────
do
    local enabled      = false
    local MAX_DISTANCE = 150
    local FIRE_DELAY   = 0.12

    local function getGunTool()
        local char     = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local function check(parent)
            if not parent then return nil end
            for _, t in ipairs(parent:GetChildren()) do
                if t:IsA("Tool") and t:FindFirstChild("showBeam") and t:FindFirstChild("kill") then
                    return t
                end
            end
        end
        return check(char) or check(backpack)
    end

    local function equipGun()
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return nil end
        local tool = getGunTool()
        if tool and tool.Parent ~= char then
            hum:EquipTool(tool)
            task.wait(0.05)
        end
        return tool
    end

    local function canSeeTarget(tc)
        local mc = LocalPlayer.Character
        if not mc then return false end
        local mr = mc:FindFirstChild("HumanoidRootPart")
        local tr = tc:FindFirstChild("HumanoidRootPart")
        if not mr or not tr then return false end
        local p = RaycastParams.new()
        p.FilterType = Enum.RaycastFilterType.Exclude
        p.FilterDescendantsInstances = {mc, tc}
        return workspace:Raycast(mr.Position, tr.Position - mr.Position, p) == nil
    end

    local function getClosest()
        if not enabled or not LocalPlayer:GetAttribute("Map") then return nil end
        local mc   = LocalPlayer.Character
        local mr   = mc and mc:FindFirstChild("HumanoidRootPart")
        if not mr then return nil end
        local myTeam  = LocalPlayer:GetAttribute("Team")
        local myGame  = LocalPlayer:GetAttribute("Game")
        local mPos    = Vector2.new(mouse.X, mouse.Y)
        local closest, shortest = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local pc  = p.Character
                local hum = pc and pc:FindFirstChildOfClass("Humanoid")
                local pr  = pc and pc:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and pr
                and p:GetAttribute("Game") == myGame
                and p:GetAttribute("Team") ~= myTeam then
                    local wd = (pr.Position - mr.Position).Magnitude
                    if wd <= MAX_DISTANCE and canSeeTarget(pc) then
                        local sp, onS = Camera:WorldToViewportPoint(pr.Position)
                        if onS then
                            local cd = (Vector2.new(sp.X, sp.Y) - mPos).Magnitude
                            if cd < shortest then shortest = cd; closest = p end
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
            local t = getClosest()
            if t then
                local r = t.Character and t.Character:FindFirstChild("HumanoidRootPart")
                if r then return CFrame.new(r.Position) end
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
            if not enabled or not LocalPlayer:GetAttribute("Map") then continue end
            local t = getClosest()
            if t then
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

    local function getClosest()
        if not enabled or not LocalPlayer:GetAttribute("Map") then return nil end
        local mc  = LocalPlayer.Character
        local mr  = mc and mc:FindFirstChild("HumanoidRootPart")
        if not mr then return nil end
        local mPos   = Vector2.new(mouse.X, mouse.Y)
        local myTeam = LocalPlayer:GetAttribute("Team")
        local myGame = LocalPlayer:GetAttribute("Game")
        local closest, shortest = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local pc = p.Character
                local pr = pc and pc:FindFirstChild("HumanoidRootPart")
                if pr
                and p:GetAttribute("Game") == myGame
                and p:GetAttribute("Team") ~= myTeam then
                    local wd = (pr.Position - mr.Position).Magnitude
                    if wd <= MAX_DISTANCE then
                        local sp, onS = Camera:WorldToViewportPoint(pr.Position)
                        if onS then
                            local d = (Vector2.new(sp.X, sp.Y) - mPos).Magnitude
                            if d < shortest then shortest = d; closest = p end
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
            local t = getClosest()
            if t then
                local r = t.Character and t.Character:FindFirstChild("HumanoidRootPart")
                if r then return CFrame.new(r.Position) end
            end
        end
        return oldIndex2(self, key)
    end))

    GunTab:CreateToggle({
        Name         = "Silent Aim",
        CurrentValue = false,
        Flag         = "SilentAim",
        Callback     = function(state) enabled = state end,
    })
end

-- ── UI Settings ────────────────────────────────
SettingsTab:CreateSection("Theme")

SettingsTab:CreateDropdown({
    Name          = "UI Theme",
    Options       = {"Default","Red","Green","Purple","Cyan","Blue","Pink","Yellow","Teal","Magenta","Orange","Rose","Gold"},
    CurrentOption = {"Teal"},
    Flag          = "UITheme",
    Callback      = function(_) end, -- theme is set on load
})

SettingsTab:CreateSection("Keybind")

SettingsTab:CreateKeybind({
    Name           = "Toggle UI",
    CurrentKeybind = "P",
    HoldToInteract = false,
    Flag           = "ToggleKey",
    Callback       = function(_) end,
})

RayfieldLibrary:LoadConfiguration()
