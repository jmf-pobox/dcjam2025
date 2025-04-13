extends Node

# A debug utility to visualize the dungeon grid and walkable areas

static func create_grid_visualization(parent_node: Node3D) -> void:
	# Clear any existing visualization
	for child in parent_node.get_children():
		if child.name.begins_with("GridVis_"):
			child.queue_free()
	
	# Create a parent node for all visualization elements
	var vis_node = Node3D.new()
	vis_node.name = "GridVis_Parent"
	parent_node.add_child(vis_node)
	
	var cell_size = DungeonGenerator3D.DEFAULT_CELL_SIZE
	var room_width = DungeonGenerator3D.DEFAULT_GRID_WIDTH
	var room_depth = DungeonGenerator3D.DEFAULT_GRID_HEIGHT
	
	# Create grid lines
	for x in range(room_width + 1):
		_create_vertical_line(vis_node, x * cell_size, 0, room_depth * cell_size, Color(0.5, 0.5, 0.5, 0.5))
	
	for z in range(room_depth + 1):
		_create_horizontal_line(vis_node, 0, z * cell_size, room_width * cell_size, Color(0.5, 0.5, 0.5, 0.5))
	
	# Highlight walkable area (1,1) to (2,2)
	var walkable_area = CSGBox3D.new()
	walkable_area.name = "GridVis_WalkableArea"
	walkable_area.size = Vector3(2 * cell_size, 0.01, 2 * cell_size)
	walkable_area.position = Vector3(1.5 * cell_size, 0.02, 1.5 * cell_size)
	
	var walkable_material = StandardMaterial3D.new()
	walkable_material.albedo_color = Color(0.0, 0.8, 0.2, 0.3)
	walkable_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	walkable_area.material = walkable_material
	
	vis_node.add_child(walkable_area)
	
	# Add grid position labels
	for x in range(room_width):
		for z in range(room_depth):
			var label_3d = Label3D.new()
			label_3d.name = "GridVis_Label_%d_%d" % [x, z]
			label_3d.text = "(%d,%d)" % [x, z]
			label_3d.position = Vector3(x * cell_size + cell_size/2, 0.05, z * cell_size + cell_size/2)
			label_3d.rotation_degrees.x = -90  # Face upward
			label_3d.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			label_3d.font_size = 48
			label_3d.modulate = Color(1, 1, 1, 0.7)
			vis_node.add_child(label_3d)

static func _create_vertical_line(parent: Node3D, x: float, z_start: float, z_end: float, color: Color) -> void:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "GridVis_VLine_%d_%d_%d" % [x, z_start, z_end]
	
	var immediate_mesh = ImmediateMesh.new()
	mesh_instance.mesh = immediate_mesh
	
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(Vector3(x, 0.03, z_start))
	immediate_mesh.surface_add_vertex(Vector3(x, 0.03, z_end))
	immediate_mesh.surface_end()
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material
	
	parent.add_child(mesh_instance)

static func _create_horizontal_line(parent: Node3D, x_start: float, z: float, x_end: float, color: Color) -> void:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "GridVis_HLine_%d_%d_%d" % [x_start, z, x_end]
	
	var immediate_mesh = ImmediateMesh.new()
	mesh_instance.mesh = immediate_mesh
	
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(Vector3(x_start, 0.03, z))
	immediate_mesh.surface_add_vertex(Vector3(x_end, 0.03, z))
	immediate_mesh.surface_end()
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material
	
	parent.add_child(mesh_instance)