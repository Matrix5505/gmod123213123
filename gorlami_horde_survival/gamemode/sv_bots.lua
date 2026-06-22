-- Bot System for Horde Survival
-- Handles AI bots that can select perks, use shop, and work with game mechanics

if SERVER then
    util.AddNetworkString("BotPerkChange")
    util.AddNetworkString("BotShopBuy")
    util.AddNetworkString("BotPlaceTurret")
end

GM.Bots = {}
GM.BotConfigs = {}

-- Bot personality types
GM.BotPersonalities = {
    ["aggressive"] = {
        name = "Aggressive",
        perkPriority = {"soldier", "tank", "scout", "merchant", "medic", "engineer"},
        weaponPreference = {"weapon_shotgun", "weapon_smg1", "weapon_ar2"},
        behavior = "rush"
    },
    ["defensive"] = {
        name = "Defensive",
        perkPriority = {"engineer", "tank", "medic", "soldier", "merchant", "scout"},
        weaponPreference = {"weapon_ar2", "weapon_shotgun", "weapon_smg1"},
        behavior = "hold_position"
    },
    ["support"] = {
        name = "Support",
        perkPriority = {"medic", "engineer", "merchant", "tank", "soldier", "scout"},
        weaponPreference = {"weapon_smg1", "weapon_pistol", "weapon_shotgun"},
        behavior = "follow_teammates"
    },
    ["economic"] = {
        name = "Economic",
        perkPriority = {"merchant", "soldier", "engineer", "medic", "tank", "scout"},
        weaponPreference = {"weapon_ar2", "weapon_smg1", "weapon_shotgun"},
        behavior = "farm_kills"
    }
}

-- Create a bot
function GM:CreateBot(name, personality)
    if not self.BotsEnabled then return nil end
    
    local botCount = player.GetCount()
    if botCount >= (self.MaxBots or 8) then
        print("[Horde Survival] Max bot limit reached!")
        return nil
    end
    
    -- Choose random personality if not specified
    if not personality then
        local personalities = {}
        for k, v in pairs(self.BotPersonalities) do
            table.insert(personalities, k)
        end
        personality = personalities[math.random(#personalities)]
    end
    
    local config = self.BotPersonalities[personality]
    if not config then return nil end
    
    -- Create bot using GMod's bot system
    local bot = player.CreateNextBot(name or "Bot")
    
    if not IsValid(bot) then
        print("[Horde Survival] Failed to create bot!")
        return nil
    end
    
    -- Store bot configuration
    self.Bots[bot] = {
        personality = personality,
        config = config,
        selectedPerks = {},
        perkPoints = 0,
        money = 500,
        lastDecisionTime = CurTime(),
        decisionInterval = 5,
        turretsPlaced = 0
    }
    
    -- Initialize bot data
    bot.PerkPoints = 0
    bot.Money = 500
    bot.SelectedPerks = {}
    bot.IsBot = true
    
    print("[Horde Survival] Created " .. config.name .. " bot: " .. bot:Nick())
    
    return bot
end

-- Remove a bot
function GM:RemoveBot(bot)
    if not IsValid(bot) or not bot:IsPlayer() then return end
    
    if self.Bots[bot] then
        self.Bots[bot] = nil
    end
    
    bot:Kick("Bot removed")
    print("[Horde Survival] Removed bot")
end

-- Bot thinks about what to do
function GM:BotThink(bot)
    if not IsValid(bot) or not bot:Alive() then return end
    
    local botData = self.Bots[bot]
    if not botData then return end
    
    -- Only make decisions periodically
    if CurTime() < botData.lastDecisionTime + botData.decisionInterval then
        return
    end
    
    botData.lastDecisionTime = CurTime()
    
    -- Update bot's actual data from our stored data
    bot.PerkPoints = botData.perkPoints
    bot.Money = botData.money
    bot.SelectedPerks = botData.selectedPerks
    
    -- Decide on perks
    self:BotDecidePerks(bot, botData)
    
    -- Decide on shop purchases
    self:BotDecideShop(bot, botData)
    
    -- Decide on turret placement (if engineer)
    if botData.selectedPerks["engineer"] then
        self:BotDecideTurret(bot, botData)
    end
end

-- Bot decides which perks to buy
function GM:BotDecidePerks(bot, botData)
    local config = botData.config
    local perkPriority = config.perkPriority
    
    -- Try to buy perks in order of priority
    for _, perkName in ipairs(perkPriority) do
        local perk = self.Perks[perkName]
        if perk then
            local currentLevel = botData.selectedPerks[perkName] or 0
            
            -- Check if we can buy this perk
            if currentLevel < perk.maxLevel and botData.perkPoints >= perk.cost then
                -- Decide whether to buy based on personality and situation
                local shouldBuy = self:BotShouldBuyPerk(bot, botData, perkName)
                
                if shouldBuy then
                    local success, reason = self:BuyPerk(bot, perkName)
                    if success then
                        botData.selectedPerks[perkName] = currentLevel + 1
                        botData.perkPoints = botData.perkPoints - perk.cost
                        bot:ChatPrint(bot:Nick() .. " bought " .. perk.name .. " (Level " .. botData.selectedPerks[perkName] .. ")")
                        break -- Only buy one perk per decision cycle
                    end
                end
            end
        end
    end
end

-- Determine if bot should buy a specific perk
function GM:BotShouldBuyPerk(bot, botData, perkName)
    local config = botData.config
    
    -- Aggressive bots prioritize combat perks when health is low
    if config.behavior == "rush" then
        if perkName == "soldier" and bot:Health() < 50 then
            return true
        end
        if perkName == "tank" and bot:Health() < 30 then
            return true
        end
    end
    
    -- Defensive bots prioritize engineer and tank
    if config.behavior == "hold_position" then
        if perkName == "engineer" then
            return true
        end
        if perkName == "tank" then
            return true
        end
    end
    
    -- Support bots prioritize medic
    if config.behavior == "follow_teammates" then
        if perkName == "medic" then
            return true
        end
    end
    
    -- Economic bots prioritize merchant early
    if config.behavior == "farm_kills" then
        if perkName == "merchant" and (botData.selectedPerks["merchant"] or 0) < 2 then
            return true
        end
    end
    
    -- Default: buy based on priority list
    return math.random() > 0.3
end

-- Bot decides what to buy from shop
function GM:BotDecideShop(bot, botData)
    if botData.money < 100 then return end
    
    -- Check health first
    if bot:Health() < 50 then
        local success = self:BuyItem(bot, "healthkit")
        if success then
            botData.money = botData.money - 100
            return
        end
    end
    
    -- Check armor
    if bot:Armor() < 30 then
        local success = self:BuyItem(bot, "armor")
        if success then
            botData.money = botData.money - 120
            return
        end
    end
    
    -- Buy weapons based on preference
    for _, weaponName in ipairs(botData.config.weaponPreference) do
        if not bot:HasWeapon(weaponName) then
            local item = self.ShopItems[weaponName]
            if item and botData.money >= item.cost then
                local success = self:BuyItem(bot, weaponName)
                if success then
                    botData.money = botData.money - item.cost
                    bot:ChatPrint(bot:Nick() .. " bought " .. item.name)
                    return
                end
            end
        end
    end
    
    -- Buy ammo for current weapon
    local activeWeapon = bot:GetActiveWeapon()
    if IsValid(activeWeapon) then
        local ammoType = activeWeapon:GetPrimaryAmmoType()
        if ammoType ~= -1 then
            local ammoName = game.GetAmmoName(ammoType)
            
            -- Find matching ammo item
            for itemName, itemData in pairs(self.ShopItems) do
                if itemData.category == "ammo" and itemData.ammoType == ammoName then
                    if botData.money >= itemData.cost then
                        local success = self:BuyItem(bot, itemName)
                        if success then
                            botData.money = botData.money - itemData.cost
                            return
                        end
                    end
                end
            end
        end
    end
end

-- Bot decides where to place turret
function GM:BotDecideTurret(bot, botData)
    if not botData.selectedPerks["engineer"] then return end
    
    local maxTurrets = botData.selectedPerks["engineer"] * 2
    if botData.turretsPlaced >= maxTurrets then return end
    
    if botData.money < 200 then return end
    
    -- Find a good position for turret
    local botPos = bot:GetPos()
    local forward = bot:GetForward()
    local trace = util.TraceLine({
        start = botPos + Vector(0, 0, 50),
        endpos = botPos + forward * 300 + Vector(0, 0, 50),
        filter = bot
    })
    
    if trace.Hit then
        -- Place turret
        self:PlaceTurret(trace.HitPos, bot)
        botData.money = botData.money - 200
        botData.turretsPlaced = botData.turretsPlaced + 1
        bot:ChatPrint(bot:Nick() .. " placed a sentry turret!")
    end
end

-- Handle bot death
function GM:BotDeath(bot)
    local botData = self.Bots[bot]
    if not botData then return end
    
    -- Lose some money on death
    botData.money = math.floor(botData.money * 0.8)
    botData.turretsPlaced = 0 -- Turrets are lost
    
    bot:ChatPrint(bot:Nick() .. " died! Lost 20% money and all turrets")
end

-- Spawn bots command
concommand.Add("horde_spawn_bot", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then
        if ply:IsValid() then ply:ChatPrint("Only admins can spawn bots!") end
        return
    end
    
    local name = args[1] or "Bot"
    local personality = args[2] or nil
    
    GAMEMODE:CreateBot(name, personality)
end, nil, "Spawn a bot with optional name and personality")

-- Remove all bots command
concommand.Add("horde_remove_bots", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then
        if ply:IsValid() then ply:ChatPrint("Only admins can remove bots!") end
        return
    end
    
    for bot, _ in pairs(GAMEMODE.Bots) do
        if IsValid(bot) then
            GAMEMODE:RemoveBot(bot)
        end
    end
    
    print("[Horde Survival] Removed all bots")
end, nil, "Remove all bots")

-- Hook into player death for bots
hook.Add("PlayerDeath", "HordeSurvival_BotDeath", function(victim, inflictor, attacker)
    if IsValid(victim) and victim:IsPlayer() and victim.IsBot then
        GAMEMODE:BotDeath(victim)
    end
end)

-- Hook into think for bot AI
hook.Add("Think", "HordeSurvival_BotThink", function()
    for bot, _ in pairs(GAMEMODE.Bots or {}) do
        if IsValid(bot) and bot:Alive() then
            GAMEMODE:BotThink(bot)
        end
    end
end)
