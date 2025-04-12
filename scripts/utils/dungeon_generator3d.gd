extends Node3D

class_name DungeonGenerator3D

# Room dimensions (in grid cells)
const ROOM_WIDTH = 4
const ROOM_DEPTH = 4
const ROOM_HEIGHT = 1
const CELL_SIZE = 2.0

# Wall thickness
const WALL_THICKNESS = 0.2

# Generate a simple dungeon room with walls, floor and ceiling
static func generate_dungeon(parent_node: Node3D) -> void:
	# Clear any existing children
	for child in parent_node.get_children():
		if child.name.begins_with("Dungeon_"):
			child.queue_free()
	
	# Create parent node for all dungeon elements
	var dungeon_node = Node3D.new()
	dungeon_node.name = "Dungeon_Elements"
	parent_node.add_child(dungeon_node)
	
	# Generate floor
	_create_floor(dungeon_node)
	
	# Generate ceiling
	_create_ceiling(dungeon_node)
	
	# Generate walls
	_create_walls(dungeon_node)
	
	print("Dungeon generated with room size: ", ROOM_WIDTH, "x", ROOM_DEPTH)

# Create the floor mesh
static func _create_floor(parent: Node3D) -> void:
	var floor_mesh = PlaneMesh.new()
	floor_mesh.size = Vector2(ROOM_WIDTH * CELL_SIZE, ROOM_DEPTH * CELL_SIZE)
	
	var floor_instance = MeshInstance3D.new()
	floor_instance.name = "Dungeon_Floor"
	floor_instance.mesh = floor_mesh
	
	# Position floor at the center of the room, aligned with grid
	floor_instance.position = Vector3(
		(ROOM_WIDTH * CELL_SIZE) / 2, 
		0, 
		(ROOM_DEPTH * CELL_SIZE) / 2
	)
	
	# Create floor material
	var floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.3, 0.3, 0.3) # Dark gray
	floor_instance.set_surface_override_material(0, floor_material)
	
	parent.add_child(floor_instance)

# Create the ceiling mesh
static func _create_ceiling(parent: Node3D) -> void:
	var ceiling_mesh = PlaneMesh.new()
	ceiling_mesh.size = Vector2(ROOM_WIDTH * CELL_SIZE, ROOM_DEPTH * CELL_SIZE)
	
	var ceiling_instance = MeshInstance3D.new()
	ceiling_instance.name = "Dungeon_Ceiling"
	ceiling_instance.mesh = ceiling_mesh
	
	# Position ceiling at the center of the room, at height
	ceiling_instance.position = Vector3(
		(ROOM_WIDTH * CELL_SIZE) / 2,
		CELL_SIZE,
		(ROOM_DEPTH * CELL_SIZE) / 2
	)
	
	# Flip ceiling to face downward
	ceiling_instance.rotation_degrees.x = 180
	
	# Create ceiling material
	var ceiling_material = StandardMaterial3D.new()
	ceiling_material.albedo_color = Color(0.15, 0.15, 0.2) # Dark blue-gray
	ceiling_instance.set_surface_override_material(0, ceiling_material)
	
	parent.add_child(ceiling_instance)

# Create all the walls
static func _create_walls(parent: Node3D) -> void:
	var room_width = ROOM_WIDTH * CELL_SIZE
	var room_depth = ROOM_DEPTH * CELL_SIZE
	var wall_height = CELL_SIZE
	
	# Create base wall material
	var wall_material = StandardMaterial3D.new()
	wall_material.albedo_color = Color(0.6, 0.5, 0.4) # Beige-brown
	
	# North wall (Z=0)
	var north_wall = BoxMesh.new()
	north_wall.size = Vector3(room_width, wall_height, WALL_THICKNESS)
	
	var north_wall_instance = MeshInstance3D.new()
	north_wall_instance.name = "Dungeon_Wall_North"
	north_wall_instance.mesh = north_wall
	north_wall_instance.position = Vector3(
		room_width / 2,
		wall_height / 2,
		0 - WALL_THICKNESS / 2
	)
	north_wall_instance.set_surface_override_material(0, wall_material)
	parent.add_child(north_wall_instance)
	
	# South wall (Z=depth)
	var south_wall = BoxMesh.new()
	south_wall.size = Vector3(room_width, wall_height, WALL_THICKNESS)
	
	var south_wall_instance = MeshInstance3D.new()
	south_wall_instance.name = "Dungeon_Wall_South"
	south_wall_instance.mesh = south_wall
	south_wall_instance.position = Vector3(
		room_width / 2,
		wall_height / 2,
		room_depth + WALL_THICKNESS / 2
	)
	south_wall_instance.set_surface_override_material(0, wall_material)
	parent.add_child(south_wall_instance)
	
	# East wall (X=width)
	var east_wall = BoxMesh.new()
	east_wall.size = Vector3(WALL_THICKNESS, wall_height, room_depth)
	
	var east_wall_instance = MeshInstance3D.new()
	east_wall_instance.name = "Dungeon_Wall_East"
	east_wall_instance.mesh = east_wall
	east_wall_instance.position = Vector3(
		room_width + WALL_THICKNESS / 2,
		wall_height / 2,
		room_depth / 2
	)
	east_wall_instance.set_surface_override_material(0, wall_material)
	parent.add_child(east_wall_instance)
	
	# West wall (X=0)
	var west_wall = BoxMesh.new()
	west_wall.size = Vector3(WALL_THICKNESS, wall_height, room_depth)
	
	var west_wall_instance = MeshInstance3D.new()
	west_wall_instance.name = "Dungeon_Wall_West"
	west_wall_instance.mesh = west_wall
	west_wall_instance.position = Vector3(
		0 - WALL_THICKNESS / 2,
		wall_height / 2,
		room_depth / 2
	)
	west_wall_instance.set_surface_override_material(0, wall_material)
	parent.add_child(west_wall_instance)