-- Client-side bot HUD
HordeBot = HordeBot or {}

local botStatus = {}

net.Receive("HordeBot_UpdateBotStatus", function()
    local bot = net.ReadEntity()
    local status = net.ReadString()
    
    if IsValid(bot) then
        botStatus[bot] = {
            status = status,
            lastUpdate = CurTime()
        }
    end
end)

-- Draw bot info on screen (optional debug)
hook.Add("HUDPaint", "HordeBot_DebugHUD", function()
    if not GetConVar("horde_bot_debug_hud") or GetConVar("horde_bot_debug_hud"):GetInt() == 0 then
        return
    end
    
    local y = 100
    for bot, data in pairs(botStatus) do
        if IsValid(bot) and CurTime() - data.lastUpdate < 5 then
            local botData = HordeBot.GetBotData(bot)
            if botData then
                draw.SimpleText(
                    bot:Nick() .. " [" .. botData.personality .. "] - " .. data.status,
                    "DermaLarge",
                    10, y,
                    Color(255, 255, 255, 255),
                    TEXT_ALIGN_LEFT
                )
                y = y + 25
            end
        end
    end
end)

concommand.Add("horde_bot_debug_hud", function(ply, cmd, args)
    local currentValue = GetConVar("horde_bot_debug_hud") and GetConVar("horde_bot_debug_hud"):GetInt() or 0
    RunConsoleCommand("horde_bot_debug_hud", currentValue == 0 and "1" or "0")
    chat.AddText(Color(100, 200, 100), "[Horde Bot] Debug HUD: " .. (currentValue == 0 and "ON" or "OFF"))
end)

print("[Horde Bot] Client HUD loaded")
