-- Client-side HUD elements
-- Additional HUD functionality

local HUDColors = {
    health = Color(255, 100, 100),
    armor = Color(100, 100, 255),
    money = Color(255, 215, 0),
    perks = Color(100, 200, 255),
    wave = Color(255, 150, 50)
}

function GM:DrawWaveInfo(waveNum, zombiesRemaining)
    if not waveNum then return end
    
    local x = ScrW() / 2
    local y = 60
    
    -- Wave background
    draw.RoundedBox(8, x - 150, y - 25, 300, 50, Color(0, 0, 0, 150))
    
    -- Wave text
    draw.SimpleText("WAVE " .. waveNum, "DermaLarge", x, y, HUDColors.wave, TEXT_ALIGN_CENTER)
    
    if zombiesRemaining then
        draw.SimpleText(zombiesRemaining .. " enemies remaining", "DermaDefault", x, y + 25, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    end
end

function GM:DrawPlayerStatus(ply)
    if not IsValid(ply) then return end
    
    local x = 20
    local y = ScrH() - 150
    
    -- Status panel background
    draw.RoundedBox(8, x - 10, y - 10, 220, 140, Color(0, 0, 0, 150))
    
    -- Health bar
    local healthPercent = ply:Health() / ply:GetMaxHealth()
    draw.RoundedBox(4, x, y + 20, 200 * healthPercent, 15, HUDColors.health)
    draw.SimpleText("HEALTH", "DermaDefaultBold", x, y, Color(255, 255, 255))
    draw.SimpleText(ply:Health() .. " / " .. ply:GetMaxHealth(), "DermaDefault", x + 200, y + 20, Color(255, 255, 255), TEXT_ALIGN_RIGHT)
    
    -- Armor bar
    y = y + 40
    local armorPercent = ply:Armor() / ply:GetMaxArmor()
    draw.RoundedBox(4, x, y + 20, 200 * armorPercent, 15, HUDColors.armor)
    draw.SimpleText("ARMOR", "DermaDefaultBold", x, y, Color(255, 255, 255))
    draw.SimpleText(ply:Armor() .. " / " .. ply:GetMaxArmor(), "DermaDefault", x + 200, y + 20, Color(255, 255, 255), TEXT_ALIGN_RIGHT)
    
    -- Money and Perk Points
    y = y + 40
    draw.SimpleText("$" .. (ply.Money or 0), "DermaDefaultBold", x, y, HUDColors.money)
    draw.SimpleText("Perk Points: " .. (ply.PerkPoints or 0), "DermaDefault", x, y + 20, HUDColors.perks)
end

function GM:DrawTurretIndicator(turrets)
    if not turrets or #turrets == 0 then return end
    
    local x = ScrW() - 220
    local y = 20
    
    draw.RoundedBox(8, x - 10, y - 10, 220, 30 + (#turrets * 20), Color(0, 0, 0, 150))
    draw.SimpleText("ACTIVE TURRETS", "DermaDefaultBold", x, y, Color(255, 255, 255))
    
    for i, turret in ipairs(turrets) do
        if IsValid(turret.entity) then
            local healthPercent = turret.entity:Health() / turret.health
            local color = Color(
                math.floor(255 * (1 - healthPercent)),
                math.floor(255 * healthPercent),
                0
            )
            
            draw.SimpleText("Turret " .. i .. ": " .. math.floor(healthPercent * 100) .. "%", 
                "DermaDefault", x, y + (i * 20), color)
        end
    end
end

print("[Horde Survival] HUD module loaded!")
