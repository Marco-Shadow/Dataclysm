# Dataclysm - Technical Documentation

## Project Overview

Dataclysm is a turn-based artillery game built with Godot 4, featuring destructible terrain, physics-based projectiles, and a turn-based gameplay system. The game supports multiple players and includes integration with Steam via the GodotSteam extension.

## Architecture

### Engine and Project Configuration

- **Godot Version**: 4.4
- **Rendering**: Uses GL Compatibility mode
- **Physics**: Uses Godot's built-in 2D physics with interpolation

### Core Systems

#### 1. Turn Management System (`turnmanager.gd`)

The central controller managing the game's turn-based gameplay:

- Initializes the game world and spawns players
- Tracks player states (active, dead)
- Handles turn switching logic
- Detects game end conditions
- Provides player lookup functionality

```gdscript
# Key components:
var players: PackedInt32Array = []
var deadplayers: PackedInt32Array = []
var current_player_id: int = 1

# Core methods:
func initialize(p_game, p_world, p_player_scene, p_camera)
func switch_turn()
func mark_dead(id)
func one_player_remaining() -> bool
```

#### 2. Player System (`player.gd`)

Handles player movement, shooting, and state:

- Character movement (horizontal with physics)
- Projectile aiming and trajectory prediction
- Shooting with variable power
- Jetpack mechanics with limited fuel
- Health tracking and death handling

```gdscript
# Key components:
const SPEED = 100.0
const MAX_SHOOT_FORCE = 1500.0
const JETPACK_FORCE = 250.0
var health: float = 100.0
var power_level = 0.0

# Core methods:
func update_trajectory()
func do_shoot()
func die()
```

#### 3. Terrain System (`world.gd`)

Manages the destructible terrain:

- Procedural terrain generation with a smooth curve
- Chunk-based terrain for efficient destruction
- Terrain carving mechanics through projectile impacts
- Player spawn point calculation

```gdscript
# Key components:
const WORLD_WIDTH = 1500
const CHUNK_SIZE = 32
var floor_polygons: Dictionary = {}

# Core methods:
func generate_terrain()
func _on_carve_requested(center: Vector2, radius: float)
func find_player_spawnpoint(camera, player_index, player_count)
```

#### 4. Projectile System (`projectile.gd`)

Controls projectile behavior and effects:

- Physics-based movement with gravity
- Collision detection with terrain and players
- Visual effects (rotation, trace dots)
- Damage calculation based on velocity
- Terrain destruction triggers

```gdscript
# Key components:
var velocity: Vector2 = Vector2.ZERO
var terrain_node: Node2D
var shooter_id: int

# Core methods:
func _physics_process(delta)
func calculate_damage() -> float
func _on_body_entered(body)
```

#### 5. Configuration System (`global_settings.gd`)

Handles game settings and configuration:

- Loads and saves user settings
- Applies display settings (fullscreen, etc.)
- Cross-platform configuration file paths

```gdscript
# Key components:
var config_file = ConfigFile.new()
var config_path: String

# Core methods:
func load_and_apply_settings()
```

### Scene Organization

The game is organized into several key scenes:

1. **Main Menu** (`mainMenu.tscn`)
   - Entry point for the game
   - Navigation to game, options, etc.

2. **Game World** (`game.tscn`)
   - Primary gameplay scene
   - Contains terrain, players, and game logic

3. **Player** (`player.tscn`)
   - Character entity with controls and visuals
   - Contains trajectory visualization

4. **Projectile** (`projectile.tscn`)
   - Fired by players
   - Physics-driven with collision detection

5. **Game Over** (`gameOver.tscn`)
   - End game screen
   - Displays winner and restart options

6. **Options** (`options.tscn`)
   - Game configuration interface

### Asset Organization

- **assets/**: Contains all visual and audio resources
  - Character sprites and animations
  - Projectile graphics
  - UI elements and fonts

- **addons/**: Third-party extensions
  - godotsteam: Steam API integration

- **shaders/**: Visual effects
  - background.gdshader: Background visual effects

## Game Flow

1. **Initialization**:
   - Global settings loaded
   - Main menu displayed

2. **Game Start**:
   - World terrain generated
   - TurnManager initialized
   - Players spawned at valid positions

3. **Gameplay Loop**:
   - Current player can move and aim
   - Player charges and fires projectile
   - Projectile impacts terrain or players
   - Turn switches to next player
   - Loop continues until one player remains

4. **Game End**:
   - Last player standing detected
   - Game over screen shown with winner
   - Option to restart or quit

## Technical Implementation Details

### Destructible Terrain

The terrain uses a chunk-based system for efficient destruction:

1. Initial terrain created using a smooth curve
2. Terrain divided into smaller chunks (32x32 pixels)
3. When projectiles impact terrain:
   - A circular hole polygon is created
   - Affected chunks are identified
   - Geometry clipping operations remove the hole from chunks
   - Collision shapes and visual polygons are updated

### Trajectory Prediction

The game features a real-time trajectory prediction system:

1. Calculates projectile path based on current aim angle and power
2. Updates as player changes aim or power
3. Uses the same physics parameters as actual projectiles
4. Displays as a dotted line when charging power

### Turn-Based Logic

The turn system controls player actions:

1. Only the current player can move and fire
2. Turn switches automatically after firing
3. Dead players are skipped
4. Game ends when only one player remains
5. Each turn refreshes the player's jetpack fuel

## External Integrations

### Steam Integration

The game integrates with Steam via GodotSteam extension:

- Loaded as an autoload singleton (`Steamworks`)
- Supports Steam achievements and stats (implementation details not visible in examined code)

## Build and Deployment

The project includes configuration for multiple platforms:

- Windows
- Linux
- (Mobile configurations exist but Android support appears to have been removed)

A Steam build is supported with appropriate Steam API libraries included for each platform.