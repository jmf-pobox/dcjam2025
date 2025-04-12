# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

GitHub Repository: https://github.com/jmf-pobox/dcjam2025

## Godot First-Person Dungeon Crawler Project

### Commands
- Open in Godot 4.4.1 Engine to run the game
- The main scene is `res://scenes/ui/main_menu.tscn`
- Launch game from the Godot editor with F5

### Recent Changes
- Fixed camera position consistency between initial position and after movement
- Fixed control mapping to match user expectations:
  - Inverted forward/backward movement behavior
  - Inverted left/right turning behavior
- Implemented buffer zone to prevent player from walking into walls
- Player movement is restricted to grid positions (1,1) to (2,2) within the 4x4 room

### Active Files

#### Scripts
- `scripts/player/fp_player.gd` - First-person grid-based player controller
- `scripts/utils/dungeon_generator3d.gd` - 3D dungeon generator
- `scripts/global/autoload.gd` - Game manager (singleton)

#### Scenes
- `scenes/levels/fp_dungeon.tscn` - First-person dungeon level
- `scenes/ui/main_menu.tscn` and `main_menu.gd` - Main menu
- `scenes/ui/game_over.tscn` - Game over screen
- `scenes/ui/options_menu.tscn` - Options menu
- `scenes/ui/pause_menu.tscn` - Pause menu

#### Resources
- `resources/ceiling_material.tres` - Ceiling material
- `resources/floor_material.tres` - Floor material
- `resources/wall_material.tres` - Wall material

### Code Style
- Use GDScript for all game logic
- Follow Godot 4.4.1 syntax (use `@export` instead of `export`)
- Include type hints for exported variables: `@export var health: int = 100`
- Use `snake_case` for functions and variables
- Use `PascalCase` for classes and nodes
- Group code by functionality with clear comments
- Signal names should be verbs in past tense (e.g., `health_changed`)
- Use `$NodePath` notation for accessing nodes within the same scene

### Architecture Notes
- First-person perspective with grid-based movement (90-degree turns only)
- 4x4 grid room with walls, floor, and ceiling
- Player can only move within a 2x2 area (positions 1,1 to 2,2) with a one-cell buffer from all walls
- Player starts at grid position (1,1)
- Use the singleton pattern via Godot's autoload for global state (GameManager)
- Scene composition over inheritance where possible
- Connect signals to handle inter-node communication

### Controls (First-Person Perspective)
- W/Up Arrow: Move in the OPPOSITE direction you're facing
- S/Down Arrow: Move in the SAME direction you're facing
- A/Left Arrow: TURN LEFT (clockwise rotation)
- D/Right Arrow: TURN RIGHT (counter-clockwise rotation)
- ESC: Open pause menu

Note: The controls were inverted to match user expectations, so the actual movement is opposite of what the function names suggest in the code.

### Cardinal Directions
- North: Positive Z direction (0 degrees)
- East: Positive X direction (90 degrees)
- South: Negative Z direction (180 degrees)
- West: Negative X direction (270 degrees)