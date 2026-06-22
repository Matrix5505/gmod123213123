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
    
    -- Initialize bot system after everything is loaded
    timer.Simple(2.0, function()
        if not HordeBot.Initialized then
            print("[HordeBot] Initializing Bot System...")
            
            -- Create a global table for active bots if it doesn't exist
            if not HordeBot.ActiveBots then
                HordeBot.ActiveBots = {}
            end
            
            -- Detect gamemode and set up hooks
            local gmName = GAMEMODE and GAMEMODE.Name or "unknown"
            print("[HordeBot] Detected gamemode: " .. gmName)
            
            -- Start the main bot think loop
            timer.Create("HordeBot_ThinkLoop", 1.0, 0, function()
                if HordeBot.ThinkAllBots then
                    HordeBot.ThinkAllBots()
                end
            end)
            
            HordeBot.Initialized = true
            print("[HordeBot] Bot System Initialized! Spawn bots with 'horde_spawn_bot [name] [personality]'")
        end
    end)
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
