horde_bot_addon
================

Horde Bot Addon for Gorlami's Horde Wave Survival

INSTALLATION:
-------------
1. Place this folder in: garrysmod/addons/horde_bot_addon/
2. Make sure you have "Gorlami's Horde Wave Survival" gamemode installed
3. Start Garry's Mod and load the Horde Wave Survival gamemode
4. Use console commands (admin required):
   - horde_spawn_bot [name] [personality] - Spawn a bot
   - horde_remove_bots - Remove all bots
   - horde_bot_debug 1/0 - Toggle debug output

PERSONALITIES:
--------------
- aggressive: Focuses on combat, high damage output
- defensive: Places turrets, stays near objectives  
- support: Heals teammates, provides ammo
- economic: Earns money faster, buys better gear

FEATURES:
---------
- Bots automatically select and upgrade perks based on their personality
- Bots use the shop to buy weapons, ammo, health, armor, and equipment
- Engineer bots place and manage sentry turrets automatically
- Medic bots heal nearby players and bots
- Bots adapt to combat situations with different behaviors
- Full integration with Horde Wave Survival mechanics
- Bots work with existing perk and shop systems

COMMANDS:
---------
- horde_spawn_bot [name] [personality] - Spawn a bot with optional name and personality
- horde_remove_bots - Remove all spawned bots
- horde_bot_debug - Toggle debug output in console
- horde_bot_debug_hud - Toggle debug HUD overlay

EXAMPLES:
---------
- horde_spawn_bot John aggressive - Spawn an aggressive bot named John
- horde_spawn_bot Sarah engineer - Spawn a defensive bot named Sarah
- horde_remove_bots - Clean up all bots

REQUIREMENTS:
-------------
- Gorlami's Horde Wave Survival gamemode
- Garry's Mod

TROUBLESHOOTING:
----------------
If commands don't work:
1. Make sure the addon is in garrysmod/addons/horde_bot_addon/
2. Check that the gamemode is loaded
3. Verify you have admin privileges
4. Check console for error messages
5. Enable debug mode with: horde_bot_debug

NOTES:
------
- Bots will automatically try to integrate with the gamemode's perk and shop systems
- If the gamemode uses different function names, bots will fall back to concommands
- Engineer bots need the Engineer perk to place turrets
- Bots periodically reassess their perks and purchases

