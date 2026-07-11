# ShadowRotation

**An intelligent Shadow Priest assistant for Turtle WoW.**

## Download

Download the latest version from the **Releases** page.

Click **Releases** on the right side of the repository to download the newest version.

`ShadowRotation_v1.0.0_SHAREABLE_INSTALL.zip`

## Installation

1. Close Turtle WoW.
2. Download the release ZIP.
3. Extract the included `ShadowRotation` folder into `Turtle WoW/Interface/AddOns/`.
4. Confirm `Turtle WoW/Interface/AddOns/ShadowRotation/ShadowRotation.toc` exists.
5. Start the game.

## Macro

```text
/script ShadowRotation()
```

## First-run check

```text
/shadow version
/shadow modules
```

The final line should be `System Status: READY`.

## Features

- Separate movable trackers with no background by default
- Next-spell recommendation and prediction queue
- DoT and cooldown tracking
- Solo, Dungeon, Raid, and PvP profiles
- Standard, Mana Saver, Max DPS, PvP Pressure, and Leveling packs
- Smart aura verification and failed-DoT recovery
- Rotation Coach, fight history, analytics, trends, and tuning suggestions
- Profile import/export
- Minimap button and system health check

## Documentation

- [Installation](docs/INSTALL.md)
- [Commands](docs/COMMANDS.md)
- [FAQ](docs/FAQ.md)
- [Changelog](CHANGELOG.md)

## License

MIT
