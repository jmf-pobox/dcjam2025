# Dungeon Crawler - dcjam2025

A simple dungeon crawler game made with Godot Engine 4.4.1.

GitHub Repository: https://github.com/jmf-pobox/dcjam2025

## Overview

This game started as a 2D dungeon crawler but has evolved into a 3D first-person, grid-based dungeon crawler where the player navigates through a dungeon room, fights enemies, and collects items.

## Features

- First-person 3D grid-based movement
- Dungeon room with 4x4 grid layout
- Grid-based combat system
- Cardinal direction-based navigation
- Buffer zone to prevent walking into walls
- Player movement restricted to central 2x2 grid area
- Various enemy types with different behaviors
- Collectible items and equipment
- Simple inventory system

## Controls (First-Person Perspective)

- W/Up Arrow: Move in the OPPOSITE direction you're facing
- S/Down Arrow: Move in the SAME direction you're facing
- A/Left Arrow: TURN LEFT (clockwise rotation)
- D/Right Arrow: TURN RIGHT (counter-clockwise rotation)
- Left Mouse Button: Attack
- E: Interact with objects/items
- ESC: Pause game

Note: The controls have been adjusted to match user expectations.

## Recent Changes

- Fixed camera position consistency between initial position and after movement
- Fixed control mapping to match user expectations
- Implemented buffer zone to prevent player from walking into walls
- Player movement is restricted to grid positions (1,1) to (2,2) within the 4x4 room
- Converted from top-down 2D view to first-person 3D perspective

## Getting Started

1. Clone this repository
2. Open the project in Godot Engine 4.4.1
3. Press F5 or click the Play button to run the game

## Project Structure

- `assets/`: Contains all game assets (sprites, audio, etc.)
- `scenes/`: Contains all game scenes
  - `player/`: Player-related scenes
  - `enemies/`: Enemy-related scenes
  - `levels/`: Game level scenes
  - `ui/`: User interface scenes
- `scripts/`: Contains all GDScript files
  - `player/`: Player-related scripts
  - `enemies/`: Enemy-related scripts
  - `items/`: Item-related scripts
  - `utils/`: Utility scripts

## Active Files

The files that are currently actively being used for the first-person dungeon crawler are:

  1. Scripts:
	- scripts/player/fp_player.gd - First-person player controller
	- scripts/utils/dungeon_generator3d.gd - 3D dungeon generator
	- scripts/global/autoload.gd - Game manager (singleton)
  2. Scenes:
	- scenes/levels/fp_dungeon.tscn - First-person dungeon level
	- scenes/ui/main_menu.tscn and main_menu.gd - Main menu
	- scenes/ui/game_over.tscn - Game over screen
	- scenes/ui/options_menu.tscn - Options menu
	- scenes/ui/pause_menu.tscn - Pause menu
  3. Resources:
	- resources/ceiling_material.tres - Ceiling material
	- resources/floor_material.tres - Floor material
	- resources/wall_material.tres - Wall material

## License

This project is licensed under the MIT License - see the LICENSE file for details.
