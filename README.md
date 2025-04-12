# Dungeon Crawler - dcjam2025

A simple dungeon crawler game made with Godot Engine 4.4.1.

## Overview

This is a 2D dungeon crawler where the player navigates through procedurally generated dungeons, fights enemies, collects items, and tries to reach the exit.

## Features

- Top-down 2D gameplay
- Multiple levels with increasing difficulty
- Various enemy types with different behaviors
- Collectible items and equipment
- Simple inventory system
- Game saving/loading

## Controls

- WASD or Arrow Keys: Move character
- Left Mouse Button: Attack
- E: Interact with objects/items
- ESC: Pause game

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
