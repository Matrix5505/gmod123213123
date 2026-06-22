-- Wave Management System
-- Handles spawning and managing zombie waves

if SERVER then
    util.AddNetworkString("WaveStart")
    util.AddNetworkString("WaveEnd")
    util.AddNetworkString("WaveUpdate")
end

GM.WaveZombies = {}
GM.WaveSettings = {
    [1] = {count = 5, healthMult = 1.0, delay = 2},
    [2] = {count = 8, healthMult = 1.1, delay = 1.8},
    [3] = {count = 10, healthMult = 1.2, delay = 1.6},
    [4] = {count = 12, healthMult = 1.3, delay = 1.5},
    [5] = {count = 15, healthMult = 1.4, delay = 1.4},
    [6] = {count = 18, healthMult = 1.5, delay = 1.3},
    [7] = {count = 20, healthMult = 1.6, delay = 1.2},
    [8] = {count = 22, healthMult = 1.7, delay = 1.1},
    [9] = {count = 25, healthMult = 1.8, delay = 1.0},
    [10] = {count = 30, healthMult = 2.0, delay = 0.9}
}

-- Override the StartWave function from init.lua with enhanced version
function GM:StartWave()
    if self.WaveActive then return end
    
    self.WaveNumber = self.WaveNumber + 1
    self.WaveActive = true
    self.ZombiesRemaining = 0
    self.ZombiesSpawned = 0
    
    -- Get wave settings or generate for higher waves
    local waveSettings = self.WaveSettings[self.WaveNumber]
    if not waveSettings then
        -- Generate settings for waves beyond 10
        waveSettings = {
            count = 30 + ((self.WaveNumber - 10) * 5),
            healthMult = 2.0 + ((self.WaveNumber - 10) * 0.1),
            delay = math.max(0.5, 0.9 - ((self.WaveNumber - 10) * 0.05))
        }
    end
    
    print("[Horde Survival] Starting Wave " .. self.WaveNumber .. " - " .. waveSettings.count .. " zombies!")
    
    -- Notify clients
    net.Start("WaveStart")
        net.WriteInt(self.WaveNumber, 16)
        net.WriteInt(waveSettings.count, 16)
    net.Broadcast()
    
    -- Spawn zombies over time
    local zombiesToSpawn = waveSettings.count
    
    for i = 1, zombiesToSpawn do
        timer.Simple(i * waveSettings.delay, function()
            if self.WaveActive then
                self:SpawnZombie(waveSettings.healthMult)
                self.ZombiesSpawned = self.ZombiesSpawned + 1
                self.ZombiesRemaining = self.ZombiesRemaining + 1
                
                -- Update clients
                net.Start("WaveUpdate")
                    net.WriteInt(self.ZombiesRemaining, 16)
                    net.WriteInt(self.ZombiesSpawned, 16)
                net.Broadcast()
            end
        end)
    end
    
    -- Check for wave completion
    timer.Create("WaveCheck_" .. self.WaveNumber, 2, 0, function()
        if not self.WaveActive then return end
        
        local zombies = ents.FindByClass("npc_zombie")
        local aliveZombies = 0
        
        for _, zombie in ipairs(zombies) do
            if IsValid(zombie) and zombie:Alive() then
                aliveZombies = aliveZombies + 1
            end
        end
        
        self.ZombiesRemaining = aliveZombies
        
        if aliveZombies == 0 and self.ZombiesSpawned >= zombiesToSpawn then
            self:EndWave()
        end
    end)
end

-- Enhanced zombie spawning
function GM:SpawnZombie(healthMult)
    local spawnPoints = ents.FindByClass("info_player_start")
    if #spawnPoints == 0 then
        -- Fallback to random spawn
        local players = player.GetAll()
        if #players == 0 then return end
        
        local randomPlayer = players[math.random(#players)]
        local pos = randomPlayer:GetPos() + Vector(math.random(-500, 500), math.random(-500, 500), 0)
        
        self:CreateZombie(pos, healthMult)
        return
    end
    
    local spawnPoint = spawnPoints[math.random(#spawnPoints)]
    local pos = spawnPoint:GetPos() + Vector(math.random(-200, 200), math.random(-200, 200), 0)
    
    self:CreateZombie(pos, healthMult)
end

function GM:CreateZombie(pos, healthMult)
    local zombie = ents.Create("npc_zombie")
    if not IsValid(zombie) then return end
    
    zombie:SetPos(pos + Vector(0, 0, 50))
    zombie:Spawn()
    zombie:Activate()
    
    -- Scale health with wave
    local baseHealth = 100
    local scaledHealth = baseHealth * (healthMult or 1.0)
    zombie:SetHealth(scaledHealth)
    
    -- Store wave number for reward calculation
    zombie.WaveNumber = self.WaveNumber
    
    -- Add to tracking table
    table.insert(self.WaveZombies, zombie)
    
    -- Clean up when zombie dies
    timer.Create("ZombieCheck_" .. zombie:EntIndex(), 1, 0, function()
        if not IsValid(zombie) or not zombie:Alive() then
            timer.Remove("ZombieCheck_" .. zombie:EntIndex())
            
            -- Remove from tracking
            for i, z in ipairs(self.WaveZombies) do
                if z == zombie then
                    table.remove(self.WaveZombies, i)
                    break
                end
            end
        end
    end)
end

-- End current wave
function GM:EndWave()
    if not self.WaveActive then return end
    
    self.WaveActive = false
    timer.Remove("WaveCheck_" .. self.WaveNumber)
    
    print("[Horde Survival] Wave " .. self.WaveNumber .. " completed!")
    
    -- Notify clients
    net.Start("WaveEnd")
        net.WriteInt(self.WaveNumber, 16)
    net.Broadcast()
    
    -- Bonus for all players
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            local bonusMoney = 100 + (self.WaveNumber * 10)
            local bonusPerks = 2 + math.floor(self.WaveNumber / 2)
            
            ply.Money = (ply.Money or 0) + bonusMoney
            ply.PerkPoints = (ply.PerkPoints or 0) + bonusPerks
            
            ply:ChatPrint("Wave complete! Bonus: $" .. bonusMoney .. ", +" .. bonusPerks .. " Perk Points")
            
            -- Full heal between waves
            ply:SetHealth(ply:GetMaxHealth())
            ply:SetArmor(ply:GetMaxArmor())
        end
    end
    
    -- Prepare for next wave
    local preparationTime = 15 - math.min(10, self.WaveNumber)
    preparationTime = math.max(5, preparationTime)
    
    print("[Horde Survival] Next wave in " .. preparationTime .. " seconds...")
    
    timer.Simple(preparationTime, function()
        if IsValid(GAMEMODE) then
            self:StartWave()
        end
    end)
end

-- Force start a wave (admin command)
concommand.Add("horde_start_wave", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then
        if ply:IsValid() then ply:ChatPrint("Only admins can control waves!") end
        return
    end
    
    local waveNum = tonumber(args[1])
    
    if waveNum and waveNum > 0 then
        GAMEMODE.WaveNumber = waveNum - 1
    end
    
    GAMEMODE:StartWave()
    ply:ChatPrint("Started wave " .. GAMEMODE.WaveNumber)
end, nil, "Force start a wave (optional: wave number)")

-- Skip current wave (admin command)
concommand.Add("horde_skip_wave", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then
        if ply:IsValid() then ply:ChatPrint("Only admins can skip waves!") end
        return
    end
    
    if IsValid(GAMEMODE) then
        GAMEMODE:EndWave()
        ply:ChatPrint("Skipped current wave")
    end
end, nil, "Skip the current wave")

-- Get wave info
concommand.Add("horde_wave_info", function(ply, cmd, args)
    if not IsValid(GAMEMODE) then return end
    
    local info = "Wave: " .. GAMEMODE.WaveNumber
    info = info .. " | Active: " .. tostring(GAMEMODE.WaveActive)
    info = info .. " | Zombies Remaining: " .. (GAMEMODE.ZombiesRemaining or 0)
    
    if ply:IsValid() then
        ply:ChatPrint(info)
    else
        print(info)
    end
end, nil, "Get current wave information")

-- Hook into NPC death for better tracking
hook.Add("OnNPCKilled", "HordeSurvival_WaveTracking", function(npc, attacker, inflictor)
    if npc:GetClass() == "npc_zombie" then
        if IsValid(GAMEMODE) then
            GAMEMODE.ZombiesRemaining = (GAMEMODE.ZombiesRemaining or 0) - 1
        end
        
        if IsValid(attacker) and attacker:IsPlayer() then
            local moneyMultiplier = attacker.MoneyMultiplier or 1
            local waveBonus = 1 + ((npc.WaveNumber or 1) * 0.1)
            
            local moneyReward = math.floor(25 * moneyMultiplier * waveBonus)
            local perkReward = 1
            
            attacker.Money = (attacker.Money or 0) + moneyReward
            attacker.PerkPoints = (attacker.PerkPoints or 0) + perkReward
            
            attacker:ChatPrint("Killed zombie! +$" .. moneyReward .. ", +" .. perkReward .. " Perk Point")
        end
    end
end)
