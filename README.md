# Dataclysm

Dataclysm is a 2D turn-based artillery game built with Godot Engine (v4.4), inspired by classic games like Worms. Players take turns firing tech-themed projectiles at each other on destructible terrain.

![Dataclysm Logo](/assets/Dataclysm.png)

## Features

- **Turn-based Artillery Gameplay**: 2-player combat with destructible terrain
- **Technology-themed Weapons**: Fire computer peripherals and components as projectiles
- **Destructible Terrain**: Carve out the landscape with explosions
- **Physics-based Combat**: Projectile damage scales with velocity
- **Jetpack Movement**: Limited jetpack fuel for vertical movement
- **Character Customization**: Multiple character skins to choose from
- **Steam Integration**: Uses GodotSteam extension for Steam features
- **Multi-platform Support**: Windows, Linux, Web, and Android

## Controls

- **W/S**: Adjust firing angle (up/down)
- **A/D**: Move left/right
- **Space**: Hold to charge shot, release to fire
- **Ctrl**: Activate jetpack (limited fuel per turn)
- **F1**: Toggle help menu

## Game Mechanics

### Turn System
Players alternate turns. Each turn allows movement, aiming, and firing a projectile. After firing or player death, the turn passes to the next player.

### Movement
- Use A/D to move horizontally
- Use Ctrl to activate jetpack for vertical movement (limited fuel per turn)

### Combat
1. Aim with W/S to adjust angle
2. Hold Space to charge shot (more power = more distance)
3. Release Space to fire
4. Projectile damage scales with impact velocity

### Terrain
- Procedurally generated terrain with hills and valleys
- Destructible terrain using polygon clipping
- Chunk-based destruction system for performance

## Installation

### Windows/Linux
1. Download the latest release from the Releases section
2. Extract the archive
3. Run the executable

### Android
1. Download the APK from the Releases section
2. Install the APK on your device
3. Launch the app

### Web
Play directly in your browser at [URL TBD]

## Development

### Requirements
- Godot Engine 4.4 or higher
- GodotSteam extension (included)

### Building from Source
1. Clone this repository
2. Open the project in Godot Engine
3. Export for your desired platform using the included export presets

## Credits

- Character sprites: "Platformer Characters 1" 
- Key icons: "Double" keyboard asset pack
- Technology projectiles: Custom assets

## License

[License information TBD]