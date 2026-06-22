-- Shared perks system
-- Defines all available perks and their effects

GM.Perks = {
    ["engineer"] = {
        name = "Engineer",
        description = "Can place sentry turrets",
        cost = 1,
        maxLevel = 3,
        icon = "icon16/wrench.png"
    },
    ["medic"] = {
        name = "Medic",
        description = "Heal yourself and teammates faster",
        cost = 1,
        maxLevel = 3,
        icon = "icon16/heart.png"
    },
    ["soldier"] = {
        name = "Soldier",
        description = "Increased weapon damage",
        cost = 1,
        maxLevel = 3,
        icon = "icon16/crosshair.png"
    },
    ["tank"] = {
        name = "Tank",
        description = "Increased health and armor",
        cost = 1,
        maxLevel = 3,
        icon = "icon16/shield.png"
    },
    ["scout"] = {
        name = "Scout",
        description = "Increased movement speed",
        cost = 1,
        maxLevel = 3,
        icon = "icon16/run.png"
    },
    ["merchant"] = {
        name = "Merchant",
        description = "Get more money from kills",
        cost = 1,
        maxLevel = 3,
        icon = "icon16/money.png"
    }
}

-- Apply perk effects to player
function GM:ApplyPerks(ply)
    if not IsValid(ply) then return end
    
    -- Reset all perk effects first
    ply:SetRunSpeed(250)
    ply:SetWalkSpeed(125)
    ply:SetMaxHealth(100)
    ply:SetMaxArmor(100)
    
    -- Apply each selected perk
    for perkName, level in pairs(ply.SelectedPerks or {}) do
        local perk = self.Perks[perkName]
        if perk then
            if perkName == "engineer" then
                -- Engineer gets turret building ability
                ply.CanBuildTurrets = true
                ply.MaxTurrets = level * 2
            elseif perkName == "medic" then
                -- Medic heals faster
                ply.HealMultiplier = 1 + (level * 0.2)
            elseif perkName == "soldier" then
                -- Soldier deals more damage
                ply.DamageMultiplier = 1 + (level * 0.15)
            elseif perkName == "tank" then
                -- Tank has more health and armor
                ply:SetMaxHealth(100 + (level * 25))
                ply:SetMaxArmor(100 + (level * 25))
                ply:SetHealth(ply:GetMaxHealth())
                ply:SetArmor(ply:GetMaxArmor())
            elseif perkName == "scout" then
                -- Scout moves faster
                ply:SetRunSpeed(250 + (level * 30))
                ply:SetWalkSpeed(125 + (level * 15))
            elseif perkName == "merchant" then
                -- Merchant gets more money
                ply.MoneyMultiplier = 1 + (level * 0.25)
            end
        end
    end
end

-- Check if player can afford perk
function GM:PlayerCanBuyPerk(ply, perkName)
    local perk = self.Perks[perkName]
    if not perk then return false, "Invalid perk" end
    
    local currentLevel = ply.SelectedPerks[perkName] or 0
    if currentLevel >= perk.maxLevel then
        return false, "Max level reached"
    end
    
    if ply.PerkPoints < perk.cost then
        return false, "Not enough perk points"
    end
    
    return true
end

-- Buy a perk
function GM:BuyPerk(ply, perkName)
    local canBuy, reason = self:PlayerCanBuyPerk(ply, perkName)
    if not canBuy then return false, reason end
    
    ply.SelectedPerks[perkName] = (ply.SelectedPerks[perkName] or 0) + 1
    ply.PerkPoints = ply.PerkPoints - self.Perks[perkName].cost
    
    self:ApplyPerks(ply)
    
    return true, "Perk purchased!"
end

-- Respec perks (refund all points)
function GM:RespecPerks(ply)
    local totalPoints = 0
    
    for perkName, level in pairs(ply.SelectedPerks) do
        totalPoints = totalPoints + level
    end
    
    ply.PerkPoints = ply.PerkPoints + totalPoints
    ply.SelectedPerks = {}
    
    self:ApplyPerks(ply)
    
    return totalPoints
end
