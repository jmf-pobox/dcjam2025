#!/usr/bin/env python3
import json
import argparse
import os
import sys

def visualize_dungeon(json_path):
    """
    Create an ASCII representation of a dungeon from its JSON definition.
    
    Args:
        json_path: Path to the dungeon JSON file
    
    Returns:
        A string containing the ASCII visualization
    """
    # Load the JSON file
    with open(json_path, 'r') as f:
        data = json.load(f)

    # Grid size
    width, height = data['grid_size']

    # Create an empty grid
    grid = [[' ' for _ in range(width)] for _ in range(height)]

    # Fill rooms
    for room in data['rooms']:
        room_x, room_y = room['position']
        room_w, room_h = room['size']
        room_id = room['id'][0].upper()
        
        # Fill room with walls
        for x in range(room_x, room_x + room_w):
            for y in range(room_y, room_y + room_h):
                if (x == room_x or x == room_x + room_w - 1 or 
                    y == room_y or y == room_y + room_h - 1):
                    grid[y][x] = '#'  # Wall
                else:
                    grid[y][x] = '.'  # Floor
        
        # Add room identifier
        center_x = room_x + room_w // 2
        center_y = room_y + room_h // 2
        grid[center_y][center_x] = room_id

    # Add doors
    for room in data['rooms']:
        for door in room.get('doors', []):
            door_x, door_y = door['position']
            grid[door_y][door_x] = 'D'

    # Add corridors
    for corridor in data['corridors']:
        # Find start and end door positions
        start_room = next(r for r in data['rooms'] if r['id'] == corridor['start']['room'])
        end_room = next(r for r in data['rooms'] if r['id'] == corridor['end']['room'])
        
        start_door = next(d for d in start_room['doors'] if d['connects_to'] == corridor['id'])
        end_door = next(d for d in end_room['doors'] if d['connects_to'] == corridor['id'])
        
        start_x, start_y = start_door['position']
        end_x, end_y = end_door['position']
        
        # Handle waypoints
        points = [start_door['position']] + corridor.get('waypoints', []) + [end_door['position']]
        
        # Draw corridor paths
        for i in range(len(points) - 1):
            x1, y1 = points[i]
            x2, y2 = points[i + 1]
            
            # Draw horizontal path
            if y1 == y2:
                for x in range(min(x1, x2), max(x1, x2) + 1):
                    if grid[y1][x] == ' ':
                        grid[y1][x] = ':'
            
            # Draw vertical path
            elif x1 == x2:
                for y in range(min(y1, y2), max(y1, y2) + 1):
                    if grid[y][x1] == ' ':
                        grid[y][x1] = ':'

    # Add entities
    for entity in data.get('entities', []):
        entity_x, entity_y = entity['position']
        entity_type = entity['type'][0].upper()
        if entity.get('is_boss', False):
            entity_type = 'B'
        grid[entity_y][entity_x] = entity_type

    # Create the ASCII representation
    output = ["ASCII Representation of " + data.get('dungeon_name', 'Dungeon') + ":", 
              "-" * (width + 2)]
    
    for row in grid:
        output.append("|" + "".join(row) + "|")
    
    output.append("-" * (width + 2))
    
    # Add a legend
    output.extend([
        "",
        "Legend:",
        "# - Wall",
        ". - Floor",
        "D - Door",
        ": - Corridor",
        "E - Entrance room",
        "H - Hallway",
        "T - Treasure room",
        "M - Monster room",
        "P - Puzzle room",
        "S - Safe room",
        "C - Corridor room",
        "B - Boss room/Boss monster", 
        "S - Slime enemy"
    ])
    
    return "\n".join(output)

def main():
    parser = argparse.ArgumentParser(description='Visualize a dungeon JSON file as ASCII art')
    parser.add_argument('json_file', help='Path to the dungeon JSON file')
    args = parser.parse_args()
    
    if not os.path.isfile(args.json_file):
        print(f"Error: File {args.json_file} not found")
        return 1
        
    try:
        ascii_dungeon = visualize_dungeon(args.json_file)
        print(ascii_dungeon)
        return 0
    except Exception as e:
        print(f"Error visualizing dungeon: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())