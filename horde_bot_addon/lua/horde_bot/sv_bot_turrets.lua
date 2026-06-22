-- Bot turret placement and management for Engineers
HordeBot = HordeBot or {}

local turretEntities = {}

function HordeBot.BotPlaceTurret(bot, data)
    if not IsValid(bot) or not bot:Alive() then return end
    if data.currentPerk ~= "engineer" then return end
    if data.turretPlaced and IsValid(data.currentTurret) then return end
    
    -- Check if bot has enough money
    local money = bot.GetMoney and bot:GetMoney() or bot.Money or 0
    if money < 300 then return end
    
    -- Find good turret position
    local turretPos = HordeBot.FindTurretPosition(bot)
    if not turretPos then
        HordeBot.Debug("Bot " .. bot:Nick() .. " couldn't find turret position")
        return
    end
    
    -- Move to position first
    if bot:EyePos():DistToSqr(turretPos) > 20000 then -- ~141 units
        bot:ConCommand("go_to_position " .. turretPos.x .. " " .. turretPos.y .. " " .. turretPos.z)
        return
    end
    
    -- Place the turret
    HordeBot.SpawnTurret(bot, turretPos, data)
end

function HordeBot.FindTurretPosition(bot)
    local botPos = bot:EyePos()
    local forward = bot:GetForward()
    
    -- Search in front of bot for valid position
    for i = 1, 5 do
        local offset = forward * (100 + i * 50)
        local pos = botPos + offset + Vector(0, 0, -50)
        
        -- Check if position is valid
        local trace = util.TraceLine({
            start = botPos,
            endpos = pos,
            filter = bot,
            mask = MASK_SOLID
        })
        
        if not trace.Hit then
            -- Check if ground is solid
            local groundTrace = util.TraceLine({
                start = pos + Vector(0, 0, 100),
                endpos = pos - Vector(0, 0, 100),
                filter = bot,
                mask = MASK_SOLID
            })
            
            if groundTrace.Hit and not groundTrace.StartSolid then
                local groundPos = groundTrace.HitPos
                HordeBot.Debug("Bot " .. bot:Nick() .. " found turret position at " .. tostring(groundPos))
                return groundPos
            end
        end
    end
    
    -- Fallback: position slightly in front and below bot
    local fallbackPos = botPos + forward * 150 + Vector(0, 0, -60)
    return fallbackPos
end

function HordeBot.SpawnTurret(bot, pos, data)
    -- Try to spawn using gamemode function
    if GAMEMODE and GAMEMODE.PlaceTurret then
        local turret = GAMEMODE:PlaceTurret(bot, pos)
        if IsValid(turret) then
            data.currentTurret = turret
            data.turretPlaced = true
            turretEntities[turret] = {owner = bot, placedTime = CurTime()}
            HordeBot.Debug("Bot " .. bot:Nick() .. " placed turret via gamemode")
            return turret
        end
    end
    
    -- Try concommand
    bot:ConCommand("horde_place_turret")
    data.turretPlaced = true
    
    -- Look for newly created turret entity
    timer.Simple(0.5, function()
        if not IsValid(bot) then return end
        
        local turrets = ents.FindByClass("horde_turret")
        if #turrets == 0 then
            turrets = ents.FindByClass("sent_turret")
        end
        if #turrets == 0 then
            turrets = ents.FindByClass("prop_dynamic")
        end
        
        -- Find closest turret to position
        local closestTurret = nil
        local closestDist = 500
        
        for _, turret in ipairs(turrets) do
            local dist = turret:GetPos():DistToSqr(pos)
            if dist < closestDist then
                closestDist = dist
                closestTurret = turret
            end
        end
        
        if closestTurret then
            data.currentTurret = closestTurret
            turretEntities[closestTurret] = {owner = bot, placedTime = CurTime()}
            HordeBot.Debug("Bot " .. bot:Nick() .. " placed turret via concommand")
        end
    end)
    
    return nil
end

function HordeBot.RemoveTurret(bot, data)
    if not data then return end
    
    if IsValid(data.currentTurret) then
        local turret = data.currentTurret
        turretEntities[turret] = nil
        data.currentTurret:Remove()
        HordeBot.Debug("Bot " .. bot:Nick() .. " turret removed")
    end
    
    data.turretPlaced = false
    data.currentTurret = nil
end

-- Clean up turrets when owner dies
hook.Add("PlayerDeath", "HordeBot_CleanupTurrets", function(victim, inflictor, attacker)
    if not HordeBot.IsBot(victim) then return end
    
    local data = HordeBot.GetBotData(victim)
    if data then
        HordeBot.RemoveTurret(victim, data)
    end
end)

-- Clean up turrets when bot disconnects
hook.Add("PlayerDisconnected", "HordeBot_CleanupTurretsDisconnect", function(ply)
    if not HordeBot.IsBot(ply) then return end
    
    local data = HordeBot.GetBotData(ply)
    if data then
        HordeBot.RemoveTurret(ply, data)
    end
    
    HordeBot.Bots[ply] = nil
end)

print("[Horde Bot] Turret system loaded")
