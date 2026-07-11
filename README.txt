ShadowRotation v1.0.2
Intelligent Shadow Priest assistant for Turtle WoW

FEATURES
- Modular, independently movable HUD trackers
- No-background layout by default
- Next-spell recommendation and prediction queue
- DoT and cooldown tracking
- Solo, Dungeon, Raid, and PvP profiles
- Rotation packs: Standard, Mana Saver, Max DPS, PvP Pressure, and Leveling
- Smart aura verification and failed-DoT recovery
- Rotation Coach, fight history, analytics, trends, and tuning suggestions
- Profile import/export
- Minimap button
- System health and module self-check

INSTALLATION
1. Close Turtle WoW.
2. Delete any old Interface\AddOns\ShadowRotation folder.
3. Extract the included ShadowRotation folder into:
   Turtle WoW\Interface\AddOns\
4. Confirm this file exists:
   Turtle WoW\Interface\AddOns\ShadowRotation\ShadowRotation.toc
5. Start the game.

RECOMMENDED MACRO
/script ShadowRotation()

FIRST-RUN CHECK
/shadow version
/shadow modules

The module check should finish with:
System Status: READY

CORE COMMANDS
/shadow options          Open settings
/shadow version          Show installed version
/shadow modules          Verify every module loaded
/shadow diagnose         Print technical diagnostics
/shadow resetui          Reset tracker positions
/shadow lock             Lock trackers
/shadow unlock           Unlock trackers
/shadow minimap on       Show minimap button
/shadow recoverui        Recover trackers and minimap

PROFILES
/shadow profile solo
/shadow profile dungeon
/shadow profile raid
/shadow profile pvp
/shadow profile save
/shadow profile reset pvp
/shadow profileio        Open profile import/export

ROTATION PACKS
/shadow pack standard
/shadow pack mana
/shadow pack maxdps
/shadow pack pvp
/shadow pack leveling

COACHING AND ANALYTICS
/shadow report
/shadow coach
/shadow analytics
/shadow insights
/shadow trends
/shadow stats
/shadow tune
/shadow why
/shadow simulate

HUD PRESETS
/shadow preset custom
/shadow preset minimal
/shadow preset classic
/shadow preset compact
/shadow preset streamer

TROUBLESHOOTING
Missing .toc file:
The ShadowRotation.toc file must be directly inside the ShadowRotation addon folder.

Trackers missing:
/shadow recoverui
/shadow tracker on
/shadow dots on
/shadow cds on
/shadow queue on

Minimap button missing:
/shadow minimap on

Unexpected Lua error:
/shadow modules
/shadow diagnose

SUPPORT
When reporting a problem, include:
- the exact error text
- /shadow version
- /shadow modules output
- what you were doing when it happened

LIMITATIONS
Turtle WoW uses a Vanilla-era API. Some uptime, missed-opportunity, and coaching values are estimates rather than combat-log-perfect measurements.
