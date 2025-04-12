extends Node

# Dungeon Loader - Loads dungeon definitions from JSON files
# and creates the 3D dungeon environment

"""
JSON Dungeon Format:
{
  "dungeon_name": "Level 1",             // Name of the dungeon level
  "grid_size": [30, 30],                 // Width and height of the grid in cells
  "cell_size": 2,                        // Size of each cell in world units
  
  "rooms": [                             // Array of room definitions
    {
      "id": "entrance",                  // Unique identifier for the room
      "position": [2, 2],                // Grid position [x, y] of the room's top-left corner
      "size": [4, 4],                    // Size [width, height] in grid cells
      "type": "entrance",                // Room type (entrance, treasure, monster, boss, etc.)
      "doors": [                         // Array of door definitions
        {
          "direction": "E",              // Direction (N, S, E, W) the door faces
          "position": [6, 4],            // Grid position [x, y] of the door
          "connects_to": "corridor_1"    // ID of the corridor this door connects to
        }
      ],
      "items": [                         // Optional items in the room
        {"type": "chest", "position": [3, 3]}
      ]
    }
  ],
  
  "corridors": [                         // Array of corridor definitions
    {
      "id": "corridor_1",                // Unique identifier for the corridor
      "start": {                         // Start connection
        "room": "entrance",              // ID of the room the corridor starts from
        "door_direction": "E"            // Direction the door faces
      },
      "end": {                           // End connection
        "room": "hallway",               // ID of the room the corridor ends at
        "door_direction": "W"            // Direction the door faces
      },
      "waypoints": [[7, 4]]              // Optional waypoints for the corridor path
    }
  ],
  
  "entities": [                          // Array of entity definitions (monsters, NPCs, etc.)
    {
      "type": "slime",                   // Entity type
      "position": [16, 10],              // Grid position [x, y]
      "room": "monster_room",            // ID of the room containing this entity
      "health": 20                       // Optional properties for the entity
    }
  ]
}
"""

# Reference to the 3D dungeon generator
var dungeon_generator: Node

func _init(generator: Node):
	"""Initialize with reference to the dungeon generator."""
	dungeon_generator = generator

func load_dungeon(file_path: String) -> Dictionary:
	"""Load a dungeon definition from a JSON file."""
	if not FileAccess.file_exists(file_path):
		printerr("Dungeon definition file not found: ", file_path)
		return {}
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	
	# Parse JSON data
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		printerr("JSON parse error: ", json.get_error_message(), " at line ", json.get_error_line())
		return {}
		
	return json.get_data()

func build_dungeon_from_json(dungeon_data: Dictionary) -> void:
	"""Build the dungeon from the loaded JSON data."""
	if dungeon_data.is_empty():
		printerr("No dungeon data to build from.")
		return
		
	# Get dungeon properties
	var grid_size = dungeon_data.get("grid_size", [20, 20])
	var cell_size = dungeon_data.get("cell_size", 2)
	
	# Initialize the dungeon generator
	dungeon_generator.initialize(grid_size[0], grid_size[1], cell_size)
	
	# Create all rooms
	for room_data in dungeon_data.get("rooms", []):
		_create_room(room_data)
	
	# Create all corridors
	for corridor_data in dungeon_data.get("corridors", []):
		_create_corridor(corridor_data, dungeon_data)
	
	# Spawn entities
	for entity_data in dungeon_data.get("entities", []):
		_spawn_entity(entity_data)
	
	# Finalize the dungeon - build walls, floor, ceiling
	dungeon_generator.build_dungeon()

func _create_room(room_data: Dictionary) -> void:
	"""Create a room based on the room data."""
	var room_id = room_data.get("id", "")
	var position = room_data.get("position", [0, 0])
	var size = room_data.get("size", [4, 4])
	var room_type = room_data.get("type", "basic")
	
	# Add the room to the dungeon
	dungeon_generator.add_room(
		room_id,
		Vector2i(position[0], position[1]),
		Vector2i(size[0], size[1]),
		room_type
	)
	
	# Process doors in the room
	for door_data in room_data.get("doors", []):
		var direction = door_data.get("direction", "N")
		var door_position = door_data.get("position", position)
		var connects_to = door_data.get("connects_to", "")
		
		# Mark door cells as walkable
		dungeon_generator.add_door(
			room_id,
			direction,
			Vector2i(door_position[0], door_position[1]),
			connects_to
		)

func _create_corridor(corridor_data: Dictionary, dungeon_data: Dictionary) -> void:
	"""Create a corridor based on the corridor data."""
	var corridor_id = corridor_data.get("id", "")
	var start = corridor_data.get("start", {})
	var end = corridor_data.get("end", {})
	var waypoints = corridor_data.get("waypoints", [])
	
	# Get starting and ending positions
	var start_pos = _get_door_position(start, dungeon_data)
	var end_pos = _get_door_position(end, dungeon_data)
	
	if start_pos == Vector2i(-1, -1) or end_pos == Vector2i(-1, -1):
		printerr("Invalid corridor connection points for corridor: ", corridor_id)
		return
	
	# Create corridor path
	var path = [Vector2i(start_pos.x, start_pos.y)]
	
	# Add waypoints
	for waypoint in waypoints:
		path.append(Vector2i(waypoint[0], waypoint[1]))
	
	path.append(Vector2i(end_pos.x, end_pos.y))
	
	# Add the corridor
	dungeon_generator.add_corridor(corridor_id, path)

func _get_door_position(connection_data: Dictionary, dungeon_data: Dictionary) -> Vector2i:
	"""Get the door position from a room connection data."""
	var room_id = connection_data.get("room", "")
	var door_direction = connection_data.get("door_direction", "")
	
	# Find the room
	for room in dungeon_data.get("rooms", []):
		if room.get("id") == room_id:
			# Find the door with the matching direction
			for door in room.get("doors", []):
				if door.get("direction") == door_direction:
					var pos = door.get("position", [0, 0])
					return Vector2i(pos[0], pos[1])
	
	return Vector2i(-1, -1)

func _spawn_entity(entity_data: Dictionary) -> void:
	"""Spawn an entity in the dungeon."""
	var entity_type = entity_data.get("type", "")
	var position = entity_data.get("position", [0, 0])
	
	# Additional properties like health, level, etc. can be passed through
	var properties = entity_data.duplicate()
	properties.erase("type")
	properties.erase("position")
	
	# Let the dungeon generator handle entity spawning
	dungeon_generator.spawn_entity(
		entity_type,
		Vector2i(position[0], position[1]),
		properties
	)