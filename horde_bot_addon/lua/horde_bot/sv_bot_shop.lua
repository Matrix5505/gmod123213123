-- Bot shop usage system
HordeBot = HordeBot or {}

function HordeBot.BotUseShop(bot, data)
    if not IsValid(bot) or not bot:Alive() then return end
    
    local personality = data.personality
    local priorities = HordeBot.ShopPriorities[personality]
    if not priorities then return end
    
    -- Get bot's money
    local money = 0
    if bot.GetMoney then
        money = bot:GetMoney()
    elseif bot.Money then
        money = bot.Money
    end
    
    -- Not enough money to buy anything
    if money < 50 then return end
    
    -- Try to buy items based on priority
    for _, itemType in ipairs(priorities) do
        local bought = HordeBot.BotBuyItem(bot, data, itemType, money)
        if bought then break end
    end
end

function HordeBot.BotBuyItem(bot, data, itemType, money)
    local health = bot:Health()
    local armor = bot:Armor and bot:Armor() or 0
    
    -- Health purchase logic
    if itemType == "health" and health < 70 and money >= 100 then
        HordeBot.AttemptBuy(bot, "medkit", 100)
        HordeBot.Debug("Bot " .. bot:Nick() .. " bought health")
        return true
    end
    
    -- Armor purchase logic
    if itemType == "armor" and armor < 70 and money >= 150 then
        HordeBot.AttemptBuy(bot, "armor", 150)
        HordeBot.Debug("Bot " .. bot:Nick() .. " bought armor")
        return true
    end
    
    -- Ammo purchase logic
    if itemType == "ammo" and money >= 50 then
        -- Check if low on ammo
        local weapon = bot:GetActiveWeapon()
        if IsValid(weapon) then
            local clip = weapon:Clip1() or 0
            local maxClip = weapon:GetMaxClip1() or 30
            if clip < maxClip * 0.5 then
                HordeBot.AttemptBuy(bot, "ammo", 50)
                HordeBot.Debug("Bot " .. bot:Nick() .. " bought ammo")
                return true
            end
        end
    end
    
    -- Weapon purchase logic (if poor weapon)
    if itemType == "weapon" and money >= 500 then
        local weapon = bot:GetActiveWeapon()
        if not IsValid(weapon) or weapon:GetClass() == "weapon_pistol" then
            HordeBot.AttemptBuy(bot, "rifle", 500)
            HordeBot.Debug("Bot " .. bot:Nick() .. " bought weapon")
            return true
        end
    end
    
    -- Grenade purchase logic
    if itemType == "grenade" and money >= 200 then
        if math.random(1, 100) > 60 then
            HordeBot.AttemptBuy(bot, "grenade", 200)
            HordeBot.Debug("Bot " .. bot:Nick() .. " bought grenade")
            return true
        end
    end
    
    -- Turret purchase for engineers
    if itemType == "turret" and data.currentPerk == "engineer" and money >= 300 then
        if not data.turretPlaced then
            HordeBot.AttemptBuy(bot, "turret", 300)
            HordeBot.Debug("Bot " .. bot:Nick() .. " bought turret")
            return true
        end
    end
    
    return false
end

function HordeBot.AttemptBuy(bot, item, cost)
    -- Get bot data for tracking
    local data = HordeBot.GetBotData(bot)
    
    -- Method 1: Try gamemode's buy function
    if GAMEMODE and GAMEMODE.BuyItem then
        local success = GAMEMODE:BuyItem(bot, item)
        if success then
            if data then data.moneySpent = (data.moneySpent or 0) + cost end
            print("[Horde Bot] Bot " .. bot:Nick() .. " bought " .. item .. " via GAMEMODE:BuyItem")
            return
        end
    end
    
    -- Method 2: Try net request
    if ShopBuyRequest then
        ShopBuyRequest(bot, item)
        if data then data.moneySpent = (data.moneySpent or 0) + cost end
        print("[Horde Bot] Bot " .. bot:Nick() .. " bought " .. item .. " via ShopBuyRequest")
        return
    end
    
    -- Method 3: Concommand approach
    bot:ConCommand("horde_buy " .. item)
    if data then data.moneySpent = (data.moneySpent or 0) + cost end
    print("[Horde Bot] Bot " .. bot:Nick() .. " used concommand to buy " .. item)
    
    -- Simulate purchase locally for tracking
    if bot.SetMoney then
        local currentMoney = bot:GetMoney and bot:GetMoney() or bot.Money or 1000
        bot:SetMoney(currentMoney - cost)
    elseif bot.Money then
        bot.Money = bot.Money - cost
    end
end

-- Determine what item to buy based on situation
function HordeBot.GetNeededItem(bot, data)
    local health = bot:Health()
    local armor = bot:Armor and bot:Armor() or 0
    local money = bot.GetMoney and bot:GetMoney() or bot.Money or 0
    
    -- Critical health
    if health < 30 and money >= 100 then
        return "health"
    end
    
    -- Low armor
    if armor < 30 and money >= 150 then
        return "armor"
    end
    
    -- Engineer without turret
    if data.currentPerk == "engineer" and not data.turretPlaced and money >= 300 then
        return "turret"
    end
    
    -- Default to ammo
    return "ammo"
end

print("[Horde Bot] Shop system loaded")
