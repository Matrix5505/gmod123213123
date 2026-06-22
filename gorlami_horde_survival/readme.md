# Gorlami's Horde Wave Survival

A Garry's Mod horde wave survival gamemode featuring intelligent bots with perk selection, shop system, and engineer turrets.

## Features

### Wave System
- Progressive zombie waves that scale in difficulty
- Configurable wave settings (zombie count, health multiplier, spawn delay)
- Wave completion bonuses (money and perk points)
- Admin commands for wave control

### Bot System
Bots can be spawned with different personalities:
- **Aggressive**: Prioritizes combat perks, rushes enemies
- **Defensive**: Focuses on engineer and tank perks, holds positions
- **Support**: Emphasizes medic perks, follows teammates
- **Economic**: Maximizes merchant perk for more money

Bots automatically:
- Select and upgrade perks based on their personality
- Purchase items from the shop (weapons, ammo, health, armor)
- Place sentry turrets when they have the Engineer perk
- Adapt their behavior based on current situation

### Perk System
Six perks available, each with 3 levels:
- **Engineer**: Place automated sentry turrets
- **Medic**: Increased healing effectiveness
- **Soldier**: Bonus weapon damage
- **Tank**: Extra health and armor
- **Scout**: Faster movement speed
- **Merchant**: More money from kills

Players earn perk points by killing zombies and completing waves.

### Shop System
Purchase items with money earned from kills:
- **Weapons**: Shotgun, SMG, Assault Rifle
- **Ammo**: Various ammunition types
- **Health**: Health kits (small and large)
- **Armor**: Armor kits (small and large)
- **Equipment**: Frag grenades

### Engineer Turrets
- Engineers can place automated sentry turrets
- Turrets automatically target and fire at zombies
- Turret count scales with Engineer perk level
- Turrets have health and can be destroyed

## Installation

1. Copy the `gorlami_horde_survival` folder to your Garry's Mod installation:
   ```
   garrysmod/gamemodes/gorlami_horde_survival/
   ```

2. Start a new game and select "Gorlami's Horde Wave Survival" as the gamemode

3. Or use console command:
   ```
   changelevel gm_construct
   gorlami_horde_survival
   ```

## Commands

### Player Commands
- `horde_place_turret` - Place a sentry turret (requires Engineer perk)
- Press **F1** - Open Perk Menu
- Press **F2** - Open Shop Menu

### Admin Commands
- `horde_spawn_bot [name] [personality]` - Spawn a bot with optional name and personality
- `horde_remove_bots` - Remove all bots
- `horde_start_wave [wave_number]` - Force start a wave (optional: specify wave number)
- `horde_skip_wave` - Skip the current wave
- `horde_wave_info` - Display current wave information
- `horde_remove_turrets` - Remove all turrets owned by player

## Bot Personalities

Spawn bots with specific behaviors:
```
horde_spawn_bot John aggressive
horde_spawn_bot Sarah defensive
horde_spawn_bot Mike support
horde_spawn_bot Dave economic
```

Or let the system choose randomly:
```
horde_spawn_bot
```

## Configuration

Edit the following files to customize the gamemode:

- `gamemode/sh_perks.lua` - Modify perk effects and costs
- `gamemode/sh_shop.lua` - Change shop items and prices
- `gamemode/sv_waves.lua` - Adjust wave settings and scaling
- `gamemode/sv_bots.lua` - Customize bot AI and personalities
- `gamemode/sv_turrets.lua` - Configure turret stats

## Requirements

- Garry's Mod (latest version recommended)
- No additional addons required (uses base GMod content)

## Credits

Created by Gorlami

## License

Free to use and modify for personal and server use.
