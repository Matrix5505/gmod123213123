-- Main bot management system
HordeBot = HordeBot or {}
HordeBot.Bots = HordeBot.Bots or {}

local botThinkTimers = {}

-- Spawn a bot with specified personality
function HordeBot.SpawnBot(name, personality, pos)
    if not name then name = "Bot" end
    if not personality then personality = HordeBot.Personalities.AGGRESSIVE end
    
    -- Validate personality
    local validPersonalities = {
        HordeBot.Personalities.AGGRESSIVE,
        HordeBot.Personalities.DEFENSIVE,
        HordeBot.Personalities.SUPPORT,
        HordeBot.Personalities.ECONOMIC
    }
    
    if not table.HasValue(validPersonalities, personality) then
        personality = HordeBot.Personalities.AGGRESSIVE
    end
    
    -- Find spawn position
    local spawnPos = pos or Vector(0, 0, 100)
    local spawns = ents.FindByClass("info_player_start")
    if #spawns > 0 then
        spawnPos = spawns[math.random(#spawns)]:GetPos()
    end
    
    -- Create the bot
    local bot = player.CreateNextBot(name)
    if not IsValid(bot) then
        print("[Horde Bot] Failed to create bot: " .. name)
        return nil
    end
    
    -- Wait for bot to be fully initialized
    timer.Simple(0.1, function()
        if not IsValid(bot) then return end
        
        -- Set up bot data
        local botData = {
            personality = personality,
            currentPerk = nil,
            perkLevel = 0,
            lastShopTime = 0,
            lastPerkCheck = 0,
            turretPlaced = false,
            currentTurret = nil,
            state = "idle",
            targetEnemy = nil,
            lastCombatTime = 0,
            moneySpent = 0,
            kills = 0
        }
        
        HordeBot.SetBotData(bot, botData)
        HordeBot.Bots[bot] = botData
        
        -- Set initial team if gamemode supports it
        if GAMEMODE and GAMEMODE.SetPlayerTeam then
            GAMEMODE:SetPlayerTeam(bot, TEAM_SURVIVORS or 1)
        end
        
        print("[Horde Bot] Spawned bot '" .. name .. "' with personality: " .. personality)
        
        -- Start bot AI loop
        HordeBot.StartBotAI(bot)
    end)
    
    return bot
end

-- Remove all bots
function HordeBot.RemoveAllBots()
    for bot, data in pairs(HordeBot.Bots) do
        if IsValid(bot) then
            -- Remove turret if exists
            if IsValid(data.currentTurret) then
                data.currentTurret:Remove()
            end
            
            bot:Kick("Removed by admin")
        end
    end
    
    HordeBot.Bots = {}
    print("[Horde Bot] Removed all bots")
end

-- Start AI thinking for a bot
function HordeBot.StartBotAI(bot)
    if not IsValid(bot) then return end
    
    local botName = "HordeBot_Think_" .. bot:EntIndex()
    
    -- Stop existing timer if any
    if botThinkTimers[bot] then
        timer.Remove(botName)
    end
    
    -- Create think timer
    timer.Create(botName, 0.5, 0, function()
        if not IsValid(bot) or not HordeBot.IsBot(bot) then
            timer.Remove(botName)
            botThinkTimers[bot] = nil
            return
        end
        
        HordeBot.ThinkBot(bot)
    end)
    
    botThinkTimers[bot] = true
end

-- Main bot AI logic
function HordeBot.ThinkBot(bot)
    local data = HordeBot.GetBotData(bot)
    if not data then return end
    
    local curTime = CurTime()
    
    -- Check if bot is alive
    if not bot:Alive() then
        data.state = "dead"
        data.lastCombatTime = curTime
        return
    end
    
    data.state = "active"
    
    -- Perk selection (every 10 seconds)
    if curTime - data.lastPerkCheck > 10 then
        HordeBot.BotSelectPerk(bot, data)
        data.lastPerkCheck = curTime
    end
    
    -- Shop purchases (every 5 seconds)
    if curTime - data.lastShopTime > 5 then
        HordeBot.BotUseShop(bot, data)
        data.lastShopTime = curTime
    end
    
    -- Turret management for engineers
    if data.currentPerk == "engineer" and not data.turretPlaced then
        HordeBot.BotPlaceTurret(bot, data)
    end
    
    -- Combat behavior
    HordeBot.BotCombatBehavior(bot, data)
    
    -- Update bot status for clients
    if curTime - data.lastCombatTime < 3 then
        net.Start("HordeBot_UpdateBotStatus")
        net.WriteEntity(bot)
        net.WriteString(data.state)
        net.Broadcast()
    end
end

-- Console commands
concommand.Add("horde_spawn_bot", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ply:ChatPrint("[Horde Bot] You need admin privileges to spawn bots")
        return
    end
    
    local name = args[1] or "Bot_" .. math.random(1000, 9999)
    local personality = args[2] or HordeBot.Personalities.AGGRESSIVE
    
    local bot = HordeBot.SpawnBot(name, personality)
    
    if IsValid(ply) then
        ply:ChatPrint("[Horde Bot] Spawned bot: " .. name .. " (" .. personality .. ")")
    end
end, nil, "Spawn a horde bot with optional name and personality")

concommand.Add("horde_remove_bots", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ply:ChatPrint("[Horde Bot] You need admin privileges to remove bots")
        return
    end
    
    HordeBot.RemoveAllBots()
    
    if IsValid(ply) then
        ply:ChatPrint("[Horde Bot] All bots removed")
    end
end, nil, "Remove all horde bots")

local debugMode = false
concommand.Add("horde_bot_debug", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() and not ply:IsSuperAdmin() then
        return
    end
    
    debugMode = not debugMode
    print("[Horde Bot] Debug mode: " .. (debugMode and "ON" or "OFF"))
end, nil, "Toggle bot debug output")

function HordeBot.Debug(msg)
    if debugMode then
        print("[Horde Bot DEBUG] " .. msg)
    end
end

print("[Horde Bot] Bot management system loaded")
