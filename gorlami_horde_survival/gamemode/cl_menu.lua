-- Client-side menu system
-- Handles perk selection, shop, and other UI

local PerkMenu = nil
local ShopMenu = nil

-- Open perk menu
function OpenPerkMenu()
    if IsValid(PerkMenu) then
        PerkMenu:Remove()
        return
    end
    
    PerkMenu = vgui.Create("DFrame")
    PerkMenu:SetSize(600, 500)
    PerkMenu:Center()
    PerkMenu:SetTitle("Perk Selection")
    PerkMenu:SetVisible(true)
    PerkMenu:SetDraggable(true)
    PerkMenu:ShowCloseButton(true)
    PerkMenu:MakePopup()
    
    local ply = LocalPlayer()
    
    -- Perk points display
    local pointsLabel = vgui.Create("DLabel", PerkMenu)
    pointsLabel:SetPos(20, 30)
    pointsLabel:SetSize(560, 25)
    pointsLabel:SetText("Perk Points: " .. (ply.PerkPoints or 0))
    pointsLabel:SetFont("DermaLarge")
    pointsLabel:SetTextColor(Color(100, 200, 255))
    
    -- Perk list
    local perkList = vgui.Create("DPanelList", PerkMenu)
    perkList:SetPos(20, 60)
    perkList:SetSize(560, 380)
    perkList:EnableVerticalScrollbar(true)
    perkList:SetSpacing(5)
    perkList:SetPadding(5)
    
    -- Define perks
    local perks = {
        ["engineer"] = {name = "Engineer", desc = "Place sentry turrets (Level " .. ((ply.SelectedPerks and ply.SelectedPerks["engineer"]) or 0) .. "/3)", cost = 1},
        ["medic"] = {name = "Medic", desc = "Heal faster (Level " .. ((ply.SelectedPerks and ply.SelectedPerks["medic"]) or 0) .. "/3)", cost = 1},
        ["soldier"] = {name = "Soldier", desc = "Increased damage (Level " .. ((ply.SelectedPerks and ply.SelectedPerks["soldier"]) or 0) .. "/3)", cost = 1},
        ["tank"] = {name = "Tank", desc = "More health and armor (Level " .. ((ply.SelectedPerks and ply.SelectedPerks["tank"]) or 0) .. "/3)", cost = 1},
        ["scout"] = {name = "Scout", desc = "Faster movement (Level " .. ((ply.SelectedPerks and ply.SelectedPerks["scout"]) or 0) .. "/3)", cost = 1},
        ["merchant"] = {name = "Merchant", desc = "More money from kills (Level " .. ((ply.SelectedPerks and ply.SelectedPerks["merchant"]) or 0) .. "/3)", cost = 1}
    }
    
    for perkName, perkData in pairs(perks) do
        local perkPanel = vgui.Create("DPanel")
        perkPanel:SetTall(60)
        
        local nameLabel = vgui.Create("DLabel", perkPanel)
        nameLabel:SetPos(10, 5)
        nameLabel:SetSize(400, 20)
        nameLabel:SetText(perkData.name)
        nameLabel:SetFont("DermaDefaultBold")
        
        local descLabel = vgui.Create("DLabel", perkPanel)
        descLabel:SetPos(10, 25)
        descLabel:SetSize(400, 20)
        descLabel:SetText(perkData.desc)
        
        local costLabel = vgui.Create("DLabel", perkPanel)
        costLabel:SetPos(420, 5)
        costLabel:SetSize(100, 20)
        costLabel:SetText("Cost: " .. perkData.cost .. " PP")
        costLabel:SetTextColor(Color(255, 215, 0))
        
        local buyButton = vgui.Create("DButton", perkPanel)
        buyButton:SetPos(420, 30)
        buyButton:SetSize(130, 25)
        buyButton:SetText("Purchase")
        buyButton.DoClick = function()
            net.Start("BuyPerk")
                net.WriteString(perkName)
            net.SendToServer()
        end
        
        -- Check if max level
        if (ply.SelectedPerks and ply.SelectedPerks[perkName]) and ply.SelectedPerks[perkName] >= 3 then
            buyButton:SetEnabled(false)
            buyButton:SetText("MAX LEVEL")
        end
        
        perkList:AddItem(perkPanel)
    end
    
    -- Respec button
    local respecButton = vgui.Create("DButton", PerkMenu)
    respecButton:SetPos(20, 450)
    respecButton:SetSize(200, 30)
    respecButton:SetText("Respec All Perks")
    respecButton.DoClick = function()
        net.Start("RespecPerks")
        net.SendToServer()
        OpenPerkMenu() -- Refresh
    end
    
    -- Close button
    local closeButton = vgui.Create("DButton", PerkMenu)
    closeButton:SetPos(380, 450)
    closeButton:SetSize(200, 30)
    closeButton:SetText("Close")
    closeButton.DoClick = function()
        PerkMenu:Remove()
        PerkMenu = nil
    end
end

-- Open shop menu
function OpenShopMenu()
    if IsValid(ShopMenu) then
        ShopMenu:Remove()
        return
    end
    
    ShopMenu = vgui.Create("DFrame")
    ShopMenu:SetSize(700, 550)
    ShopMenu:Center()
    ShopMenu:SetTitle("Weapon Shop")
    ShopMenu:SetVisible(true)
    ShopMenu:SetDraggable(true)
    ShopMenu:ShowCloseButton(true)
    ShopMenu:MakePopup()
    
    local ply = LocalPlayer()
    
    -- Money display
    local moneyLabel = vgui.Create("DLabel", ShopMenu)
    moneyLabel:SetPos(20, 30)
    moneyLabel:SetSize(660, 25)
    moneyLabel:SetText("Money: $" .. (ply.Money or 0))
    moneyLabel:SetFont("DermaLarge")
    moneyLabel:SetTextColor(Color(255, 215, 0))
    
    -- Category selector
    local categorySelector = vgui.Create("DComboBox", ShopMenu)
    categorySelector:SetPos(20, 60)
    categorySelector:SetSize(200, 25)
    categorySelector:AddChoice("Weapons", "weapons", true)
    categorySelector:AddChoice("Ammo", "ammo")
    categorySelector:AddChoice("Health", "health")
    categorySelector:AddChoice("Armor", "armor")
    categorySelector:AddChoice("Equipment", "equipment")
    
    -- Item list
    local itemList = vgui.Create("DPanelList", ShopMenu)
    itemList:SetPos(20, 95)
    itemList:SetSize(660, 400)
    itemList:EnableVerticalScrollbar(true)
    itemList:SetSpacing(5)
    itemList:SetPadding(5)
    
    -- Shop items
    local shopItems = {
        ["weapon_shotgun"] = {name = "Shotgun", desc = "Close-range powerhouse", cost = 800, category = "weapons"},
        ["weapon_smg1"] = {name = "SMG", desc = "Fast firing submachine gun", cost = 600, category = "weapons"},
        ["weapon_ar2"] = {name = "Assault Rifle", desc = "Versatile automatic rifle", cost = 1200, category = "weapons"},
        ["weapon_pistol"] = {name = "Pistol Ammo (50)", desc = "Ammunition for pistol", cost = 50, category = "ammo"},
        ["weapon_shotgun_ammo"] = {name = "Shotgun Shells (20)", desc = "Ammunition for shotgun", cost = 75, category = "ammo"},
        ["weapon_smg1_ammo"] = {name = "SMG Ammo (90)", desc = "Ammunition for SMG", cost = 60, category = "ammo"},
        ["weapon_ar2_ammo"] = {name = "AR2 Ammo (60)", desc = "Ammunition for Assault Rifle", cost = 100, category = "ammo"},
        ["healthkit"] = {name = "Health Kit", desc = "Restores 50 health", cost = 100, category = "health"},
        ["medkit_large"] = {name = "Large Health Kit", desc = "Restores 100 health", cost = 180, category = "health"},
        ["armor"] = {name = "Armor Kit", desc = "Restores 50 armor", cost = 120, category = "armor"},
        ["armor_large"] = {name = "Large Armor Kit", desc = "Restores 100 armor", cost = 200, category = "armor"},
        ["grenade"] = {name = "Frag Grenade", desc = "Explosive grenade", cost = 150, category = "equipment"}
    }
    
    local function UpdateItemList(category)
        itemList:Clear()
        
        for itemName, itemData in pairs(shopItems) do
            if itemData.category == category then
                local itemPanel = vgui.Create("DPanel")
                itemPanel:SetTall(60)
                
                local nameLabel = vgui.Create("DLabel", itemPanel)
                nameLabel:SetPos(10, 5)
                nameLabel:SetSize(400, 20)
                nameLabel:SetText(itemData.name)
                nameLabel:SetFont("DermaDefaultBold")
                
                local descLabel = vgui.Create("DLabel", itemPanel)
                descLabel:SetPos(10, 25)
                descLabel:SetSize(400, 20)
                descLabel:SetText(itemData.desc)
                
                local costLabel = vgui.Create("DLabel", itemPanel)
                costLabel:SetPos(520, 5)
                costLabel:SetSize(100, 20)
                costLabel:SetText("$" .. itemData.cost)
                costLabel:SetTextColor(Color(255, 215, 0))
                
                local buyButton = vgui.Create("DButton", itemPanel)
                buyButton:SetPos(520, 30)
                buyButton:SetSize(130, 25)
                buyButton:SetText("Buy")
                buyButton.DoClick = function()
                    net.Start("BuyItem")
                        net.WriteString(itemName)
                    net.SendToServer()
                end
                
                -- Check if can afford
                if (ply.Money or 0) < itemData.cost then
                    buyButton:SetEnabled(false)
                    buyButton:SetText("Too Expensive")
                end
                
                itemList:AddItem(itemPanel)
            end
        end
    end
    
    categorySelector.OnSelect = function(panel, index, value, data)
        UpdateItemList(data)
    end
    
    -- Initialize with weapons
    UpdateItemList("weapons")
    
    -- Close button
    local closeButton = vgui.Create("DButton", ShopMenu)
    closeButton:SetPos(480, 500)
    closeButton:SetSize(200, 30)
    closeButton:SetText("Close")
    closeButton.DoClick = function()
        ShopMenu:Remove()
        ShopMenu = nil
    end
end

-- Bind keys to open menus
hook.Add("Think", "HordeSurvival_MenuKeys", function()
    if input.IsKeyDown(KEY_F1) then
        if not IsValid(PerkMenu) then
            timer.Simple(0.5, function()
                OpenPerkMenu()
            end)
        end
    end
    
    if input.IsKeyDown(KEY_F2) then
        if not IsValid(ShopMenu) then
            timer.Simple(0.5, function()
                OpenShopMenu()
            end)
        end
    end
end)

-- Network receiving for server responses
net.Receive("PerkUpdate", function()
    local success = net.ReadBool()
    local message = net.ReadString()
    
    if success then
        notification.AddLegacy(message, NOTIFY_GENERIC, 3)
    else
        notification.AddLegacy(message, NOTIFY_ERROR, 3)
    end
    
    -- Refresh menu if open
    if IsValid(PerkMenu) then
        OpenPerkMenu()
    end
end)

net.Receive("ShopUpdate", function()
    local success = net.ReadBool()
    local message = net.ReadString()
    
    if success then
        notification.AddLegacy(message, NOTIFY_GENERIC, 3)
    else
        notification.AddLegacy(message, NOTIFY_ERROR, 3)
    end
    
    -- Refresh menu if open
    if IsValid(ShopMenu) then
        OpenShopMenu()
    end
end)

print("[Horde Survival] Menu module loaded!")
print("Press F1 for Perks, F2 for Shop")
