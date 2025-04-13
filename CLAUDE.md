# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

GitHub Repository: https://github.com/jmf-pobox/dcjam2025

## Godot First-Person Dungeon Crawler Project

### Commands
- Open in Godot 4.4.1 Engine to run the game
- The main scene is `res://scenes/ui/main_menu.tscn`
- Launch game from the Godot editor with F5
- Run `dungeon_visualizer.py` to create ASCII visualizations of dungeon layouts
  - Usage: `python dungeon_visualizer.py --dungeon path/to/dungeon.json --output path/to/output.txt`
  - Optional: `--show-legend` to include legend in output
  - Optional: `--show-coordinates` to show grid coordinates

### Recent Features
- Python-based dungeon visualization system with ASCII art output
- Animated torch system with dynamic lighting
- Room-specific textures and materials
- JSON-based dungeon layout system
- Audio management with background music
- Wall height adjusted to 2.0 units for better atmosphere
- Special lighting effects for different room types

### Active Files and Their Purpose

#### Core Scripts
- `scripts/global/autoload.gd` - Game manager (singleton)
  - Handles audio, game state, saving/loading
  - Sets up and manages audio buses and background music
  - Contains global utility functions

- `scripts/player/fp_player.gd` - First-person grid-based player controller
  - Handles grid-based movement and rotation
  - Controls camera and player positioning
  - Processes player input and handles collisions

- `scripts/utils/dungeon_generator3d.gd` - 3D dungeon generator
  - Generates 3D environments from grid data
  - Places and configures walls, floors, ceilings
  - Handles material assignments and texturing
  - Manages torch placement and lighting
  - Creates room-specific visual styles

- `scripts/utils/dungeon_loader.gd` - Dungeon definition loader
  - Parses JSON dungeon layouts
  - Converts JSON data to game structures
  - Handles room, corridor, and entity creation

- `scripts/objects/torch.gd` - Torch behavior script
  - Controls torch animation from sprite sheet
  - Manages flickering light effect
  - Configures light properties based on room type

#### Python Visualization System
- `dungeon_visualizer.py` - Dungeon visualization tool
  - Converts JSON dungeon layouts to ASCII art
  - Supports different room types and entities
  - Generates coordinate-based grid output
  - Includes optional legend and coordinate display
  - Uses type hints and follows PEP 8 standards
  - Implements proper error handling and logging

#### Key Scenes
- `scenes/levels/fp_dungeon.tscn` - First-person dungeon level
  - Main 3D gameplay environment
  - Contains player, dungeon generator, and game logic

- `scenes/ui/main_menu.tscn` and `main_menu.gd` - Main menu
  - Game entry point
  - Options for starting game, adjusting settings, and quitting

- `scenes/objects/torch.tscn` - Torch object scene
  - Animated torch with dynamic lighting
  - Configurable properties for different environments

#### Resource Files
- `resources/dungeons/level_1.json` - Main level definition
  - Contains rooms, corridors, doors, and entity definitions
  - Structured for procedural dungeon generation

- Material resources:
  - `resources/floor_material.tres`, `floor_material_alt.tres`, `floor_material_boss.tres`
  - `resources/wall_material.tres`, `wall_material_alt.tres`, `wall_material_boss.tres`
  - `resources/ceiling_material.tres`
  - Each configures textures and properties for different room types

### Code Style
- Use GDScript for all game logic
- Follow Godot 4.4.1 syntax (use `@export` instead of `export`)
- Include type hints for exported variables: `@export var health: int = 100`
- Use `snake_case` for functions and variables
- Use `PascalCase` for classes and nodes
- Group code by functionality with clear comments
- Signal names should be verbs in past tense (e.g., `health_changed`)
- Use `$NodePath` notation for accessing nodes within the same scene
- For Python code:
  - Use type hints and PEP 695 syntax for generics
  - Use `__new__` instead of `__init__` for object instantiation
  - Use `__slots__` for variable declarations
  - Follow PEP 8 coding standards
  - Include appropriate comments
  - Do not use type ignore hints

### Architecture Notes
- First-person perspective with grid-based movement (90-degree turns only)
- JSON-based procedural dungeon generation
- Material system for room-specific styling
- Dynamic lighting with animated torches
- Player can only move within a 2x2 area (positions 1,1 to 2,2) with a one-cell buffer from walls
- Player starts at grid position (1,1)
- Use the singleton pattern via Godot's autoload for global state (GameManager)
- Scene composition over inheritance where possible
- Connect signals to handle inter-node communication

### JSON Dungeon Format
- `dungeon_name`: String name of the dungeon
- `grid_size`: [width, height] array defining the total grid dimensions
- `cell_size`: Size of each grid cell in 3D units
- `rooms`: Array of room objects with:
  - `id`: Unique identifier
  - `position`: [x, y] grid coordinates
  - `size`: [width, height] in grid cells
  - `type`: Room type (entrance, hallway, treasure, boss, etc.)
  - `doors`: Array of door objects
- `corridors`: Array of corridor objects connecting rooms
- `entities`: Array of entities to spawn in the dungeon

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

### Room Types and Material Mappings
- Entrance rooms: Standard floor, standard walls
- Hallway rooms: Alternate floor, standard walls
- Treasure rooms: Alternate floor, alternate walls
- Boss rooms: Special boss floor, special boss walls with reddish lighting

### ASCII Visualization Symbols
- `#` - Wall
- `.` - Floor
- `D` - Door
- `T` - Torch
- `E` - Enemy
- `C` - Chest
- `S` - Start position
- `B` - Boss
- `+` - Corridor
- ` ` (space) - Empty space