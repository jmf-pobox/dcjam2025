extends Node3D

class_name DungeonGenerator3D

# Default room dimensions if not specified
const DEFAULT_GRID_WIDTH = 20
const DEFAULT_GRID_HEIGHT = 20 
const DEFAULT_CELL_SIZE = 2.0
const DEFAULT_ROOM_HEIGHT = 2.0

# Wall thickness
const WALL_THICKNESS = 0.2

# Materials (loaded in _ready)
var floor_material: Material
var floor_material_alt: Material
var floor_material_boss: Material
var ceiling_material: Material
var wall_material: Material
var wall_material_alt: Material
var wall_material_boss: Material

# Material mappings for room types
var room_floor_materials = {}
var room_wall_materials = {}

# Grid properties
var grid_width: int
var grid_height: int 
var cell_size: float
var room_height: float

# Dungeon layout data
var grid: Array[Array] = []  # 2D grid: 0=empty, 1=floor, 2=wall
var rooms: Dictionary = {}   # room_id -> room data
var corridors: Dictionary = {} # corridor_id -> corridor data
var doors: Array[Dictionary] = [] # List of door positions
var entities: Array[Dictionary] = [] # List of entities to spawn

# Parent node for all dungeon elements
var dungeon_node: Node3D

# Called when the node enters the scene tree for the first time
func _ready():
	# Load materials
	_load_materials()

# Initialize the dungeon generator with grid dimensions
func initialize(width: int = DEFAULT_GRID_WIDTH, height: int = DEFAULT_GRID_HEIGHT, 
				cs: float = DEFAULT_CELL_SIZE, rh: float = DEFAULT_ROOM_HEIGHT) -> void:
	grid_width = width
	grid_height = height
	cell_size = cs
	room_height = rh
	
	# Create the empty grid
	grid.clear()
	for x in range(grid_width):
		var column = []
		for y in range(grid_height):
			column.append(0)  # 0 = empty space
		grid.append(column)
	
	# Clear other data structures
	rooms.clear()
	corridors.clear()
	doors.clear()
	entities.clear()
	
	print("Dungeon generator initialized with grid size: ", grid_width, "x", grid_height)

# Add a room to the dungeon
func add_room(room_id: String, room_pos: Vector2i, size: Vector2i, room_type: String = "basic") -> void:
	# Store room data
	rooms[room_id] = {
		"id": room_id,
		"position": room_pos,
		"size": size,
		"type": room_type,
		"doors": []
	}
	
	# Mark room area as floor in the grid
	for x in range(room_pos.x, room_pos.x + size.x):
		for y in range(room_pos.y, room_pos.y + size.y):
			if x >= 0 and x < grid_width and y >= 0 and y < grid_height:
				grid[x][y] = 1  # 1 = floor
	
	print("Added room: ", room_id, " at position ", room_pos, " with size ", size)

# Add a door to a room
func add_door(room_id: String, direction: String, door_pos: Vector2i, connects_to: String) -> void:
	if not rooms.has(room_id):
		printerr("Cannot add door to non-existent room: ", room_id)
		return
	
	# Add door to room data
	rooms[room_id]["doors"].append({
		"direction": direction,
		"position": door_pos,
		"connects_to": connects_to
	})
	
	# Mark door position as floor in the grid
	if door_pos.x >= 0 and door_pos.x < grid_width and door_pos.y >= 0 and door_pos.y < grid_height:
		grid[door_pos.x][door_pos.y] = 1  # 1 = floor
	
	# Add to doors list
	doors.append({
		"room_id": room_id,
		"direction": direction,
		"position": door_pos,
		"connects_to": connects_to
	})
	
	print("Added door in room ", room_id, " at position ", door_pos, " connecting to ", connects_to)

# Add a corridor to the dungeon
func add_corridor(corridor_id: String, path_points: Array) -> void:
	# Store corridor data
	corridors[corridor_id] = {
		"id": corridor_id,
		"path": path_points
	}
	
	# Mark corridor path as floor in the grid
	for point in path_points:
		if point.x >= 0 and point.x < grid_width and point.y >= 0 and point.y < grid_height:
			grid[point.x][point.y] = 1  # 1 = floor
	
	print("Added corridor: ", corridor_id, " with ", path_points.size(), " points")

# Spawn an entity in the dungeon
func spawn_entity(entity_type: String, entity_pos: Vector2i, properties: Dictionary = {}) -> void:
	var entity_data = properties.duplicate()
	entity_data["type"] = entity_type
	entity_data["position"] = entity_pos
	
	entities.append(entity_data)
	print("Added entity: ", entity_type, " at position ", entity_pos)

# Build the dungeon from the grid data
func build_dungeon() -> void:
	# Create parent node
	if dungeon_node == null:
		dungeon_node = Node3D.new()
		dungeon_node.name = "Dungeon_Elements"
		add_child(dungeon_node)
	else:
		# Clear existing dungeon
		for child in dungeon_node.get_children():
			child.queue_free()
	
	# Create floor and ceiling for the entire occupied grid area
	_create_floor_and_ceiling()
	
	# Create walls around all floor cells
	_create_walls_from_grid()
	
	# Add torches to walls
	_add_torches_to_walls()
	
	print("Dungeon built with ", rooms.size(), " rooms and ", corridors.size(), " corridors")

# Load a dungeon from JSON file
func load_from_json(file_path: String) -> bool:
	var loader = load("res://scripts/utils/dungeon_loader.gd").new(self)
	var dungeon_data = loader.load_dungeon(file_path)
	
	if dungeon_data.is_empty():
		return false
	
	loader.build_dungeon_from_json(dungeon_data)
	return true

# Load material resources
func _load_materials() -> void:
	# Try to load materials from resources first
	var floor_mat_res = load("res://resources/floor_material.tres")
	var floor_mat_alt_res = load("res://resources/floor_material_alt.tres")
	var floor_mat_boss_res = load("res://resources/floor_material_boss.tres")
	var ceiling_mat_res = load("res://resources/ceiling_material.tres")
	var wall_mat_res = load("res://resources/wall_material.tres")
	var wall_mat_alt_res = load("res://resources/wall_material_alt.tres")
	var wall_mat_boss_res = load("res://resources/wall_material_boss.tres")
	
	# Use loaded materials if available, otherwise create new ones
	if floor_mat_res:
		floor_material = floor_mat_res
	else:
		floor_material = StandardMaterial3D.new()
		floor_material.albedo_color = Color(0.3, 0.3, 0.3) # Dark gray
	
	if floor_mat_alt_res:
		floor_material_alt = floor_mat_alt_res
	else:
		floor_material_alt = floor_material # Fallback to standard floor
		
	if floor_mat_boss_res:
		floor_material_boss = floor_mat_boss_res
	else:
		floor_material_boss = floor_material_alt # Fallback to alt floor
	
	if ceiling_mat_res:
		ceiling_material = ceiling_mat_res
	else:
		ceiling_material = StandardMaterial3D.new()
		ceiling_material.albedo_color = Color(0.15, 0.15, 0.2) # Dark blue-gray
	
	if wall_mat_res:
		wall_material = wall_mat_res
	else:
		wall_material = StandardMaterial3D.new()
		wall_material.albedo_color = Color(0.6, 0.5, 0.4) # Beige-brown
		
	if wall_mat_alt_res:
		wall_material_alt = wall_mat_alt_res
	else:
		wall_material_alt = wall_material # Fallback to standard wall
		
	if wall_mat_boss_res:
		wall_material_boss = wall_mat_boss_res
	else:
		wall_material_boss = wall_material_alt # Fallback to alt wall
	
	# Setup room type material mappings
	# Default for all rooms
	room_floor_materials["default"] = floor_material
	room_wall_materials["default"] = wall_material
	
	# Special room types
	room_floor_materials["entrance"] = floor_material
	room_floor_materials["hallway"] = floor_material_alt
	room_floor_materials["treasure"] = floor_material_alt
	room_floor_materials["boss"] = floor_material_boss
	
	room_wall_materials["entrance"] = wall_material
	room_wall_materials["hallway"] = wall_material
	room_wall_materials["treasure"] = wall_material_alt
	room_wall_materials["boss"] = wall_material_boss

# Create floor and ceiling for the entire occupied grid area
func _create_floor_and_ceiling() -> void:
	# Find the min/max extents of the occupied grid
	var min_x = grid_width
	var min_y = grid_height
	var max_x = 0
	var max_y = 0
	
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] == 1:  # if this is a floor tile
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)
	
	# If no floor cells found, nothing to do
	if min_x > max_x or min_y > max_y:
		return
	
	# Create a floor mesh for each room instead of one big floor
	for room_id in rooms:
		var room = rooms[room_id]
		var position = room["position"]
		var size = room["size"]
		
		var floor_mesh = PlaneMesh.new()
		floor_mesh.size = Vector2(size.x * cell_size, size.y * cell_size)
		
		var floor_instance = MeshInstance3D.new()
		floor_instance.name = "Floor_" + room_id
		floor_instance.mesh = floor_mesh
		
		# Position floor at the center of the room, aligned with grid
		floor_instance.position = Vector3(
			(position.x + size.x / 2.0) * cell_size,
			0,
			(position.y + size.y / 2.0) * cell_size
		)
		
		# Use room-specific floor material if defined
		var room_type = room["type"]
		var floor_mat = room_floor_materials.get("default", floor_material)
		if room_floor_materials.has(room_type):
			floor_mat = room_floor_materials[room_type]
			
		floor_instance.set_surface_override_material(0, floor_mat)
		dungeon_node.add_child(floor_instance)
		
		# Create ceiling for this room
		var ceiling_mesh = PlaneMesh.new()
		ceiling_mesh.size = Vector2(size.x * cell_size, size.y * cell_size)
		
		var ceiling_instance = MeshInstance3D.new()
		ceiling_instance.name = "Ceiling_" + room_id
		ceiling_instance.mesh = ceiling_mesh
		
		# Position ceiling at the center of the room, at height
		ceiling_instance.position = Vector3(
			(position.x + size.x / 2.0) * cell_size,
			room_height * cell_size,
			(position.y + size.y / 2.0) * cell_size
		)
		
		# Flip ceiling to face downward
		ceiling_instance.rotation_degrees.x = 180
		
		ceiling_instance.set_surface_override_material(0, ceiling_material)
		dungeon_node.add_child(ceiling_instance)
	
	# Create corridor floors
	for corridor_id in corridors:
		var corridor = corridors[corridor_id]
		var path = corridor["path"]
		
		for i in range(path.size() - 1):
			var start = path[i]
			var end = path[i + 1]
			
			# Calculate corridor segment dimensions
			var segment_length
			var is_horizontal = start.y == end.y
			
			if is_horizontal:
				segment_length = abs(end.x - start.x) + 1
			else:
				segment_length = abs(end.y - start.y) + 1
			
			var floor_mesh = PlaneMesh.new()
			
			if is_horizontal:
				floor_mesh.size = Vector2(segment_length * cell_size, cell_size)
			else:
				floor_mesh.size = Vector2(cell_size, segment_length * cell_size)
			
			var floor_instance = MeshInstance3D.new()
			floor_instance.name = "Floor_Corridor_" + corridor_id + "_" + str(i)
			floor_instance.mesh = floor_mesh
			
			# Position floor at the center of the corridor segment
			var corridor_pos
			if is_horizontal:
				var corridor_min_x = min(start.x, end.x)
				corridor_pos = Vector3(
					(corridor_min_x + segment_length / 2.0) * cell_size,
					0,
					start.y * cell_size + cell_size / 2
				)
			else:
				var corridor_min_y = min(start.y, end.y)
				corridor_pos = Vector3(
					start.x * cell_size + cell_size / 2,
					0,
					(corridor_min_y + segment_length / 2.0) * cell_size
				)
			
			floor_instance.position = corridor_pos
			floor_instance.set_surface_override_material(0, floor_material)
			dungeon_node.add_child(floor_instance)
			
			# Create ceiling for this corridor segment
			var ceiling_mesh = PlaneMesh.new()
			ceiling_mesh.size = floor_mesh.size
			
			var ceiling_instance = MeshInstance3D.new()
			ceiling_instance.name = "Ceiling_Corridor_" + corridor_id + "_" + str(i)
			ceiling_instance.mesh = ceiling_mesh
			
			# Position ceiling at the center of the corridor segment, at height
			ceiling_instance.position = Vector3(
				corridor_pos.x,
				room_height * cell_size,
				corridor_pos.z
			)
			
			# Flip ceiling to face downward
			ceiling_instance.rotation_degrees.x = 180
			
			ceiling_instance.set_surface_override_material(0, ceiling_material)
			dungeon_node.add_child(ceiling_instance)

# Create walls around all floor cells
func _create_walls_from_grid() -> void:
	var wall_height = room_height * cell_size
	
	# For each grid cell that's floor (1), check adjacent cells
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] == 1:  # if this is a floor cell
				# Check each of the 4 cardinal directions
				# North wall (y-1)
				if y == 0 or grid[x][y-1] == 0:
					# Place wall on the grid boundary (offset by 0.5 cell)
					_create_wall_segment(
						Vector3(
							(x * cell_size) + (cell_size / 2), # Center in the cell X
							0, 
							y * cell_size # Align with north edge
						), 
						"NS", cell_size, wall_height, "N"
					)
				
				# South wall (y+1)
				if y == grid_height-1 or grid[x][y+1] == 0:
					# Place wall on the grid boundary (offset by 0.5 cell)
					_create_wall_segment(
						Vector3(
							(x * cell_size) + (cell_size / 2), # Center in the cell X
							0, 
							(y+1) * cell_size # Align with south edge
						), 
						"NS", cell_size, wall_height, "S"
					)
				
				# East wall (x+1)
				if x == grid_width-1 or grid[x+1][y] == 0:
					# Place wall on the grid boundary (offset by 0.5 cell)
					_create_wall_segment(
						Vector3(
							(x+1) * cell_size, # Align with east edge
							0, 
							(y * cell_size) + (cell_size / 2) # Center in the cell Z
						), 
						"EW", cell_size, wall_height, "E"
					)
				
				# West wall (x-1)
				if x == 0 or grid[x-1][y] == 0:
					# Place wall on the grid boundary (offset by 0.5 cell)
					_create_wall_segment(
						Vector3(
							x * cell_size, # Align with west edge
							0, 
							(y * cell_size) + (cell_size / 2) # Center in the cell Z
						), 
						"EW", cell_size, wall_height, "W"
					)

# Helper function to create a wall segment
func _create_wall_segment(position: Vector3, orientation: String, length: float, 
						height: float, direction: String) -> void:
	var wall = BoxMesh.new()
	
	# Set wall size based on orientation
	if orientation == "NS":  # North-South wall (runs along X axis)
		wall.size = Vector3(length, height, WALL_THICKNESS)
	else:  # East-West wall (runs along Z axis)
		wall.size = Vector3(WALL_THICKNESS, height, length)
	
	var wall_instance = MeshInstance3D.new()
	wall_instance.name = "Wall_" + direction + "_" + str(position.x) + "_" + str(position.z)
	wall_instance.mesh = wall
	
	# Position the wall - walls are now centered on grid boundaries
	var wall_pos = position
	wall_pos.y = height / 2  # Center vertically
	
	# These offsets are no longer needed as we're already positioning walls
	# at grid boundaries in _create_walls_from_grid
	# But we'll keep the code structure for clarity
	if direction == "N":
		wall_pos.z -= WALL_THICKNESS / 2
	elif direction == "S":
		wall_pos.z += WALL_THICKNESS / 2
	elif direction == "E":
		wall_pos.x += WALL_THICKNESS / 2
	elif direction == "W":
		wall_pos.x -= WALL_THICKNESS / 2
	
	wall_instance.position = wall_pos
	
	# Use room-specific wall material if position is within a room
	var wall_mat = wall_material
	
	# Find which room this wall belongs to
	for room_id in rooms:
		var room = rooms[room_id]
		var room_pos = room["position"]
		var room_size = room["size"]
		var room_type = room["type"]
		
		# Check if wall position is within room bounds
		var wall_grid_x = int(position.x / cell_size)
		var wall_grid_y = int(position.z / cell_size)
		
		if wall_grid_x >= room_pos.x and wall_grid_x <= room_pos.x + room_size.x and \
		   wall_grid_y >= room_pos.y and wall_grid_y <= room_pos.y + room_size.y:
			# This wall belongs to this room
			if room_wall_materials.has(room_type):
				wall_mat = room_wall_materials[room_type]
			break
	
	wall_instance.set_surface_override_material(0, wall_mat)
	
	# Skip walls at door positions
	var is_door = false
	for door in doors:
		var door_pos = door["position"]
		var door_dir = door["direction"]
		
		# Convert grid position to world position with adjusted positions for doors
		var door_world_pos = Vector3(0, 0, 0)
		
		# Position door at grid boundaries like walls
		if door_dir == "N":
			door_world_pos = Vector3(
				(door_pos.x * cell_size) + (cell_size / 2), # Center in cell X
				0,
				door_pos.y * cell_size # North edge
			)
		elif door_dir == "S":
			door_world_pos = Vector3(
				(door_pos.x * cell_size) + (cell_size / 2), # Center in cell X
				0,
				(door_pos.y * cell_size) + cell_size # South edge
			)
		elif door_dir == "E":
			door_world_pos = Vector3(
				(door_pos.x * cell_size) + cell_size, # East edge
				0,
				(door_pos.y * cell_size) + (cell_size / 2) # Center in cell Z
			)
		elif door_dir == "W":
			door_world_pos = Vector3(
				door_pos.x * cell_size, # West edge
				0,
				(door_pos.y * cell_size) + (cell_size / 2) # Center in cell Z
			)
		
		# Add the same offset we applied to walls
		if door_dir == "N":
			door_world_pos.z -= WALL_THICKNESS / 2
		elif door_dir == "S":
			door_world_pos.z += WALL_THICKNESS / 2
		elif door_dir == "E":
			door_world_pos.x += WALL_THICKNESS / 2
		elif door_dir == "W":
			door_world_pos.x -= WALL_THICKNESS / 2
		
		# Check if this wall segment matches a door position
		var door_match = direction == door_dir and is_position_near(wall_pos, door_world_pos, Vector3.ZERO)
		
		if door_match:
			is_door = true
			# Ensure the door and adjacent cells are walkable
			_ensure_door_passage(door_pos, door_dir)
			break
	
	if not is_door:
		dungeon_node.add_child(wall_instance)

# Helper to check if a position is near another position (for door detection)
func is_position_near(pos1: Vector3, pos2: Vector3, offset: Vector3 = Vector3.ZERO) -> bool:
	var adjusted_pos = pos2 + offset
	return (pos1 - adjusted_pos).length() < cell_size * 0.5
	
# Ensure both sides of a door are marked as walkable
func _ensure_door_passage(door_pos: Vector2i, door_dir: String) -> void:
	var neighbor_pos = door_pos
	
	# Based on door direction, mark the cell on the other side of the door as walkable
	match door_dir:
		"N": # North door
			neighbor_pos.y -= 1
		"S": # South door
			neighbor_pos.y += 1
		"E": # East door
			neighbor_pos.x += 1
		"W": # West door
			neighbor_pos.x -= 1
	
	# Make sure the position is within grid bounds
	if neighbor_pos.x >= 0 and neighbor_pos.x < grid_width and neighbor_pos.y >= 0 and neighbor_pos.y < grid_height:
		# Mark both the door position and its neighbor as walkable floor
		grid[door_pos.x][door_pos.y] = 1  # Door position
		grid[neighbor_pos.x][neighbor_pos.y] = 1  # Neighbor position
		
		# Additionally, mark cells in a small area around the door as walkable
		# This helps with navigation through doorways
		for x in range(max(0, door_pos.x - 1), min(grid_width, door_pos.x + 2)):
			for y in range(max(0, door_pos.y - 1), min(grid_height, door_pos.y + 2)):
				# Only mark cells that are already marked as floor (1) or
				# are in the direct path through the door
				if grid[x][y] == 1 or (door_dir in ["N", "S"] and x == door_pos.x) or (door_dir in ["E", "W"] and y == door_pos.y):
					grid[x][y] = 1
		
		print("Ensuring door passage at ", door_pos, " direction ", door_dir, " and neighbor ", neighbor_pos)

# Add torches to walls at regular intervals
func _add_torches_to_walls() -> void:
	# Load the torch scene
	var torch_scene = load("res://scenes/objects/torch.tscn")
	if not torch_scene:
		printerr("Failed to load torch scene")
		return
	
	# Create a node to hold all torches
	var torches_node = Node3D.new()
	torches_node.name = "Torches"
	dungeon_node.add_child(torches_node)
	
	# Torch placement settings
	var torch_height = room_height * cell_size * 0.7  # Place at 70% of wall height
	
	# Keep track of wall segments with torches to avoid duplicates
	var torch_positions = {}
	
	# Track door positions to avoid placing torches at doors
	var door_positions = {}
	for door in doors:
		door_positions[door["position"]] = door["direction"]
	
	# First, let's build a map of valid wall positions
	var wall_positions = {}  # Dictionary to track wall positions and their directions
	
	# For each floor cell in the grid, check adjacent cells
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] == 1:  # If this is a floor cell
				# Check each adjacent cell for walls
				
				# North (y-1)
				if y == 0 or grid[x][y-1] == 0:
					wall_positions[Vector2i(x, y)] = "N"
				
				# South (y+1)
				if y == grid_height-1 or grid[x][y+1] == 0:
					wall_positions[Vector2i(x, y+1)] = "S"
				
				# East (x+1)
				if x == grid_width-1 or grid[x+1][y] == 0:
					wall_positions[Vector2i(x+1, y)] = "E"
				
				# West (x-1)
				if x == 0 or grid[x-1][y] == 0:
					wall_positions[Vector2i(x, y)] = "W"
	
	# Now place torches only on actual walls
	for pos in wall_positions:
		var x = pos.x
		var y = pos.y
		var wall_dir = wall_positions[pos]
		
		# Only place at valid intervals and not at doors
		if _should_place_torch(x, y, torch_positions, 0) and not _is_door_position(pos, wall_dir, door_positions):
			# Find which room this wall belongs to
			var room_type = "default"
			for room_id in rooms:
				var room = rooms[room_id]
				var room_pos = room["position"]
				var room_size = room["size"]
				
				# Check if position is on the boundary of this room
				var is_on_room = false
				
				if wall_dir == "N" and y == room_pos.y and x >= room_pos.x and x < room_pos.x + room_size.x:
					is_on_room = true
				elif wall_dir == "S" and y == room_pos.y + room_size.y and x >= room_pos.x and x < room_pos.x + room_size.x:
					is_on_room = true
				elif wall_dir == "E" and x == room_pos.x + room_size.x and y >= room_pos.y and y < room_pos.y + room_size.y:
					is_on_room = true
				elif wall_dir == "W" and x == room_pos.x and y >= room_pos.y and y < room_pos.y + room_size.y:
					is_on_room = true
				
				if is_on_room:
					room_type = room["type"]
					break
					
			# Place the torch on this wall
			_place_torch(torch_scene, torches_node, x, y, wall_dir, torch_height, room_type)
			torch_positions[Vector2(x, y)] = true
	
	# Place torches next to doors (but not at door positions)
	for door in doors:
		var door_pos = door["position"]
		var door_dir = door["direction"]
		
		# Find the room this door belongs to
		var room_type = "default"
		var door_room_id = door.get("room_id", "")
		if door_room_id != "" and rooms.has(door_room_id):
			room_type = rooms[door_room_id]["type"]
		else:
			# Try to find the room by checking if the door position is on a room boundary
			for room_id in rooms:
				var room = rooms[room_id]
				var room_pos = room["position"]
				var room_size = room["size"]
				
				# Check if door is on this room's boundary
				if (door_dir == "N" and door_pos.y == room_pos.y and 
					door_pos.x >= room_pos.x and door_pos.x < room_pos.x + room_size.x) or \
				   (door_dir == "S" and door_pos.y == room_pos.y + room_size.y and 
					door_pos.x >= room_pos.x and door_pos.x < room_pos.x + room_size.x) or \
				   (door_dir == "E" and door_pos.x == room_pos.x + room_size.x and 
					door_pos.y >= room_pos.y and door_pos.y < room_pos.y + room_size.y) or \
				   (door_dir == "W" and door_pos.x == room_pos.x and 
					door_pos.y >= room_pos.y and door_pos.y < room_pos.y + room_size.y):
					room_type = room["type"]
					break
		
		# Place torches 1 cell to the sides of the door
		var torch_offset = 1
		
		# For North/South doors, place torches to the left and right
		if door_dir in ["N", "S"]:
			var left_pos = Vector2i(door_pos.x - torch_offset, door_pos.y)
			var right_pos = Vector2i(door_pos.x + torch_offset, door_pos.y)
			
			# Check if these positions are valid walls
			if wall_positions.has(left_pos) and wall_positions[left_pos] == door_dir:
				_place_torch(torch_scene, torches_node, left_pos.x, left_pos.y, door_dir, torch_height, room_type)
				torch_positions[Vector2(left_pos.x, left_pos.y)] = true
			
			if wall_positions.has(right_pos) and wall_positions[right_pos] == door_dir:
				_place_torch(torch_scene, torches_node, right_pos.x, right_pos.y, door_dir, torch_height, room_type)
				torch_positions[Vector2(right_pos.x, right_pos.y)] = true
		else: # East/West doors
			var top_pos = Vector2i(door_pos.x, door_pos.y - torch_offset)
			var bottom_pos = Vector2i(door_pos.x, door_pos.y + torch_offset)
			
			# Check if these positions are valid walls
			if wall_positions.has(top_pos) and wall_positions[top_pos] == door_dir:
				_place_torch(torch_scene, torches_node, top_pos.x, top_pos.y, door_dir, torch_height, room_type)
				torch_positions[Vector2(top_pos.x, top_pos.y)] = true
			
			if wall_positions.has(bottom_pos) and wall_positions[bottom_pos] == door_dir:
				_place_torch(torch_scene, torches_node, bottom_pos.x, bottom_pos.y, door_dir, torch_height, room_type)
				torch_positions[Vector2(bottom_pos.x, bottom_pos.y)] = true
	
	print("Added torches to the dungeon walls with regular spacing")

# Helper to check if a position is a door
func _is_door_position(pos: Vector2i, wall_dir: String, door_positions: Dictionary) -> bool:
	if not door_positions.has(pos):
		return false
		
	# Make sure the door direction matches the wall we're checking
	var door_dir = door_positions[pos]
	return door_dir == wall_dir

# Helper function to determine if a torch should be placed at a given location
func _should_place_torch(x: int, y: int, torch_positions: Dictionary, spacing: int) -> bool:
	# Skip if we already have a torch at this position
	if torch_positions.has(Vector2(x, y)):
		return false
	
	# Check if we're near another torch - we want one every 2 cells
	for offset_x in range(-2, 3):
		for offset_y in range(-2, 3):
			var check_pos = Vector2(x + offset_x, y + offset_y)
			if torch_positions.has(check_pos) and check_pos != Vector2(x, y):
				return false
	
	# Check if position is divisible by 2 to create regular pattern
	# This ensures torches appear every 2 cells along walls
	return (x % 2 == 0 and y % 2 == 0)

# Helper function to place a torch on a wall
func _place_torch(torch_scene, parent_node: Node3D, grid_x: int, grid_y: int, 
				 wall_dir: String, height: float, room_type: String) -> void:
	# Instance the torch scene
	var torch_instance = torch_scene.instantiate()
	torch_instance.name = "Torch_" + str(grid_x) + "_" + str(grid_y)
	
	# Adjust light properties based on room type
	if room_type == "boss":
		torch_instance.light_color = Color(1.0, 0.5, 0.2, 1.0)  # More red/orange
		torch_instance.light_energy = 2.0  # Brighter
	elif room_type == "treasure":
		torch_instance.light_color = Color(0.9, 0.9, 0.2, 1.0)  # Golden
		torch_instance.light_energy = 1.8
	
	# Position the torch on the wall
	var wall_pos = Vector3.ZERO
	var torch_rotation = 0.0
	
	# Position the torch based on wall direction
	match wall_dir:
		"N": # North wall
			wall_pos = Vector3(
				(grid_x * cell_size) + (cell_size / 2),
				height,
				grid_y * cell_size + WALL_THICKNESS/2
			)
			torch_rotation = PI  # Rotate to face south
		"S": # South wall
			wall_pos = Vector3(
				(grid_x * cell_size) + (cell_size / 2),
				height,
				grid_y * cell_size - WALL_THICKNESS/2
			)
			torch_rotation = 0  # Facing north
		"E": # East wall
			wall_pos = Vector3(
				grid_x * cell_size - WALL_THICKNESS/2,
				height,
				(grid_y * cell_size) + (cell_size / 2)
			)
			torch_rotation = PI * 1.5  # Facing west
		"W": # West wall
			wall_pos = Vector3(
				grid_x * cell_size + WALL_THICKNESS/2,
				height,
				(grid_y * cell_size) + (cell_size / 2)
			)
			torch_rotation = PI * 0.5  # Facing east
	
	torch_instance.position = wall_pos
	torch_instance.rotation.y = torch_rotation
	
	# Add the torch to the parent node
	parent_node.add_child(torch_instance)