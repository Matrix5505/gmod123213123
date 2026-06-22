-- Bot AI combat and behavior system
HordeBot = HordeBot or {}

function HordeBot.BotCombatBehavior(bot, data)
    if not IsValid(bot) or not bot:Alive() then return end
    
    local curTime = CurTime()
    
    -- Find enemies
    local enemies = HordeBot.FindEnemies(bot)
    
    if #enemies > 0 then
        data.lastCombatTime = curTime
        
        -- Pick a target
        local target = HordeBot.SelectTarget(bot, enemies)
        data.targetEnemy = target
        
        -- Combat actions based on personality
        if data.personality == HordeBot.Personalities.AGGRESSIVE then
            HordeBot.AggressiveBehavior(bot, data, target)
        elseif data.personality == HordeBot.Personalities.DEFENSIVE then
            HordeBot.DefensiveBehavior(bot, data, target)
        elseif data.personality == HordeBot.Personalities.SUPPORT then
            HordeBot.SupportBehavior(bot, data, target)
        else
            HordeBot.EconomicBehavior(bot, data, target)
        end
        
        -- Shoot at target
        HordeBot.BotShootAtTarget(bot, target)
    else
        -- No enemies, idle behavior
        data.targetEnemy = nil
        HordeBot.BotIdleBehavior(bot, data)
    end
    
    -- Use abilities based on perk
    HordeBot.BotUseAbilities(bot, data)
end

function HordeBot.FindEnemies(bot)
    local enemies = {}
    local botPos = bot:GetPos()
    local searchRadius = 1500
    
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent ~= bot then
            -- Check if it's a zombie or enemy
            local isEnemy = false
            
            if ent:IsPlayer() then
                -- Enemy player (if PvP enabled)
                if ent:Team() ~= bot:Team() then
                    isEnemy = true
                end
            elseif string.find(ent:GetClass(), "zombie") or 
                   string.find(ent:GetClass(), "horde") or
                   ent:GetClass() == "npc_zombie" then
                isEnemy = true
            end
            
            if isEnemy and ent:GetPos():DistToSqr(botPos) < searchRadius * searchRadius then
                -- Check line of sight
                local trace = util.TraceLine({
                    start = bot:EyePos(),
                    endpos = ent:EyePos(),
                    filter = bot,
                    mask = MASK_SOLID
                })
                
                if not trace.Hit or trace.Fraction > 0.9 then
                    table.insert(enemies, ent)
                end
            end
        end
    end
    
    return enemies
end

function HordeBot.SelectTarget(bot, enemies)
    if #enemies == 0 then return nil end
    
    -- Pick closest enemy
    local closest = nil
    local closestDist = math.huge
    local botPos = bot:GetPos()
    
    for _, enemy in ipairs(enemies) do
        if IsValid(enemy) then
            local dist = enemy:GetPos():DistToSqr(botPos)
            if dist < closestDist then
                closestDist = dist
                closest = enemy
            end
        end
    end
    
    return closest
end

function HordeBot.AggressiveBehavior(bot, data, target)
    if not IsValid(target) then return end
    
    local botPos = bot:GetPos()
    local targetPos = target:GetPos()
    local dist = botPos:DistToSqr(targetPos)
    
    -- Move closer if too far
    if dist > 40000 then -- ~200 units
        local moveDir = (targetPos - botPos):GetNormalized()
        local movePos = botPos + moveDir * 150
        
        bot:ConCommand("go_to_position " .. movePos.x .. " " .. movePos.y .. " " .. movePos.z)
    end
end

function HordeBot.DefensiveBehavior(bot, data, target)
    if not IsValid(target) then return end
    
    local botPos = bot:GetPos()
    local targetPos = target:GetPos()
    local dist = botPos:DistToSqr(targetPos)
    
    -- Keep medium distance
    if dist < 10000 then -- Too close, back up (~100 units)
        local moveDir = (botPos - targetPos):GetNormalized()
        local movePos = botPos + moveDir * 200
        
        bot:ConCommand("go_to_position " .. movePos.x .. " " .. movePos.y .. " " .. movePos.z)
    elseif dist > 90000 then -- Too far, move closer (~300 units)
        local moveDir = (targetPos - botPos):GetNormalized()
        local movePos = botPos + moveDir * 150
        
        bot:ConCommand("go_to_position " .. movePos.x .. " " .. movePos.y .. " " .. movePos.z)
    end
end

function HordeBot.SupportBehavior(bot, data, target)
    -- Look for teammates to heal/support
    local teammates = HordeBot.FindTeammates(bot)
    
    for _, teammate in ipairs(teammates) do
        if IsValid(teammate) and teammate:Health() < 50 then
            -- Move towards injured teammate
            local movePos = teammate:GetPos()
            bot:ConCommand("go_to_position " .. movePos.x .. " " .. movePos.y .. " " .. movePos.z)
            return
        end
    end
    
    -- If no injured teammates, fight normally
    if IsValid(target) then
        HordeBot.DefensiveBehavior(bot, data, target)
    end
end

function HordeBot.EconomicBehavior(bot, data, target)
    -- Stay alive, avoid combat when possible
    if not IsValid(target) then return end
    
    local botPos = bot:GetPos()
    local targetPos = target:GetPos()
    local dist = botPos:DistToSqr(targetPos)
    
    -- Keep far distance
    if dist < 160000 then -- ~400 units
        local moveDir = (botPos - targetPos):GetNormalized()
        local movePos = botPos + moveDir * 300
        
        bot:ConCommand("go_to_position " .. movePos.x .. " " .. movePos.y .. " " .. movePos.z)
    end
end

function HordeBot.BotShootAtTarget(bot, target)
    if not IsValid(target) or not IsValid(bot) then return end
    
    -- Aim at target
    local aimPos = target:EyePos()
    local botEyePos = bot:EyePos()
    local aimDir = (aimPos - botEyePos):GetNormalized()
    
    -- Set bot's look direction
    local angles = aimDir:Angle()
    bot:SetEyeAngles(angles)
    
    -- Try to fire weapon
    local weapon = bot:GetActiveWeapon()
    if IsValid(weapon) then
        -- Check if target is in view
        local trace = util.TraceLine({
            start = botEyePos,
            endpos = aimPos,
            filter = bot,
            mask = MASK_SOLID
        })
        
        if trace.Entity == target or not trace.Hit then
            -- Fire!
            bot:ConCommand("+attack")
            
            -- Stop firing after short burst
            timer.Simple(0.2, function()
                if IsValid(bot) then
                    bot:ConCommand("-attack")
                end
            end)
        end
    end
end

function HordeBot.BotIdleBehavior(bot, data)
    -- Random movement or stay near objective
    local curTime = CurTime()
    
    -- Occasionally move to random position
    if math.random(1, 100) > 80 then
        local botPos = bot:GetPos()
        local randomOffset = Vector(math.random(-500, 500), math.random(-500, 500), 0)
        local movePos = botPos + randomOffset
        
        bot:ConCommand("go_to_position " .. movePos.x .. " " .. movePos.y .. " " .. movePos.z)
    end
end

function HordeBot.BotUseAbilities(bot, data)
    if not IsValid(bot) or not bot:Alive() then return end
    
    local curTime = CurTime()
    
    -- Medic: Heal nearby teammates
    if data.currentPerk == "medic" then
        local teammates = HordeBot.FindTeammates(bot)
        for _, teammate in ipairs(teammates) do
            if IsValid(teammate) and teammate:Health() < 80 and teammate ~= bot then
                if teammate:GetPos():DistToSqr(bot:GetPos()) < 30000 then -- ~173 units
                    -- Use medkit on teammate
                    bot:ConCommand("use_medkit_on_player " .. teammate:EntIndex())
                    break
                end
            end
        end
    end
    
    -- Soldier: Use grenades when surrounded
    if data.currentPerk == "soldier" then
        local enemies = HordeBot.FindEnemies(bot)
        if #enemies >= 3 then
            local avgPos = Vector(0, 0, 0)
            for _, enemy in ipairs(enemies) do
                avgPos = avgPos + enemy:GetPos()
            end
            avgPos = avgPos / #enemies
            
            if avgPos:DistToSqr(bot:GetPos()) < 250000 then -- ~500 units
                bot:ConCommand("use_grenade")
            end
        end
    end
end

function HordeBot.FindTeammates(bot)
    local teammates = {}
    local botTeam = bot:Team()
    
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and ply ~= bot then
            if ply:Team() == botTeam then
                table.insert(teammates, ply)
            end
        end
    end
    
    return teammates
end

print("[Horde Bot] AI combat system loaded")
