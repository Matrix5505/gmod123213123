-- Shared gamemode file
-- Contains shared definitions and utilities

GM.Name = "Gorlami's Horde Wave Survival"
GM.Author = "Gorlami"
GM.TeamBased = false

-- Player extension functions
local PLAYER_METATABLE = FindMetaTable("Player")

-- Get player's money
function PLAYER_METATABLE:GetMoney()
    return self.Money or 0
end

-- Set player's money
function PLAYER_METATABLE:SetMoney(amount)
    self.Money = amount
end

-- Add money to player
function PLAYER_METATABLE:AddMoney(amount)
    self.Money = (self.Money or 0) + amount
end

-- Remove money from player
function PLAYER_METATABLE:RemoveMoney(amount)
    self.Money = math.max(0, (self.Money or 0) - amount)
end

-- Get player's perk points
function PLAYER_METATABLE:GetPerkPoints()
    return self.PerkPoints or 0
end

-- Check if player has a weapon
function PLAYER_METATABLE:HasWeapon(weaponClass)
    local weapons = self:GetWeapons()
    
    for _, wep in ipairs(weapons) do
        if IsValid(wep) and wep:GetClass() == weaponClass then
            return true
        end
    end
    
    return false
end

-- Utility function to check if entity is a bot
function PLAYER_METATABLE:IsBot()
    return self.IsBot or false
end

-- Global utility functions
function GetPlayersAlive()
    local count = 0
    
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            count = count + 1
        end
    end
    
    return count
end

function GetTotalZombies()
    local count = 0
    
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent:GetClass() == "npc_zombie" and ent:Alive() then
            count = count + 1
        end
    end
    
    return count
end

-- Network strings (defined on both sides for safety)
if CLIENT then
    net.Receive("WaveStart", function()
        local waveNum = net.ReadInt(16)
        local zombieCount = net.ReadInt(16)
        
        notification.AddLegacy("Wave " .. waveNum .. " started! (" .. zombieCount .. " zombies)", NOTIFY_GENERIC, 5)
        surface.PlaySound("buttons/blip1.wav")
    end)
    
    net.Receive("WaveEnd", function()
        local waveNum = net.ReadInt(16)
        
        notification.AddLegacy("Wave " .. waveNum .. " completed!", NOTIFY_GENERIC, 5)
        surface.PlaySound("buttons/button19.wav")
    end)
    
    net.Receive("WaveUpdate", function()
        local remaining = net.ReadInt(16)
        local spawned = net.ReadInt(16)
        
        -- Could update HUD here
    end)
    
    net.Receive("TurretPlaced", function()
        local turret = net.ReadEntity()
        local owner = net.ReadEntity()
        
        if IsValid(turret) and IsValid(owner) then
            -- Visual effect for turret placement
        end
    end)
    
    net.Receive("TurretRemoved", function()
        local turret = net.ReadEntity()
        
        if IsValid(turret) then
            -- Visual effect for turret removal
        end
    end)
end

print("[Horde Survival] Shared module loaded!")
