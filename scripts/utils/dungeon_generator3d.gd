extends Node3D

class_name DungeonGenerator3D

# Default room dimensions if not specified
const DEFAULT_GRID_WIDTH = 20
const DEFAULT_GRID_HEIGHT = 20 
const DEFAULT_CELL_SIZE = 2.0
const DEFAULT_ROOM_HEIGHT = 1.0

# Wall thickness
const WALL_THICKNESS = 0.2

# Materials (loaded in _ready)
var floor_material: Material
var ceiling_material: Material
var wall_material: Material

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
	var ceiling_mat_res = load("res://resources/ceiling_material.tres")
	var wall_mat_res = load("res://resources/wall_material.tres")
	
	# Use loaded materials if available, otherwise create new ones
	if floor_mat_res:
		floor_material = floor_mat_res
	else:
		floor_material = StandardMaterial3D.new()
		floor_material.albedo_color = Color(0.3, 0.3, 0.3) # Dark gray
	
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
		
		floor_instance.set_surface_override_material(0, floor_material)
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
	wall_instance.set_surface_override_material(0, wall_material)
	
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