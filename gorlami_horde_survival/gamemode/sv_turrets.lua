-- Turret System for Engineer Perk
-- Allows engineers to place automated sentry turrets

if SERVER then
    util.AddNetworkString("TurretPlaced")
    util.AddNetworkString("TurretRemoved")
end

GM.Turrets = {}
GM.MaxTurretsPerPlayer = 6

-- Create a turret entity
function GM:PlaceTurret(pos, owner)
    if not IsValid(owner) or not owner:IsPlayer() then return nil end
    
    -- Check if player is an engineer
    if not (owner.SelectedPerks and owner.SelectedPerks["engineer"]) then
        owner:ChatPrint("You need the Engineer perk to place turrets!")
        return nil
    end
    
    -- Check turret limit
    local currentTurrets = self:GetPlayerTurretCount(owner)
    local maxTurrets = (owner.SelectedPerks["engineer"] or 1) * 2
    
    if currentTurrets >= maxTurrets then
        owner:ChatPrint("Maximum turrets reached! (" .. currentTurrets .. "/" .. maxTurrets .. ")")
        return nil
    end
    
    -- Create turret entity
    local turret = ents.Create("prop_physics")
    if not IsValid(turret) then return nil end
    
    -- Set up turret
    turret:SetPos(pos + Vector(0, 0, 20))
    turret:SetModel("models/props_c17/clock01.mdl")
    turret:Spawn()
    turret:Activate()
    
    -- Make turret static
    turret:PhysicsInit(SOLID_VPHYSICS)
    turret:SetMoveType(MOVETYPE_NONE)
    turret:SetSolid(SOLID_BBOX)
    
    -- Store turret data
    local turretData = {
        entity = turret,
        owner = owner,
        health = 150 + (owner.SelectedPerks["engineer"] * 25),
        damage = 10 + (owner.SelectedPerks["engineer"] * 3),
        range = 500,
        fireRate = 0.5,
        lastFireTime = 0,
        target = nil
    }
    
    turret:SetNWInt("TurretHealth", turretData.health)
    turret:SetNWEntity("TurretOwner", owner)
    turret:SetNWBool("IsTurret", true)
    
    -- Add to turret list
    table.insert(self.Turrets, turretData)
    
    -- Apply physics constraints to keep it in place
    local phys = turret:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end
    
    -- Start turret AI
    timer.Create("TurretThink_" .. turret:EntIndex(), 0.1, 0, function()
        if not IsValid(turret) then
            timer.Remove("TurretThink_" .. turret:EntIndex())
            return
        end
        
        self:TurretThink(turretData)
    end)
    
    owner:ChatPrint("Placed sentry turret! (" .. currentTurrets + 1 .. "/" .. maxTurrets .. ")")
    
    -- Network spawn
    net.Start("TurretPlaced")
        net.WriteEntity(turret)
        net.WriteEntity(owner)
    net.Broadcast()
    
    return turret
end

-- Remove a turret
function GM:RemoveTurret(turret)
    if not IsValid(turret) then return end
    
    -- Find turret data
    local turretData = nil
    for i, data in ipairs(self.Turrets) do
        if data.entity == turret then
            turretData = data
            table.remove(self.Turrets, i)
            break
        end
    end
    
    if turretData then
        timer.Remove("TurretThink_" .. turret:EntIndex())
        
        -- Notify owner
        if IsValid(turretData.owner) then
            local count = self:GetPlayerTurretCount(turretData.owner)
            turretData.owner:ChatPrint("Turret destroyed! (" .. count .. " remaining)")
        end
        
        -- Network removal
        net.Start("TurretRemoved")
            net.WriteEntity(turret)
        net.Broadcast()
    end
    
    -- Remove entity
    turret:Remove()
end

-- Get number of turrets owned by player
function GM:GetPlayerTurretCount(ply)
    local count = 0
    
    for _, turretData in ipairs(self.Turrets) do
        if turretData.owner == ply and IsValid(turretData.entity) then
            count = count + 1
        end
    end
    
    return count
end

-- Turret AI logic
function GM:TurretThink(turretData)
    local turret = turretData.entity
    if not IsValid(turret) then
        self:RemoveTurret(turret)
        return
    end
    
    -- Check health
    local currentHealth = turret:Health()
    if currentHealth <= 0 then
        self:RemoveTurret(turret)
        return
    end
    
    turret:SetNWInt("TurretHealth", currentHealth)
    
    -- Find target
    local target = self:FindTurretTarget(turretData)
    
    if target then
        turretData.target = target
        
        -- Check line of sight
        local trace = util.TraceLine({
            start = turret:GetPos() + Vector(0, 0, 20),
            endpos = target:GetPos() + Vector(0, 0, 50),
            filter = turret
        })
        
        if trace.Entity == target then
            -- Can see target, check range
            local distance = turret:GetPos():Distance(target:GetPos())
            
            if distance <= turretData.range then
                -- Fire at target
                local currentTime = CurTime()
                if currentTime - turretData.lastFireTime >= turretData.fireRate then
                    self:TurretFire(turretData, target)
                    turretData.lastFireTime = currentTime
                end
                
                -- Rotate turret towards target
                local angle = (target:GetPos() - turret:GetPos()):Angle()
                turret:SetAngles(Angle(0, angle.y, 0))
            end
        end
    end
end

-- Find valid target for turret
function GM:FindTurretTarget(turretData)
    local turret = turretData.entity
    local owner = turretData.owner
    
    -- Search for zombies
    local zombies = ents.FindByClass("npc_zombie")
    
    for _, zombie in ipairs(zombies) do
        if IsValid(zombie) and zombie:Alive() then
            local distance = turret:GetPos():Distance(zombie:GetPos())
            
            if distance <= turretData.range then
                return zombie
            end
        end
    end
    
    return nil
end

-- Turret fires at target
function GM:TurretFire(turretData, target)
    local turret = turretData.entity
    
    -- Create effect
    local effectData = EffectData()
    effectData:SetStart(turret:GetPos() + Vector(0, 0, 20))
    effectData:SetOrigin(target:GetPos() + Vector(0, 0, 50))
    effectData:SetScale(1)
    util.Effect("MuzzleEffect", effectData)
    
    -- Deal damage to target
    local damageInfo = DamageInfo()
    damageInfo:SetAttacker(owner)
    damageInfo:SetInflictor(turret)
    damageInfo:SetDamage(turretData.damage)
    damageInfo:SetDamageType(DMG_BULLET)
    
    target:TakeDamageInfo(damageInfo)
    
    -- Sound
    turret:EmitSound("Weapon_AR2.Single", 100, math.random(90, 110))
end

-- Remove all turrets for a player (on death/disconnect)
function GM:RemovePlayerTurrets(ply)
    for i = #self.Turrets, 1, -1 do
        local turretData = self.Turrets[i]
        if turretData.owner == ply and IsValid(turretData.entity) then
            self:RemoveTurret(turretData.entity)
        end
    end
end

-- Hook into player disconnect
hook.Add("PlayerDisconnected", "HordeSurvival_RemoveTurrets", function(ply)
    if IsValid(GAMEMODE) then
        GAMEMODE:RemovePlayerTurrets(ply)
    end
end)

-- Command to remove turrets
concommand.Add("horde_remove_turrets", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then
        if ply:IsValid() then ply:ChatPrint("Only admins can remove turrets!") end
        return
    end
    
    if IsValid(GAMEMODE) then
        GAMEMODE:RemovePlayerTurrets(ply)
        ply:ChatPrint("All your turrets have been removed")
    end
end, nil, "Remove all your turrets")
