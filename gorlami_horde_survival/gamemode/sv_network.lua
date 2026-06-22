-- Server-side network handlers for perk and shop systems

-- Network strings
util.AddNetworkString("BuyPerk")
util.AddNetworkString("RespecPerks")
util.AddNetworkString("BuyItem")
util.AddNetworkString("PerkUpdate")
util.AddNetworkString("ShopUpdate")

-- Handle perk purchase from client
net.Receive("BuyPerk", function(len, ply)
    if not IsValid(ply) then return end
    
    local perkName = net.ReadString()
    
    if not perkName then return end
    
    local success, message = GAMEMODE:BuyPerk(ply, perkName)
    
    -- Send response to client
    net.Start("PerkUpdate")
        net.WriteBool(success)
        net.WriteString(message or (success and "Perk purchased!" or "Purchase failed"))
    net.Send(ply)
    
    if success then
        ply:ChatPrint("Purchased " .. GAMEMODE.Perks[perkName].name .. "!")
    else
        ply:ChatPrint("Cannot buy perk: " .. (message or "Unknown error"))
    end
end)

-- Handle perk respec from client
net.Receive("RespecPerks", function(len, ply)
    if not IsValid(ply) then return end
    
    local pointsRefunded = GAMEMODE:RespecPerks(ply)
    
    ply:ChatPrint("Perks reset! Refunded " .. pointsRefunded .. " perk points")
    
    -- Send update to client
    net.Start("PerkUpdate")
        net.WriteBool(true)
        net.WriteString("Perks reset successfully!")
    net.Send(ply)
end)

-- Handle item purchase from client
net.Receive("BuyItem", function(len, ply)
    if not IsValid(ply) then return end
    
    local itemName = net.ReadString()
    
    if not itemName then return end
    
    local success, message = GAMEMODE:BuyItem(ply, itemName)
    
    -- Send response to client
    net.Start("ShopUpdate")
        net.WriteBool(success)
        net.WriteString(message or (success and "Item purchased!" or "Purchase failed"))
    net.Send(ply)
    
    if success then
        local item = GAMEMODE.ShopItems[itemName]
        if item then
            ply:ChatPrint("Bought " .. item.name .. "!")
        end
    else
        ply:ChatPrint("Cannot buy item: " .. (message or "Unknown error"))
    end
end)

-- Turret placement command (can be bound to a key)
concommand.Add("horde_place_turret", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    -- Check if player is engineer
    if not (ply.SelectedPerks and ply.SelectedPerks["engineer"]) then
        ply:ChatPrint("You need the Engineer perk to place turrets!")
        return
    end
    
    -- Get position in front of player
    local pos = ply:GetPos() + ply:GetForward() * 100
    
    -- Place turret
    local turret = GAMEMODE:PlaceTurret(pos, ply)
    
    if not turret then
        ply:ChatPrint("Cannot place turret here!")
    end
end, nil, "Place a sentry turret (requires Engineer perk)")

print("[Horde Survival] Network handlers loaded!")
