-- Client-side initialization
-- Handles HUD, menus, and client-side functionality

include("cl_hud.lua")
include("cl_menu.lua")

function GM:Initialize()
    print("[Horde Survival] Client initialized!")
    
    -- Initialize HUD elements
    self.HUDVisible = true
    self.LastWaveUpdate = 0
end

function GM:HUDPaint()
    if not self.HUDVisible then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Draw wave info
    draw.SimpleText("HORDE SURVIVAL", "DermaLarge", ScrW() / 2, 30, Color(255, 100, 100), TEXT_ALIGN_CENTER)
    
    -- Draw player stats
    local y = 80
    draw.SimpleText("Health: " .. ply:Health(), "DermaDefault", 20, y, Color(255, 255, 255))
    y = y + 20
    draw.SimpleText("Armor: " .. ply:Armor(), "DermaDefault", 20, y, Color(255, 255, 255))
    y = y + 20
    draw.SimpleText("Money: $" .. (ply.Money or 0), "DermaDefault", 20, y, Color(255, 215, 0))
    y = y + 20
    draw.SimpleText("Perk Points: " .. (ply.PerkPoints or 0), "DermaDefault", 20, y, Color(100, 200, 255))
    
    -- Draw ammo
    local weapon = ply:GetActiveWeapon()
    if IsValid(weapon) then
        local clip = weapon:Clip1()
        local reserve = ply:GetAmmoCount(weapon:GetPrimaryAmmoType())
        
        if clip >= 0 then
            draw.SimpleText("Ammo: " .. clip .. " / " .. reserve, "DermaDefault", 20, ScrH() - 60, Color(255, 255, 255))
        end
    end
    
    -- Draw crosshair
    local cx, cy = ScrW() / 2, ScrH() / 2
    surface.SetDrawColor(0, 255, 0, 200)
    surface.DrawRect(cx - 2, cy - 10, 4, 20)
    surface.DrawRect(cx - 10, cy - 2, 20, 4)
end

function GM:HUDShouldDraw(name)
    if name == "CHudHealth" or name == "CHudBattery" or name == "CHudAmmo" then
        return false -- We draw our own HUD
    end
    return true
end

print("[Horde Survival] Client module loaded!")
