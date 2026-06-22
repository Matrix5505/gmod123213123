-- Horde Bot Addon for Gorlami's Horde Wave Survival
-- This addon adds intelligent bots that work with the Horde Wave Survival gamemode

if SERVER then
    -- Load shared file first so constants are available
    AddCSLuaFile("horde_bot/sh_bot_shared.lua")
    AddCSLuaFile("horde_bot/cl_bot_hud.lua")
    
    -- Include shared file on server first
    include("horde_bot/sh_bot_shared.lua")
    
    -- Then include server files
    include("horde_bot/sv_bots.lua")
    include("horde_bot/sv_bot_perks.lua")
    include("horde_bot/sv_bot_shop.lua")
    include("horde_bot/sv_bot_turrets.lua")
    include("horde_bot/sv_bot_ai.lua")
end

if CLIENT then
    include("horde_bot/sh_bot_shared.lua")
    include("horde_bot/cl_bot_hud.lua")
end

print("[Horde Bot Addon] Loaded successfully!")

-- Network setup
if SERVER then
    util.AddNetworkString("HordeBot_UpdateBotStatus")
end
