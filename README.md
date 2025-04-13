# Dungeon Crawler - dcjam2025

A grid-based 3D dungeon crawler game made with Godot Engine 4.4.1.

GitHub Repository: https://github.com/jmf-pobox/dcjam2025

## Overview

This is a first-person, grid-based dungeon crawler where the player navigates through procedurally generated dungeons, fights enemies, collects items, and tries to reach the exit. The game features a 3D environment with textured walls, animated torches, and dynamic lighting.

## Features

- First-person 3D grid-based movement
- JSON-based procedural dungeon generation
- Room-specific textures and lighting
- Animated torches with dynamic lighting
- Grid-based combat system
- Cardinal direction-based navigation
- Various enemy types with different behaviors
- Collectible items and equipment
- Simple inventory system
- Background music with volume controls
- 2D Chase minigame (press 'g' to play)

## Controls

### Main Game (First-Person Perspective)
- W/Up Arrow: Move in the OPPOSITE direction you're facing
- S/Down Arrow: Move in the SAME direction you're facing
- A/Left Arrow: TURN LEFT (clockwise rotation)
- D/Right Arrow: TURN RIGHT (counter-clockwise rotation)
- Left Mouse Button: Attack
- E: Interact with objects/items
- ESC: Pause game
- G: Launch Chase minigame

### Chase Minigame
- Arrow Keys: Move the player character
- ESC: Return to main dungeon

Note: The main game controls have been adjusted to match user expectations.

## Recent Features Added

- Animated torches that cast dynamic light throughout the dungeon
- Room-specific textures for walls, floors, and ceilings
- Special lighting for different room types (boss rooms, treasure rooms, etc.)
- Taller walls for a more spacious dungeon feel
- JSON-based dungeon definition for easy level creation
- Audio system with background music and volume controls
- 2D Chase minigame with enemy AI and level design

## Getting Started

1. Clone this repository
2. Open the project in Godot Engine 4.4.1
3. Press F5 or click the Play button to run the game

## Project Structure

### Key Directories
- `assets/`: Contains all game assets
  - `audio/music/`: Background music files
  - `audio/sfx/`: Sound effects
  - `sprites/`: Sprite sheets, including torch animations
  - `textures/`: Wall, floor, and ceiling textures
- `resources/`: Contains material definitions and other resources
  - `dungeons/`: JSON dungeon definitions
- `scenes/`: Contains all game scenes
  - `player/`: Player-related scenes
  - `enemies/`: Enemy-related scenes
  - `levels/`: Game level scenes
  - `objects/`: Objects like torches, doors, etc.
  - `ui/`: User interface scenes
  - `minigames/`: Minigame scenes
    - `chase/`: Chase minigame components
- `scripts/`: Contains all GDScript files
  - `player/`: Player-related scripts
  - `enemies/`: Enemy-related scripts
  - `items/`: Item-related scripts
  - `global/`: Global singleton scripts
  - `objects/`: Object behavior scripts
  - `utils/`: Utility scripts including dungeon generation
  - `minigames/`: Minigame scripts
    - `chase/`: Chase minigame scripts

### Key Files and Their Functions

#### Core Game Scripts
- `scripts/global/autoload.gd`: The game manager singleton that handles global state, audio, game flow, and minigame transitions
- `scripts/player/fp_player.gd`: First-person player controller with grid-based movement and rotation
- `scripts/utils/dungeon_generator3d.gd`: 3D dungeon generation from grid data, including walls, floors, and torches
- `scripts/utils/dungeon_loader.gd`: Loads and parses JSON dungeon definitions
- `scripts/objects/torch.gd`: Handles torch animation and dynamic lighting

#### Important Scenes
- `scenes/levels/fp_dungeon.tscn`: Main 3D dungeon level scene
- `scenes/ui/main_menu.tscn`: Game start menu with options
- `scenes/objects/torch.tscn`: Animated torch object that provides light

### Chase Minigame

The game includes a 2D chase minigame that can be accessed by pressing the 'g' key while in the main dungeon. This minigame provides a different gameplay experience from the main dungeon crawler.

#### Minigame Structure
- `scenes/minigames/chase/chase_game.tscn`: Main minigame scene that contains:
  - Player character
  - Enemy slimes
  - Exit area
  - Game logic and pause handling

#### Minigame Components
- `scenes/minigames/chase/chase_player.tscn`: Player character scene
- `scenes/minigames/chase/chase_slime.tscn`: Enemy slime scene
- `scripts/minigames/chase/chase_player.gd`: Player movement and interaction logic
- `scripts/minigames/chase/chase_enemy.gd`: Enemy AI and behavior logic

#### Minigame Objective
- Navigate through the level while avoiding enemy slimes
- Reach the exit area to return to the main dungeon
- Can also press ESC at any time to return to the main dungeon

#### Resource Files
- `resources/dungeons/level_1.json`: JSON definition of the first level's layout
- `resources/floor_material.tres`, `wall_material.tres`, etc.: Material definitions for dungeon surfaces
- Various specialized materials for different room types (_boss, _alt, etc.)

## Modifying the Game

### To Modify Dungeon Layout
1. Edit or create JSON files in `resources/dungeons/`
2. Follow the format with rooms, doors, corridors, and entities
3. Visualize layouts using `dungeon_visualizer.py` script

### To Change Materials and Textures
1. Replace texture files in `assets/textures/`
2. Edit material properties in resource files like `resources/wall_material.tres`
3. Modify material mappings in `scripts/utils/dungeon_generator3d.gd`

### To Modify Torch Properties
1. Edit `scripts/objects/torch.gd` to change animation speed, light properties, etc.
2. Adjust torch placement logic in `dungeon_generator3d.gd`

### To Modify Game Audio
1. Replace audio files in the `assets/audio/` directory
2. Edit `scripts/global/autoload.gd` to adjust audio settings and playback

### To Modify the Chase Minigame
1. Edit `scenes/minigames/chase/chase_game.tscn` to modify level layout
2. Adjust player movement in `scripts/minigames/chase/chase_player.gd`
3. Modify enemy behavior in `scripts/minigames/chase/chase_enemy.gd`
4. Update minigame transition logic in `scripts/global/autoload.gd`

## License

This project is licensed under the MIT License - see the LICENSE file for details.