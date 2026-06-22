-- Shared shop system
-- Defines items that can be purchased with money

GM.ShopItems = {
    ["weapon_shotgun"] = {
        name = "Shotgun",
        description = "Close-range powerhouse",
        cost = 800,
        category = "weapons"
    },
    ["weapon_smg1"] = {
        name = "SMG",
        description = "Fast firing submachine gun",
        cost = 600,
        category = "weapons"
    },
    ["weapon_ar2"] = {
        name = "Assault Rifle",
        description = "Versatile automatic rifle",
        cost = 1200,
        category = "weapons"
    },
    ["weapon_pistol"] = {
        name = "Pistol Ammo",
        description = "Ammunition for pistol",
        cost = 50,
        category = "ammo",
        ammoType = "Pistol",
        amount = 50
    },
    ["weapon_shotgun_ammo"] = {
        name = "Shotgun Shells",
        description = "Ammunition for shotgun",
        cost = 75,
        category = "ammo",
        ammoType = "Buckshot",
        amount = 20
    },
    ["weapon_smg1_ammo"] = {
        name = "SMG Ammo",
        description = "Ammunition for SMG",
        cost = 60,
        category = "ammo",
        ammoType = "SMG1",
        amount = 90
    },
    ["weapon_ar2_ammo"] = {
        name = "AR2 Ammo",
        description = "Ammunition for Assault Rifle",
        cost = 100,
        category = "ammo",
        ammoType = "AR2",
        amount = 60
    },
    ["healthkit"] = {
        name = "Health Kit",
        description = "Restores 50 health",
        cost = 100,
        category = "health",
        healAmount = 50
    },
    ["medkit_large"] = {
        name = "Large Health Kit",
        description = "Restores 100 health",
        cost = 180,
        category = "health",
        healAmount = 100
    },
    ["armor"] = {
        name = "Armor Kit",
        description = "Restores 50 armor",
        cost = 120,
        category = "armor",
        armorAmount = 50
    },
    ["armor_large"] = {
        name = "Large Armor Kit",
        description = "Restores 100 armor",
        cost = 200,
        category = "armor",
        armorAmount = 100
    },
    ["grenade"] = {
        name = "Frag Grenade",
        description = "Explosive grenade",
        cost = 150,
        category = "equipment"
    }
}

-- Check if player can buy item
function GM:PlayerCanBuyItem(ply, itemName)
    local item = self.ShopItems[itemName]
    if not item then return false, "Invalid item" end
    
    if ply.Money < item.cost then
        return false, "Not enough money"
    end
    
    return true
end

-- Buy an item
function GM:BuyItem(ply, itemName)
    local canBuy, reason = self:PlayerCanBuyItem(ply, itemName)
    if not canBuy then return false, reason end
    
    local item = self.ShopItems[itemName]
    
    -- Deduct money
    ply.Money = ply.Money - item.cost
    
    -- Give item based on category
    if item.category == "weapons" then
        ply:Give(itemName)
        
        -- Give starting ammo
        if itemName == "weapon_shotgun" then
            ply:GiveAmmo(40, "Buckshot")
        elseif itemName == "weapon_smg1" then
            ply:GiveAmmo(90, "SMG1")
        elseif itemName == "weapon_ar2" then
            ply:GiveAmmo(60, "AR2")
        end
        
        ply:ChatPrint("Purchased " .. item.name)
        
    elseif item.category == "ammo" then
        ply:GiveAmmo(item.amount, item.ammoType)
        ply:ChatPrint("Purchased " .. item.name)
        
    elseif item.category == "health" then
        local newHealth = math.min(ply:GetMaxHealth(), ply:Health() + item.healAmount)
        ply:SetHealth(newHealth)
        ply:ChatPrint("Used " .. item.name)
        
    elseif item.category == "armor" then
        local newArmor = math.min(ply:GetMaxArmor(), ply:Armor() + item.armorAmount)
        ply:SetArmor(newArmor)
        ply:ChatPrint("Used " .. item.name)
        
    elseif item.category == "equipment" then
        if itemName == "grenade" then
            ply:Give("weapon_grenade")
            ply:ChatPrint("Purchased Grenade")
        end
    end
    
    return true, "Purchase successful!"
end

-- Get shop items by category
function GM:GetShopItemsByCategory(category)
    local items = {}
    
    for itemName, itemData in pairs(self.ShopItems) do
        if itemData.category == category then
            items[itemName] = itemData
        end
    end
    
    return items
end
