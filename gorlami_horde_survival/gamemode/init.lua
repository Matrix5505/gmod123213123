-- Gorlami's Horde Wave Survival - Main Initialization
-- This file initializes the gamemode and bot system

if SERVER then
    AddCSLuaFile("cl_init.lua")
    AddCSLuaFile("shared.lua")
    
    -- Include server-side files
    include("sh_perks.lua")
    include("sh_shop.lua")
    include("sv_bots.lua")
    include("sv_waves.lua")
    include("sv_turrets.lua")
    include("sv_network.lua")
end

if CLIENT then
    include("cl_init.lua")
end

include("shared.lua")

-- Register the gamemode
GM.Name = "Gorlami's Horde Wave Survival"
GM.Author = "Gorlami"
GM.Email = "N/A"
GM.Website = "N/A"

function GM:Initialize()
    print("[Horde Survival] Gamemode initialized!")
    
    if SERVER then
        -- Initialize game state
        GAMEMODE.WaveNumber = 0
        GAMEMODE.WaveActive = false
        GAMEMODE.BotsEnabled = true
        GAMEMODE.MaxBots = 8
        
        -- Start first wave after delay
        timer.Simple(5, function()
            if IsValid(GAMEMODE) then
                GAMEMODE:StartWave()
            end
        end)
    end
end

function GM:StartWave()
    if self.WaveActive then return end
    
    self.WaveNumber = self.WaveNumber + 1
    self.WaveActive = true
    
    print("[Horde Survival] Starting Wave " .. self.WaveNumber)
    
    -- Spawn zombies based on wave number
    local zombieCount = 5 + (self.WaveNumber * 2)
    
    for i = 1, zombieCount do
        timer.Simple(i * 2, function()
            if self.WaveActive then
                self:SpawnZombie()
            end
        end)
    end
    
    -- Check for wave completion
    timer.Create("WaveCheck_" .. self.WaveNumber, 2, 0, function()
        if not self.WaveActive then return end
        
        local zombies = ents.FindByClass("npc_zombie")
        local zombieCount = #zombies
        
        if zombieCount == 0 then
            self:EndWave()
        end
    end)
end

function GM:SpawnZombie()
    local spawnPoints = ents.FindByClass("info_player_start")
    if #spawnPoints == 0 then return end
    
    local spawnPoint = spawnPoints[math.random(#spawnPoints)]
    local pos = spawnPoint:GetPos() + Vector(math.random(-200, 200), math.random(-200, 200), 0)
    
    local zombie = ents.Create("npc_zombie")
    zombie:SetPos(pos)
    zombie:Spawn()
    zombie:Activate()
    
    -- Scale zombie health with wave number
    local baseHealth = 100
    zombie:SetHealth(baseHealth + (self.WaveNumber * 10))
end

function GM:EndWave()
    if not self.WaveActive then return end
    
    self.WaveActive = false
    timer.Remove("WaveCheck_" .. self.WaveNumber)
    
    print("[Horde Survival] Wave " .. self.WaveNumber .. " completed!")
    
    -- Give players time to prepare
    timer.Simple(10, function()
        if IsValid(GAMEMODE) then
            self:StartWave()
        end
    end)
end

function GM:PlayerSpawn(ply)
    ply:SetModel("models/player/group03/male_07.mdl")
    ply:SetHealth(100)
    ply:SetArmor(50)
    
    -- Give starting weapon
    ply:Give("weapon_pistol")
    ply:GiveAmmo(250, "Pistol")
    
    if SERVER then
        -- Initialize player data
        ply.PerkPoints = 0
        ply.Money = 500
        ply.SelectedPerks = {}
    end
end

function GM:PlayerDeath(ply, inflictor, attacker)
    timer.Simple(3, function()
        if IsValid(ply) then
            ply:Spawn()
        end
    end)
end

function GM:OnNPCKilled(npc, attacker, inflictor)
    if npc:GetClass() == "npc_zombie" then
        if IsValid(attacker) and attacker:IsPlayer() then
            attacker.Money = (attacker.Money or 0) + 25
            attacker.PerkPoints = (attacker.PerkPoints or 0) + 1
            
            attacker:ChatPrint("Killed zombie! +$25, +1 Perk Point")
        end
    end
end
