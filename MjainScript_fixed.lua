-- ╔══════════════════════════════════════════════╗
-- ║        Rivals — Unlock All + ESP + Aim       ║
-- ║        Powered by Rayfield                   ║
-- ╚══════════════════════════════════════════════╝

local RayfieldLibrary = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = RayfieldLibrary:CreateWindow({
    Name               = "Rivals",
    LoadingTitle       = "FluxGui",
    LoadingSubtitle    = "Unlock All + ESP + Aim Assist",
    Theme              = "Teal",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
})

local CosmeticsTab = Window:CreateTab("Cosmetics",         4483362458)
local SettingsTab  = Window:CreateTab("UI Settings",       4483362458)
local VisualsTab   = Window:CreateTab("Visuals",           4483362458)
local ExtrasTab    = Window:CreateTab("Skeleton & Tracer", 4483362458)
local AimTab       = Window:CreateTab("Aim Assist",        4483362458)
local FiltersTab   = Window:CreateTab("Filters",           4483362458)
local MiscTab      = Window:CreateTab("Misc",              4483362458)

-- ════════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════════

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local UserInputService  = game:GetService("UserInputService")

local localPlayer   = Players.LocalPlayer
local camera        = workspace.CurrentCamera
local playerScripts = localPlayer:WaitForChild("PlayerScripts", 15)
local controllers   = playerScripts and playerScripts:WaitForChild("Controllers", 15)

-- ════════════════════════════════════════════════
--  CORE UNLOCK LOGIC (runs once on load)
-- ════════════════════════════════════════════════

local EnumLibrary, CosmeticLibrary, ItemLibrary, DataController
pcall(function()
    EnumLibrary     = require(ReplicatedStorage.Modules:WaitForChild("EnumLibrary", 10))
    if EnumLibrary then EnumLibrary:WaitForEnumBuilder() end
    CosmeticLibrary = require(ReplicatedStorage.Modules:WaitForChild("CosmeticLibrary", 10))
    ItemLibrary     = require(ReplicatedStorage.Modules:WaitForChild("ItemLibrary", 10))
    DataController  = require(controllers:WaitForChild("PlayerDataController", 10))
end)

local equipped, favorites = {}, {}
local constructingWeapon, viewingProfile = nil, nil
local lastUsedWeapon = nil
local unlockLoaded = false

-- ── Save / Load ────────────────────────────────
local saveFile = "unlockall/config.json"

local function cloneCosmetic(name, cosmeticType, options)
    local base = CosmeticLibrary and CosmeticLibrary.Cosmetics[name]
    if not base then return nil end
    local data = {}
    for k, v in pairs(base) do data[k] = v end
    data.Name = name
    data.Type = data.Type or cosmeticType
    data.Seed = data.Seed or math.random(1, 1000000)
    if EnumLibrary then
        local ok, enumId = pcall(EnumLibrary.ToEnum, EnumLibrary, name)
        if ok and enumId then data.Enum = enumId; data.ObjectID = data.ObjectID or enumId end
    end
    if options then
        if options.inverted ~= nil then data.Inverted = options.inverted end
        if options.favoritesOnly ~= nil then data.OnlyUseFavorites = options.favoritesOnly end
    end
    return data
end

local function saveConfig()
    if not writefile then return end
    pcall(function()
        local config = {equipped = {}, favorites = favorites}
        for weapon, cosmetics in pairs(equipped) do
            config.equipped[weapon] = {}
            for cosmeticType, cosmeticData in pairs(cosmetics) do
                if cosmeticData and cosmeticData.Name then
                    config.equipped[weapon][cosmeticType] = {
                        name = cosmeticData.Name, seed = cosmeticData.Seed, inverted = cosmeticData.Inverted
                    }
                end
            end
        end
        pcall(makefolder, "unlockall")
        writefile(saveFile, HttpService:JSONEncode(config))
    end)
end

local function loadConfig()
    if not readfile or not isfile or not isfile(saveFile) then return end
    pcall(function()
        local config = HttpService:JSONDecode(readfile(saveFile))
        if config.equipped then
            for weapon, cosmetics in pairs(config.equipped) do
                equipped[weapon] = {}
                for cosmeticType, cosmeticData in pairs(cosmetics) do
                    local cloned = cloneCosmetic(cosmeticData.name, cosmeticType, {inverted = cosmeticData.inverted})
                    if cloned then cloned.Seed = cosmeticData.seed; equipped[weapon][cosmeticType] = cloned end
                end
            end
        end
        favorites = config.favorites or {}
    end)
end

-- ── Main unlock patcher ────────────────────────
local function ApplyUnlockAll()
    if unlockLoaded or not CosmeticLibrary or not DataController then return end
    unlockLoaded = true

    -- ── SKINS ──
    CosmeticLibrary.OwnsCosmeticNormally    = function(self, inv, name) local c = CosmeticLibrary.Cosmetics[name]; if c and c.Type == "Skin" then return true end return false end
    CosmeticLibrary.OwnsCosmeticUniversally = function(self, inv, name) local c = CosmeticLibrary.Cosmetics[name]; if c and c.Type == "Skin" then return true end return false end
    CosmeticLibrary.OwnsCosmeticForWeapon   = function(self, inv, name) local c = CosmeticLibrary.Cosmetics[name]; if c and c.Type == "Skin" then return true end return false end

    local origOwns = CosmeticLibrary.OwnsCosmetic
    CosmeticLibrary.OwnsCosmetic = function(self, inv, name, weapon)
        if name:find("MISSING_") then return origOwns(self, inv, name, weapon) end
        local c = CosmeticLibrary.Cosmetics[name]
        if c and c.Type == "Skin" then return true end
        return origOwns(self, inv, name, weapon)
    end

    -- ── CHARMS ──
    local origOwnsCharm = CosmeticLibrary.OwnsCosmetic
    CosmeticLibrary.OwnsCosmetic = function(self, inv, name, weapon)
        if name:find("MISSING_") then return origOwnsCharm(self, inv, name, weapon) end
        local c = CosmeticLibrary.Cosmetics[name]
        if c and (c.Type == "Charm" or name:lower():find("charm")) then return true end
        return origOwnsCharm(self, inv, name, weapon)
    end

    -- ── DANCES ──
    local origOwnsDance = CosmeticLibrary.OwnsCosmetic
    CosmeticLibrary.OwnsCosmetic = function(self, inv, name, weapon)
        if name:find("MISSING_") then return origOwnsDance(self, inv, name, weapon) end
        local c = CosmeticLibrary.Cosmetics[name]
        if c and (c.Type == "Dance" or c.Type == "Emote" or name:lower():find("dance") or name:lower():find("emote")) then return true end
        return origOwnsDance(self, inv, name, weapon)
    end

    -- ── WRAPS ──
    local origOwnsWrap = CosmeticLibrary.OwnsCosmetic
    CosmeticLibrary.OwnsCosmetic = function(self, inv, name, weapon)
        if name:find("MISSING_") then return origOwnsWrap(self, inv, name, weapon) end
        local c = CosmeticLibrary.Cosmetics[name]
        if c and (c.Type == "Wrap" or c.Type == "Wrapping" or name:lower():find("wrap")) then return true end
        return origOwnsWrap(self, inv, name, weapon)
    end

    -- ── DataController.Get patch ──
    local origGet = DataController.Get
    DataController.Get = function(self, key)
        local data = origGet(self, key)
        if key == "CosmeticInventory" then
            local proxy = {}
            if data then
                for k, v in pairs(data) do
                    local c = CosmeticLibrary.Cosmetics[k]
                    if c and c.Type ~= "Finisher" then proxy[k] = v end
                end
            end
            return setmetatable(proxy, {__index = function(t, k)
                local c = CosmeticLibrary.Cosmetics[k]
                if c and c.Type ~= "Finisher" then return true end
                return nil
            end})
        end
        if key == "FavoritedCosmetics" then
            local result = data and table.clone(data) or {}
            for weapon, favs in pairs(favorites) do
                result[weapon] = result[weapon] or {}
                for name, isFav in pairs(favs) do
                    local c = CosmeticLibrary.Cosmetics[name]
                    if c and c.Type ~= "Finisher" then result[weapon][name] = isFav end
                end
            end
            return result
        end
        return data
    end

    -- ── DataController.GetWeaponData patch ──
    local origGetWeapon = DataController.GetWeaponData
    DataController.GetWeaponData = function(self, weaponName)
        local data = origGetWeapon(self, weaponName)
        if not data then return nil end
        local merged = {}
        for k, v in pairs(data) do merged[k] = v end
        merged.Name = weaponName
        if equipped[weaponName] then
            for cosmeticType, cosmeticData in pairs(equipped[weaponName]) do
                merged[cosmeticType] = cosmeticData
            end
        end
        return merged
    end

    -- ── Remote hooks ──
    if hookmetamethod then
        local remotes        = ReplicatedStorage:FindFirstChild("Remotes")
        local dataRemotes    = remotes and remotes:FindFirstChild("Data")
        local equipRemote    = dataRemotes and dataRemotes:FindFirstChild("EquipCosmetic")
        local favoriteRemote = dataRemotes and dataRemotes:FindFirstChild("FavoriteCosmetic")
        local replRemotes    = remotes and remotes:FindFirstChild("Replication")
        local fighterRemotes = replRemotes and replRemotes:FindFirstChild("Fighter")
        local useItemRemote  = fighterRemotes and fighterRemotes:FindFirstChild("UseItem")
        local FighterController
        pcall(function() FighterController = require(controllers:WaitForChild("FighterController", 10)) end)

        if equipRemote then
            local oldNC
            oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                if getnamecallmethod() ~= "FireServer" then return oldNC(self, ...) end
                local args = {...}

                if useItemRemote and self == useItemRemote then
                    local objectID = args[1]
                    if FighterController then
                        pcall(function()
                            local fighter = FighterController:GetFighter(localPlayer)
                            if fighter and fighter.Items then
                                for _, item in pairs(fighter.Items) do
                                    if item:Get("ObjectID") == objectID then lastUsedWeapon = item.Name; break end
                                end
                            end
                        end)
                    end
                end

                if self == equipRemote then
                    local weaponName, cosmeticType, cosmeticName, options = args[1], args[2], args[3], args[4] or {}
                    if cosmeticName and cosmeticName ~= "None" and cosmeticName ~= "" then
                        local inv = DataController:Get("CosmeticInventory")
                        if inv and rawget(inv, cosmeticName) then return oldNC(self, ...) end
                    end
                    equipped[weaponName] = equipped[weaponName] or {}
                    if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then
                        equipped[weaponName][cosmeticType] = nil
                        if not next(equipped[weaponName]) then equipped[weaponName] = nil end
                    else
                        local cloned = cloneCosmetic(cosmeticName, cosmeticType, {inverted = options.IsInverted, favoritesOnly = options.OnlyUseFavorites})
                        if cloned then equipped[weaponName][cosmeticType] = cloned end
                    end
                    task.defer(function()
                        pcall(function() DataController.CurrentData:Replicate("WeaponInventory") end)
                        task.wait(0.2)
                        saveConfig()
                    end)
                    return
                end

                if self == favoriteRemote then
                    local c = CosmeticLibrary.Cosmetics[args[2]]
                    if c and c.Type ~= "Finisher" then
                        favorites[args[1]] = favorites[args[1]] or {}
                        favorites[args[1]][args[2]] = args[3] or nil
                        saveConfig()
                        task.spawn(function() pcall(function() DataController.CurrentData:Replicate("FavoritedCosmetics") end) end)
                    end
                    return
                end

                return oldNC(self, ...)
            end))
        end
    end

    -- ── ClientItem / ViewModel patches ──
    local ClientItem
    pcall(function() ClientItem = require(playerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem) end)

    if ClientItem and ClientItem._CreateViewModel then
        local origVM = ClientItem._CreateViewModel
        ClientItem._CreateViewModel = function(self, viewmodelRef)
            local weaponName   = self.Name
            local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
            constructingWeapon = (weaponPlayer == localPlayer) and weaponName or nil
            if weaponPlayer == localPlayer and equipped[weaponName] and viewmodelRef then
                for cosmeticType, cosmeticData in pairs(equipped[weaponName]) do
                    local ok, dataKey, typeKey, nameKey = pcall(function()
                        return self:ToEnum("Data"), self:ToEnum(cosmeticType), self:ToEnum("Name")
                    end)
                    if ok and viewmodelRef[dataKey] then
                        viewmodelRef[dataKey][typeKey] = cosmeticData
                        viewmodelRef[dataKey][nameKey] = cosmeticData.Name
                    elseif viewmodelRef.Data then
                        viewmodelRef.Data[cosmeticType] = cosmeticData
                        viewmodelRef.Data.Name = cosmeticData.Name
                    end
                end
            end
            local result = origVM(self, viewmodelRef)
            constructingWeapon = nil
            return result
        end
    end

    local viewModelModule = playerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
    if viewModelModule then
        local ClientViewModel = require(viewModelModule)
        local origNew = ClientViewModel.new
        ClientViewModel.new = function(replicatedData, clientItem)
            local weaponPlayer = clientItem.ClientFighter and clientItem.ClientFighter.Player
            local weaponName   = constructingWeapon or clientItem.Name
            if weaponPlayer == localPlayer and equipped[weaponName] then
                local ok, ReplicatedClass = pcall(require, ReplicatedStorage.Modules.ReplicatedClass)
                if ok then
                    local dataKey = ReplicatedClass:ToEnum("Data")
                    replicatedData[dataKey] = replicatedData[dataKey] or {}
                    for cosmeticType, cosmeticData in pairs(equipped[weaponName]) do
                        local ok2, enumKey = pcall(ReplicatedClass.ToEnum, ReplicatedClass, cosmeticType)
                        if ok2 then replicatedData[dataKey][enumKey] = cosmeticData end
                    end
                end
            end
            return origNew(replicatedData, clientItem)
        end
    end

    -- ── EmoteController ──
    pcall(function()
        local EmoteController = require(controllers:WaitForChild("EmoteController", 10))
        if EmoteController and EmoteController.GetEmotes then
            local origEmotes = EmoteController.GetEmotes
            EmoteController.GetEmotes = function(self)
                local emotes = origEmotes(self)
                for name, c in pairs(CosmeticLibrary.Cosmetics) do
                    if c and (c.Type == "Dance" or c.Type == "Emote" or name:lower():find("dance") or name:lower():find("emote")) then
                        if not emotes[name] then
                            emotes[name] = {Name = name, Type = c.Type, ObjectID = c.ObjectID, Enum = c.Enum}
                        end
                    end
                end
                return emotes
            end
        end
    end)

    -- ── ViewProfile patch ──
    pcall(function()
        local ViewProfile = require(playerScripts.Modules.Pages.ViewProfile)
        if ViewProfile and ViewProfile.Fetch then
            local origFetch = ViewProfile.Fetch
            ViewProfile.Fetch = function(self, targetPlayer)
                viewingProfile = targetPlayer
                return origFetch(self, targetPlayer)
            end
        end
    end)

    loadConfig()
end

-- ════════════════════════════════════════════════
--  ESP SETTINGS
-- ════════════════════════════════════════════════

local ESP_SETTINGS = {
    Enabled         = true,
    ShowBox         = true,
    ShowName        = true,
    ShowHealth      = true,
    ShowDistance    = false,
    ShowSkeletons   = false,
    ShowTracer      = false,
    ShowChams       = false,
    TeamCheck       = false,
    WallCheck       = false,
    UseTeamColor    = true,
    BoxColor        = Color3.fromRGB(0, 255, 0),
    BoxOutlineColor = Color3.fromRGB(0, 0, 0),
    NameColor       = Color3.fromRGB(255, 255, 255),
    TracerColor     = Color3.fromRGB(255, 255, 255),
    TracerThickness = 2,
    TracerPosition  = "Bottom",
    BoxType         = "2D",
}

local bones = {
    {"Head","UpperTorso"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"UpperTorso","LowerTorso"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
}

-- ── ESP Helpers ────────────────────────────────
local function newDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function getPlayerColor(plr)
    if not ESP_SETTINGS.UseTeamColor then return ESP_SETTINGS.BoxColor end
    local c = plr.Team and plr.Team.TeamColor.Color or Color3.fromRGB(0, 255, 0)
    if c == Color3.new(1, 1, 1) then c = Color3.fromRGB(0, 255, 0) end
    return c
end

local function shouldShow(plr)
    if not ESP_SETTINGS.Enabled then return false end
    if ESP_SETTINGS.TeamCheck and localPlayer.Team and plr.Team then
        if localPlayer.Team == plr.Team then return false end
    end
    return true
end

local function behindWall(plr)
    local char = plr.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local origin = camera.CFrame.Position
    local dir    = hrp.Position - origin
    local ray    = Ray.new(origin, dir.Unit * dir.Magnitude)
    local hit    = workspace:FindPartOnRayWithIgnoreList(ray, {localPlayer.Character, char})
    return hit ~= nil
end

-- ── Per-player ESP cache ───────────────────────
local cache = {}

local function createPlayerEsp(plr)
    local e = {}
    e.box        = newDrawing("Square", {Color=ESP_SETTINGS.BoxColor, Thickness=2, Filled=false, Visible=false})
    e.boxOutline = newDrawing("Square", {Color=Color3.new(0,0,0),     Thickness=4, Filled=false, Visible=false})
    e.boxLines   = {}
    e.name       = newDrawing("Text",   {Color=Color3.new(1,1,1), Outline=true, Center=true, Size=14, Visible=false})
    e.healthBg   = newDrawing("Square", {Color=Color3.new(0,0,0), Filled=true,  Thickness=1,  Visible=false})
    e.healthFill = newDrawing("Square", {Color=Color3.fromRGB(0,255,0), Filled=true, Thickness=1, Visible=false})
    e.distance   = newDrawing("Text",   {Color=Color3.new(1,1,1), Outline=true, Center=true, Size=12, Visible=false})
    e.tracer     = newDrawing("Line",   {Color=ESP_SETTINGS.TracerColor, Thickness=2, Transparency=1, Visible=false})
    e.skeleton   = {}
    e.highlight  = nil
    cache[plr]   = e
end

local function destroyPlayerEsp(plr)
    local e = cache[plr]
    if not e then return end
    pcall(function()
        e.box:Remove()        e.boxOutline:Remove()
        e.name:Remove()       e.healthBg:Remove()
        e.healthFill:Remove() e.distance:Remove()
        e.tracer:Remove()
        for _, l  in ipairs(e.boxLines)  do l:Remove() end
        for _, ld in ipairs(e.skeleton)  do ld[1]:Remove() end
        if e.highlight then e.highlight:Destroy() end
    end)
    cache[plr] = nil
end

local function hidePlayerEsp(plr)
    local e = cache[plr]
    if not e then return end
    pcall(function()
        e.box.Visible        = false
        e.boxOutline.Visible = false
        e.name.Visible       = false
        e.healthBg.Visible   = false
        e.healthFill.Visible = false
        e.distance.Visible   = false
        e.tracer.Visible     = false
        for _, l  in ipairs(e.boxLines)  do l.Visible = false end
        for _, ld in ipairs(e.skeleton)  do ld[1].Visible = false end
        if e.highlight then e.highlight.Enabled = false end
    end)
end

-- ── Chams ──────────────────────────────────────
local function addHighlight(plr)
    local e = cache[plr]
    if not e or e.highlight then return end
    if not plr.Character then return end
    local h = Instance.new("Highlight")
    h.Name                = "ESPHighlight"
    h.Adornee             = plr.Character
    h.FillColor           = getPlayerColor(plr)
    h.OutlineColor        = Color3.new(0, 0, 0)
    h.FillTransparency    = 0.5
    h.OutlineTransparency = 0
    h.Parent              = CoreGui
    e.highlight           = h
end

-- ── Main ESP update ────────────────────────────
local function updateEsp()
    local vp = camera.ViewportSize
    for plr, e in pairs(cache) do
        pcall(function()
            if not shouldShow(plr)                          then hidePlayerEsp(plr) return end
            local char = plr.Character
            if not char                                     then hidePlayerEsp(plr) return end
            local hrp      = char:FindFirstChild("HumanoidRootPart")
            local head     = char:FindFirstChild("Head")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not head or not humanoid          then hidePlayerEsp(plr) return end
            if humanoid.Health <= 0                         then hidePlayerEsp(plr) return end
            if ESP_SETTINGS.WallCheck and behindWall(plr)  then hidePlayerEsp(plr) return end

            local rootScreen = camera:WorldToViewportPoint(hrp.Position)
            if rootScreen.Z <= 0                            then hidePlayerEsp(plr) return end
            if rootScreen.X < -150 or rootScreen.X > vp.X + 150
            or rootScreen.Y < -150 or rootScreen.Y > vp.Y + 150 then
                hidePlayerEsp(plr) return
            end

            local dist  = math.clamp(rootScreen.Z, 0.1, 2000)
            local sizeY = math.clamp((1500 / dist) * 1.3, 10, 800)
            local sizeX = sizeY * 0.6
            local bpX   = math.floor(rootScreen.X - sizeX / 2)
            local bpY   = math.floor(rootScreen.Y - sizeY / 2)
            local boxPos  = Vector2.new(bpX, bpY)
            local boxSize = Vector2.new(math.floor(sizeX), math.floor(sizeY))
            local color   = getPlayerColor(plr)

            -- Chams
            if ESP_SETTINGS.ShowChams then
                if not e.highlight then addHighlight(plr) end
                if e.highlight then
                    e.highlight.Adornee   = char
                    e.highlight.FillColor = color
                    e.highlight.Enabled   = true
                end
            else
                if e.highlight then e.highlight.Enabled = false end
            end

            -- Box
            if ESP_SETTINGS.ShowBox then
                if ESP_SETTINGS.BoxType == "2D" then
                    for _, l in ipairs(e.boxLines) do pcall(function() l:Remove() end) end
                    e.boxLines = {}
                    e.boxOutline.Size     = boxSize + Vector2.new(2, 2)
                    e.boxOutline.Position = boxPos  - Vector2.new(1, 1)
                    e.boxOutline.Color    = ESP_SETTINGS.BoxOutlineColor
                    e.boxOutline.Visible  = true
                    e.box.Size     = boxSize
                    e.box.Position = boxPos
                    e.box.Color    = color
                    e.box.Visible  = true
                elseif ESP_SETTINGS.BoxType == "Corner Box Esp" then
                    e.box.Visible        = false
                    e.boxOutline.Visible = false
                    if #e.boxLines ~= 16 then
                        for _, l in ipairs(e.boxLines) do pcall(function() l:Remove() end) end
                        e.boxLines = {}
                        for i = 1, 16 do
                            e.boxLines[i] = newDrawing("Line", {Thickness=1, Color=color, Transparency=1, Visible=false})
                        end
                    end
                    local bl = e.boxLines
                    local lw = math.floor(boxSize.X / 4)
                    local lh = math.floor(boxSize.Y / 4)
                    local x0, y0 = boxPos.X, boxPos.Y
                    local x1, y1 = x0 + boxSize.X, y0 + boxSize.Y
                    bl[1].From=Vector2.new(x0,y0)       bl[1].To=Vector2.new(x0+lw,y0)
                    bl[2].From=Vector2.new(x0,y0)       bl[2].To=Vector2.new(x0,y0+lh)
                    bl[3].From=Vector2.new(x1,y0)       bl[3].To=Vector2.new(x1-lw,y0)
                    bl[4].From=Vector2.new(x1,y0)       bl[4].To=Vector2.new(x1,y0+lh)
                    bl[5].From=Vector2.new(x0,y1)       bl[5].To=Vector2.new(x0+lw,y1)
                    bl[6].From=Vector2.new(x0,y1)       bl[6].To=Vector2.new(x0,y1-lh)
                    bl[7].From=Vector2.new(x1,y1)       bl[7].To=Vector2.new(x1-lw,y1)
                    bl[8].From=Vector2.new(x1,y1)       bl[8].To=Vector2.new(x1,y1-lh)
                    for i = 9, 16 do bl[i].Thickness=2  bl[i].Color=ESP_SETTINGS.BoxOutlineColor end
                    bl[9].From=Vector2.new(x0+1,y0+1)   bl[9].To=Vector2.new(x0+lw,y0+1)
                    bl[10].From=Vector2.new(x0+1,y0+1)  bl[10].To=Vector2.new(x0+1,y0+lh)
                    bl[11].From=Vector2.new(x1-1,y0+1)  bl[11].To=Vector2.new(x1-lw,y0+1)
                    bl[12].From=Vector2.new(x1-1,y0+1)  bl[12].To=Vector2.new(x1-1,y0+lh)
                    bl[13].From=Vector2.new(x0+1,y1-1)  bl[13].To=Vector2.new(x0+lw,y1-1)
                    bl[14].From=Vector2.new(x0+1,y1-1)  bl[14].To=Vector2.new(x0+1,y1-lh)
                    bl[15].From=Vector2.new(x1-1,y1-1)  bl[15].To=Vector2.new(x1-lw,y1-1)
                    bl[16].From=Vector2.new(x1-1,y1-1)  bl[16].To=Vector2.new(x1-1,y1-lh)
                    for _, l in ipairs(bl) do l.Color=color l.Visible=true end
                end
            else
                e.box.Visible        = false
                e.boxOutline.Visible = false
                for _, l in ipairs(e.boxLines) do pcall(function() l:Remove() end) end
                e.boxLines = {}
            end

            -- Name
            if ESP_SETTINGS.ShowName then
                e.name.Text     = plr.Name
                e.name.Color    = color
                e.name.Position = Vector2.new(rootScreen.X, bpY - 18)
                e.name.Visible  = true
            else
                e.name.Visible = false
            end

            -- Health bar
            if ESP_SETTINGS.ShowHealth then
                local hp   = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                local barW = 6
                local barH = boxSize.Y
                local barX = bpX - barW - 4
                local barY = bpY
                e.healthBg.Size     = Vector2.new(barW + 2, barH + 2)
                e.healthBg.Position = Vector2.new(barX - 1, barY - 1)
                e.healthBg.Visible  = true
                local fillH = math.max(1, math.floor(barH * hp))
                e.healthFill.Size     = Vector2.new(barW, fillH)
                e.healthFill.Position = Vector2.new(barX, barY + (barH - fillH))
                e.healthFill.Color    = hp > 0.6 and Color3.fromRGB(0,255,0)
                                     or hp > 0.3 and Color3.fromRGB(255,255,0)
                                     or              Color3.fromRGB(255,0,0)
                e.healthFill.Visible  = true
            else
                e.healthBg.Visible   = false
                e.healthFill.Visible = false
            end

            -- Distance
            if ESP_SETTINGS.ShowDistance then
                e.distance.Text     = string.format("%d studs", math.floor(dist))
                e.distance.Position = Vector2.new(rootScreen.X, bpY + boxSize.Y + 4)
                e.distance.Visible  = true
            else
                e.distance.Visible = false
            end

            -- Skeleton
            if ESP_SETTINGS.ShowSkeletons then
                if #e.skeleton == 0 then
                    for _, bp in ipairs(bones) do
                        if char:FindFirstChild(bp[1]) and char:FindFirstChild(bp[2]) then
                            e.skeleton[#e.skeleton+1] = {
                                newDrawing("Line",{Thickness=1,Color=color,Transparency=1,Visible=false}),
                                bp[1], bp[2]
                            }
                        end
                    end
                end
                for _, ld in ipairs(e.skeleton) do
                    local p = char:FindFirstChild(ld[2])
                    local c = char:FindFirstChild(ld[3])
                    if p and c then
                        local ps = camera:WorldToViewportPoint(p.Position)
                        local cs = camera:WorldToViewportPoint(c.Position)
                        ld[1].From    = Vector2.new(ps.X, ps.Y)
                        ld[1].To      = Vector2.new(cs.X, cs.Y)
                        ld[1].Color   = color
                        ld[1].Visible = true
                    else
                        ld[1].Visible = false
                    end
                end
            else
                for _, ld in ipairs(e.skeleton) do pcall(function() ld[1]:Remove() end) end
                e.skeleton = {}
            end

            -- Tracer
            if ESP_SETTINGS.ShowTracer then
                local tracerY = vp.Y
                if ESP_SETTINGS.TracerPosition == "Top"    then tracerY = 0        end
                if ESP_SETTINGS.TracerPosition == "Middle" then tracerY = vp.Y / 2 end
                e.tracer.From      = Vector2.new(vp.X / 2, tracerY)
                e.tracer.To        = Vector2.new(rootScreen.X, rootScreen.Y)
                e.tracer.Color     = color
                e.tracer.Thickness = ESP_SETTINGS.TracerThickness
                e.tracer.Visible   = true
            else
                e.tracer.Visible = false
            end
        end)
    end
end

-- ── Player hooks ───────────────────────────────
local function hookPlayer(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        local e = cache[plr]
        if not e then return end
        for _, ld in ipairs(e.skeleton) do pcall(function() ld[1]:Remove() end) end
        e.skeleton = {}
        if e.highlight then pcall(function() e.highlight:Destroy() end) e.highlight = nil end
        if ESP_SETTINGS.ShowChams then addHighlight(plr) end
    end)
    plr.CharacterRemoving:Connect(function() hidePlayerEsp(plr) end)
end

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= localPlayer then createPlayerEsp(plr); hookPlayer(plr) end
end
Players.PlayerAdded:Connect(function(plr)
    if plr == localPlayer then return end
    createPlayerEsp(plr); hookPlayer(plr)
end)
Players.PlayerRemoving:Connect(function(plr)
    pcall(function() destroyPlayerEsp(plr) end)
end)
RunService.RenderStepped:Connect(updateEsp)

-- ════════════════════════════════════════════════
--  AIM ASSIST
-- ════════════════════════════════════════════════

local AIM_SETTINGS = {
    Enabled         = true,
    FOV             = 120,
    Smoothness      = 5,
    TargetPart      = "Head",
    ShowFOV         = true,
    FOVColor        = Color3.new(1, 1, 1),
    TeamCheck       = false,
    VisibilityCheck = false,
    Prediction      = 0.1,
    MaxSpeed        = 30,
    Mode            = "Silent",
}

local fovCircle     = Drawing.new("Circle")
fovCircle.Visible   = false
fovCircle.Thickness = 1
fovCircle.Filled    = false
fovCircle.NumSides  = 64
fovCircle.Radius    = AIM_SETTINGS.FOV
fovCircle.Color     = AIM_SETTINGS.FOVColor

local partVelocityCache = {}
local function getTargetVelocity(part)
    local prev = partVelocityCache[part]
    local now  = tick()
    local vel  = Vector3.new()
    if prev then
        local dt = now - prev.time
        if dt > 0 then vel = (part.Position - prev.pos) / dt end
    end
    partVelocityCache[part] = {pos = part.Position, time = now}
    return vel
end

local function getClosestPlayer()
    local closest, closestDist = nil, math.huge
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == localPlayer then continue end
        if AIM_SETTINGS.TeamCheck and plr.Team == localPlayer.Team then continue end
        local char = plr.Character
        if not char then continue end
        local part = char:FindFirstChild(AIM_SETTINGS.TargetPart) or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        if AIM_SETTINGS.VisibilityCheck then
            local ray = Ray.new(camera.CFrame.Position, (part.Position - camera.CFrame.Position).Unit * 1000)
            local hit = workspace:FindPartOnRayWithIgnoreList(ray, {localPlayer.Character, char})
            if hit then continue end
        end
        local dist3D = (part.Position - camera.CFrame.Position).Magnitude
        if dist3D > 500 then continue end
        local sp, onSc = camera:WorldToViewportPoint(part.Position)
        if not onSc then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < closestDist and d <= AIM_SETTINGS.FOV then
            closestDist = d
            closest     = plr
        end
    end
    return closest
end

local lockedTarget = nil

RunService.RenderStepped:Connect(function(dt)
    fovCircle.Radius   = AIM_SETTINGS.FOV
    fovCircle.Color    = AIM_SETTINGS.FOVColor
    fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    fovCircle.Visible  = AIM_SETTINGS.ShowFOV and AIM_SETTINGS.Enabled

    if not AIM_SETTINGS.Enabled then lockedTarget = nil return end

    local rmb = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if not rmb then lockedTarget = nil return end

    local target
    if AIM_SETTINGS.Mode == "LockOn" then
        if lockedTarget then
            local char = lockedTarget.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if not char or not hum or hum.Health <= 0 then lockedTarget = nil end
        end
        if not lockedTarget then lockedTarget = getClosestPlayer() end
        target = lockedTarget
    else
        target = getClosestPlayer()
    end

    if not target then return end
    local char = target.Character
    if not char then return end
    local part = char:FindFirstChild(AIM_SETTINGS.TargetPart) or char:FindFirstChild("HumanoidRootPart")
    if not part then return end

    local predictedPos = part.Position + getTargetVelocity(part) * AIM_SETTINGS.Prediction
    local sp, onSc = camera:WorldToViewportPoint(predictedPos)
    if not onSc then return end

    local dx = sp.X - camera.ViewportSize.X / 2
    local dy = sp.Y - camera.ViewportSize.Y / 2
    if math.abs(dx) < 1 and math.abs(dy) < 1 then return end

    local smooth = math.max(1, AIM_SETTINGS.Smoothness)
    local moveX  = dx / smooth
    local moveY  = dy / smooth
    if math.abs(moveX) > math.abs(dx) then moveX = dx end
    if math.abs(moveY) > math.abs(dy) then moveY = dy end

    mousemoverel(moveX, moveY)
end)

-- ════════════════════════════════════════════════
--  GUI — COSMETICS TAB
-- ════════════════════════════════════════════════

CosmeticsTab:CreateSection("Unlock All")
CosmeticsTab:CreateToggle({
    Name         = "Unlock All Cosmetics (except Finishers)",
    CurrentValue = true,
    Flag         = "UnlockAll",
    Callback     = function(state)
        if state then
            ApplyUnlockAll()
            RayfieldLibrary:Notify({
                Title    = "Rivals UnlockAll",
                Content  = "All cosmetics unlocked! (Skins, Charms, Dances, Wraps)",
                Duration = 4,
            })
        end
    end,
})
CosmeticsTab:CreateSection("Info")
CosmeticsTab:CreateLabel("Skins ✅  Charms ✅  Dances ✅  Wraps ✅  Finishers ❌")
CosmeticsTab:CreateButton({
    Name     = "Reload / Re-apply Patches",
    Callback = function()
        unlockLoaded = false
        ApplyUnlockAll()
        RayfieldLibrary:Notify({Title = "Reloaded", Content = "Patches re-applied.", Duration = 3})
    end,
})

-- ════════════════════════════════════════════════
--  GUI — UI SETTINGS TAB
-- ════════════════════════════════════════════════

SettingsTab:CreateSection("Keybind")
SettingsTab:CreateKeybind({
    Name           = "Toggle UI",
    CurrentKeybind = "P",
    HoldToInteract = false,
    Flag           = "ToggleKey",
    Callback       = function(_) end,
})

-- ════════════════════════════════════════════════
--  GUI — VISUALS TAB
-- ════════════════════════════════════════════════

VisualsTab:CreateToggle({ Name="Enable ESP",       CurrentValue=ESP_SETTINGS.Enabled,        Flag="ESP_Enabled",    Callback=function(v) ESP_SETTINGS.Enabled=v end })
VisualsTab:CreateToggle({ Name="Show Box",          CurrentValue=ESP_SETTINGS.ShowBox,         Flag="ESP_Box",        Callback=function(v) ESP_SETTINGS.ShowBox=v end })
VisualsTab:CreateDropdown({ Name="Box Type", Options={"2D","Corner Box Esp"}, CurrentOption={ESP_SETTINGS.BoxType}, Flag="ESP_BoxType", Callback=function(v) ESP_SETTINGS.BoxType=v[1] end })
VisualsTab:CreateToggle({ Name="Use Team Color",    CurrentValue=ESP_SETTINGS.UseTeamColor,    Flag="ESP_TeamCol",    Callback=function(v) ESP_SETTINGS.UseTeamColor=v end })
VisualsTab:CreateColorPicker({ Name="Box Color",    Color=ESP_SETTINGS.BoxColor,               Flag="ESP_BoxColor",   Callback=function(v) ESP_SETTINGS.BoxColor=v end })
VisualsTab:CreateColorPicker({ Name="Box Outline",  Color=ESP_SETTINGS.BoxOutlineColor,        Flag="ESP_BoxOutline", Callback=function(v) ESP_SETTINGS.BoxOutlineColor=v end })
VisualsTab:CreateToggle({ Name="Show Name",         CurrentValue=ESP_SETTINGS.ShowName,        Flag="ESP_Name",       Callback=function(v) ESP_SETTINGS.ShowName=v end })
VisualsTab:CreateColorPicker({ Name="Name Color",   Color=ESP_SETTINGS.NameColor,              Flag="ESP_NameColor",  Callback=function(v) ESP_SETTINGS.NameColor=v end })
VisualsTab:CreateToggle({ Name="Show Health",       CurrentValue=ESP_SETTINGS.ShowHealth,      Flag="ESP_Health",     Callback=function(v) ESP_SETTINGS.ShowHealth=v end })
VisualsTab:CreateToggle({ Name="Show Distance",     CurrentValue=ESP_SETTINGS.ShowDistance,    Flag="ESP_Dist",       Callback=function(v) ESP_SETTINGS.ShowDistance=v end })
VisualsTab:CreateToggle({ Name="Show Chams",        CurrentValue=ESP_SETTINGS.ShowChams,       Flag="ESP_Chams",      Callback=function(v)
    ESP_SETTINGS.ShowChams = v
    if not v then
        for plr, e in pairs(cache) do
            if e.highlight then pcall(function() e.highlight:Destroy() end) e.highlight = nil end
        end
    end
end })

-- ════════════════════════════════════════════════
--  GUI — SKELETON & TRACER TAB
-- ════════════════════════════════════════════════

ExtrasTab:CreateToggle({ Name="Show Skeletons",     CurrentValue=ESP_SETTINGS.ShowSkeletons,   Flag="ESP_Skel",      Callback=function(v) ESP_SETTINGS.ShowSkeletons=v end })
ExtrasTab:CreateToggle({ Name="Show Tracer",        CurrentValue=ESP_SETTINGS.ShowTracer,      Flag="ESP_Tracer",    Callback=function(v) ESP_SETTINGS.ShowTracer=v end })
ExtrasTab:CreateDropdown({ Name="Tracer Origin", Options={"Bottom","Middle","Top"}, CurrentOption={ESP_SETTINGS.TracerPosition}, Flag="ESP_TracerPos", Callback=function(v) ESP_SETTINGS.TracerPosition=v[1] end })
ExtrasTab:CreateColorPicker({ Name="Tracer Color",  Color=ESP_SETTINGS.TracerColor,            Flag="ESP_TracerCol", Callback=function(v) ESP_SETTINGS.TracerColor=v end })
ExtrasTab:CreateSlider({ Name="Tracer Thickness", Range={1,5}, Increment=1, Suffix="px", CurrentValue=ESP_SETTINGS.TracerThickness, Flag="ESP_TracerThk", Callback=function(v) ESP_SETTINGS.TracerThickness=v end })

-- ════════════════════════════════════════════════
--  GUI — AIM ASSIST TAB
-- ════════════════════════════════════════════════

AimTab:CreateToggle({ Name="Enable Aim Assist",     CurrentValue=true,                         Flag="AIM_Enabled",   Callback=function(v) AIM_SETTINGS.Enabled=v end })
AimTab:CreateDropdown({ Name="Aim Mode", Options={"Silent","LockOn"}, CurrentOption={AIM_SETTINGS.Mode}, Flag="AIM_Mode", Callback=function(v)
    AIM_SETTINGS.Mode = v[1]
    lockedTarget = nil
end })
AimTab:CreateSlider({ Name="FOV Radius",  Range={10,500},  Increment=5,   Suffix="px", CurrentValue=AIM_SETTINGS.FOV,             Flag="AIM_FOV",    Callback=function(v) AIM_SETTINGS.FOV=v end })
AimTab:CreateSlider({ Name="Smoothness",  Range={1,20},    Increment=1,   Suffix="",   CurrentValue=AIM_SETTINGS.Smoothness,      Flag="AIM_Smooth", Callback=function(v) AIM_SETTINGS.Smoothness=v end })
AimTab:CreateSlider({ Name="Max Speed",   Range={1,100},   Increment=1,   Suffix="px", CurrentValue=AIM_SETTINGS.MaxSpeed,        Flag="AIM_Speed",  Callback=function(v) AIM_SETTINGS.MaxSpeed=v end })
AimTab:CreateSlider({ Name="Prediction",  Range={0,200},   Increment=1,   Suffix="",   CurrentValue=AIM_SETTINGS.Prediction*100, Flag="AIM_Pred",   Callback=function(v) AIM_SETTINGS.Prediction=v/100 end })
AimTab:CreateDropdown({ Name="Target Part", Options={"Head","HumanoidRootPart","UpperTorso"}, CurrentOption={AIM_SETTINGS.TargetPart}, Flag="AIM_Part", Callback=function(v) AIM_SETTINGS.TargetPart=v[1] end })
AimTab:CreateToggle({ Name="Show FOV Circle",       CurrentValue=AIM_SETTINGS.ShowFOV,         Flag="AIM_ShowFOV",   Callback=function(v) AIM_SETTINGS.ShowFOV=v end })
AimTab:CreateColorPicker({ Name="FOV Color",        Color=AIM_SETTINGS.FOVColor,               Flag="AIM_FOVCol",    Callback=function(v) AIM_SETTINGS.FOVColor=v end })
AimTab:CreateToggle({ Name="Team Check",            CurrentValue=AIM_SETTINGS.TeamCheck,       Flag="AIM_TeamChk",   Callback=function(v) AIM_SETTINGS.TeamCheck=v end })
AimTab:CreateToggle({ Name="Visibility Check",      CurrentValue=AIM_SETTINGS.VisibilityCheck, Flag="AIM_VisChk",    Callback=function(v) AIM_SETTINGS.VisibilityCheck=v end })

-- ════════════════════════════════════════════════
--  GUI — FILTERS TAB
-- ════════════════════════════════════════════════

FiltersTab:CreateToggle({ Name="ESP Team Check",    CurrentValue=ESP_SETTINGS.TeamCheck,       Flag="ESP_TeamChk",   Callback=function(v) ESP_SETTINGS.TeamCheck=v end })
FiltersTab:CreateToggle({ Name="ESP Wall Check",    CurrentValue=ESP_SETTINGS.WallCheck,       Flag="ESP_WallChk",   Callback=function(v) ESP_SETTINGS.WallCheck=v end })

-- ════════════════════════════════════════════════
--  GUI — MISC TAB
-- ════════════════════════════════════════════════

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        local success, err = pcall(function()
            TeleportService:Teleport(game.PlaceId, localPlayer)
        end)
        if not success then
            RayfieldLibrary:Notify({ Title="Rejoin Failed", Content=tostring(err), Duration=4 })
        end
    end,
})

-- ── Auto-apply on load ─────────────────────────
task.spawn(ApplyUnlockAll)

RayfieldLibrary:Notify({
    Title    = "FluxGui — Rivals",
    Content  = "Loaded! Unlock All + ESP + Aim Assist active. Press [P] to toggle UI.",
    Duration = 5,
})

RayfieldLibrary:LoadConfiguration()
