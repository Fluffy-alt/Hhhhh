-- ╔══════════════════════════════════════════════╗
-- ║        Rivals — Unlock All Skins             ║
-- ║        Powered by Rayfield                   ║
-- ╚══════════════════════════════════════════════╝

local RayfieldLibrary = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = RayfieldLibrary:CreateWindow({
    Name               = "Rivals",
    LoadingTitle       = "FluxGui",
    LoadingSubtitle    = "Unlock All Cosmetics",
    Theme              = "Teal",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
})

local CosmeticsTab = Window:CreateTab("Cosmetics", 4483362458)
local SettingsTab  = Window:CreateTab("UI Settings", 4483362458)

-- ════════════════════════════════════════════════
--  CORE UNLOCK LOGIC (runs once on load)
-- ════════════════════════════════════════════════

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local player            = Players.LocalPlayer
local playerScripts     = player:WaitForChild("PlayerScripts", 15)
local controllers       = playerScripts and playerScripts:WaitForChild("Controllers", 15)

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
        local remotes       = ReplicatedStorage:FindFirstChild("Remotes")
        local dataRemotes   = remotes and remotes:FindFirstChild("Data")
        local equipRemote   = dataRemotes and dataRemotes:FindFirstChild("EquipCosmetic")
        local favoriteRemote= dataRemotes and dataRemotes:FindFirstChild("FavoriteCosmetic")
        local replRemotes   = remotes and remotes:FindFirstChild("Replication")
        local fighterRemotes= replRemotes and replRemotes:FindFirstChild("Fighter")
        local useItemRemote = fighterRemotes and fighterRemotes:FindFirstChild("UseItem")
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
                            local fighter = FighterController:GetFighter(player)
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
                    -- skip if real inventory item
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
    pcall(function() ClientItem = require(player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem) end)

    if ClientItem and ClientItem._CreateViewModel then
        local origVM = ClientItem._CreateViewModel
        ClientItem._CreateViewModel = function(self, viewmodelRef)
            local weaponName   = self.Name
            local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
            constructingWeapon = (weaponPlayer == player) and weaponName or nil
            if weaponPlayer == player and equipped[weaponName] and viewmodelRef then
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

    local viewModelModule = player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
    if viewModelModule then
        local ClientViewModel = require(viewModelModule)
        local origNew = ClientViewModel.new
        ClientViewModel.new = function(replicatedData, clientItem)
            local weaponPlayer = clientItem.ClientFighter and clientItem.ClientFighter.Player
            local weaponName   = constructingWeapon or clientItem.Name
            if weaponPlayer == player and equipped[weaponName] then
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
        local ViewProfile = require(player.PlayerScripts.Modules.Pages.ViewProfile)
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

-- ── Auto-apply on load ─────────────────────────
task.spawn(ApplyUnlockAll)

RayfieldLibrary:Notify({
    Title    = "FluxGui — Rivals",
    Content  = "Unlock All loaded! Press [P] to toggle UI.",
    Duration = 5,
})

RayfieldLibrary:LoadConfiguration()
