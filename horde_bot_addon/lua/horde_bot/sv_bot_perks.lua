-- Bot perk selection and management
HordeBot = HordeBot or {}

-- Simulate perk selection by calling gamemode functions
function HordeBot.BotSelectPerk(bot, data)
    if not IsValid(bot) or not bot:Alive() then return end
    
    local personality = data.personality
    local priorities = HordeBot.PerkPriorities[personality]
    if not priorities then return end
    
    -- Get current player perks from gamemode if available
    local currentPerks = {}
    if bot.GetPerks then
        currentPerks = bot:GetPerks() or {}
    end
    
    -- Find best perk to select/upgrade based on priority
    for _, perkName in ipairs(priorities) do
        local canSelect = true
        
        -- Check if already have this perk at max level
        if currentPerks[perkName] and currentPerks[perkName] >= 3 then
            canSelect = false
        end
        
        if canSelect then
            -- Try to select this perk
            HordeBot.AttemptPerkSelection(bot, perkName, data)
            return
        end
    end
end

function HordeBot.AttemptPerkSelection(bot, perkName, data)
    -- Method 1: Try gamemode's perk function
    if GAMEMODE and GAMEMODE.SelectPerk then
        local success = GAMEMODE:SelectPerk(bot, perkName)
        if success then
            data.currentPerk = perkName
            data.perkLevel = (data.perkLevel or 0) + 1
            print("[Horde Bot] Bot " .. bot:Nick() .. " selected perk: " .. perkName .. " via GAMEMODE:SelectPerk")
            return
        end
    end
    
    -- Method 2: Try net request to server
    if PerkSelectRequest then
        PerkSelectRequest(bot, perkName)
        data.currentPerk = perkName
        print("[Horde Bot] Bot " .. bot:Nick() .. " requested perk: " .. perkName .. " via PerkSelectRequest")
        return
    end
    
    -- Method 3: Concommand approach
    bot:ConCommand("horde_select_perk " .. perkName)
    data.currentPerk = perkName
    data.perkLevel = (data.perkLevel or 0) + 1
    print("[Horde Bot] Bot " .. bot:Nick() .. " used concommand for perk: " .. perkName)
end

-- Check if bot should change perk based on situation
function HordeBot.ShouldChangePerk(bot, data)
    local curTime = CurTime()
    
    -- If dead, might want to change perk on respawn
    if not bot:Alive() then
        return true
    end
    
    -- If low health and not medic, consider switching
    if bot:Health() < 30 and data.currentPerk ~= "medic" then
        if math.random(1, 100) > 70 then
            return true
        end
    end
    
    -- If no money and not merchant, consider switching
    local money = bot.GetMoney and bot:GetMoney() or 0
    if money < 100 and data.currentPerk ~= "merchant" then
        if math.random(1, 100) > 80 then
            return true
        end
    end
    
    return false
end

-- Get recommended perk based on current game state
function HordeBot.GetRecommendedPerk(bot, data)
    local priorities = HordeBot.PerkPriorities[data.personality]
    
    -- Count alive teammates and their perks
    local teammatePerks = {}
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and ply ~= bot then
            local pdata = HordeBot.GetBotData(ply)
            if pdata and pdata.currentPerk then
                teammatePerks[pdata.currentPerk] = (teammatePerks[pdata.currentPerk] or 0) + 1
            end
        end
    end
    
    -- Pick highest priority perk that teammates don't have
    for _, perkName in ipairs(priorities) do
        if not teammatePerks[perkName] or teammatePerks[perkName] == 0 then
            return perkName
        end
    end
    
    -- Fallback to highest priority
    return priorities[1]
end

print("[Horde Bot] Perk system loaded")
