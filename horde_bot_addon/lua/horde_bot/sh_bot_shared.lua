-- Shared bot utilities and constants
HordeBot = HordeBot or {}

HordeBot.Personalities = {
    AGGRESSIVE = "aggressive",
    DEFENSIVE = "defensive",
    SUPPORT = "support",
    ECONOMIC = "economic"
}

HordeBot.BotData = HordeBot.BotData or {}

function HordeBot.GetBotData(ply)
    if not IsValid(ply) or not ply:IsBot() then return nil end
    return HordeBot.BotData[ply]
end

function HordeBot.SetBotData(ply, data)
    if not IsValid(ply) then return end
    HordeBot.BotData[ply] = data
end

function HordeBot.IsBot(ply)
    return IsValid(ply) and ply:IsBot() and HordeBot.BotData[ply] ~= nil
end

-- Perk priorities based on personality
HordeBot.PerkPriorities = {
    [HordeBot.Personalities.AGGRESSIVE] = {"soldier", "tank", "scout", "engineer", "medic", "merchant"},
    [HordeBot.Personalities.DEFENSIVE] = {"engineer", "tank", "soldier", "medic", "scout", "merchant"},
    [HordeBot.Personalities.SUPPORT] = {"medic", "merchant", "engineer", "scout", "soldier", "tank"},
    [HordeBot.Personalities.ECONOMIC] = {"merchant", "scout", "engineer", "medic", "soldier", "tank"}
}

-- Shop item priorities based on personality
HordeBot.ShopPriorities = {
    [HordeBot.Personalities.AGGRESSIVE] = {"weapon", "ammo", "grenade", "armor", "health"},
    [HordeBot.Personalities.DEFENSIVE] = {"turret", "ammo", "armor", "health", "weapon"},
    [HordeBot.Personalities.SUPPORT] = {"health", "ammo", "armor", "weapon", "grenade"},
    [HordeBot.Personalities.ECONOMIC] = {"weapon", "ammo", "armor", "health", "grenade"}
}

if CLIENT then
    net.Receive("HordeBot_UpdateBotStatus", function()
        local bot = net.ReadEntity()
        local status = net.ReadString()
        -- Can be used for HUD updates
    end)
end
