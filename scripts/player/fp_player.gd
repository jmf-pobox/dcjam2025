extends Node3D

class_name FirstPersonPlayer

# Grid-based movement constants
const CELL_SIZE = 2.0
const MOVE_SPEED = 2.0 # Cells per second
const ROTATION_SPEED = 5.0 # Rotations per second

# Player properties
const MAX_HEALTH = 100
const ATTACK_DAMAGE = 25
const ATTACK_COOLDOWN = 0.7

# Player state
var health = MAX_HEALTH
var grid_position = Vector2i(0, 0) # Current grid position (x,z)
var facing_cardinal = Cardinal.SOUTH # Cardinal direction the player is facing
var target_position = Vector3.ZERO # Target world position
var target_rotation = Vector3.ZERO # Target rotation
var is_moving = false # Currently moving between grid cells
var is_turning = false # Currently turning
var can_attack = true # Attack cooldown state

# Cardinal directions enum for clarity
enum Cardinal { NORTH, EAST, SOUTH, WEST }
enum Action { NONE, MOVE_FORWARD, MOVE_BACKWARD, TURN_LEFT, TURN_RIGHT }
var current_action = Action.NONE

# Node references
@onready var camera = $Camera3D
@onready var raycast = $RayCast3D

# Debug properties
var enable_debug_output = true

func _ready():
	# Add player to the "player" group for enemy detection
	add_to_group("player")
	print("Player added to 'player' group")
	
	# Initialize position to grid alignment
	_update_grid_to_world_position()
	position = target_position  # Set initial position to match target position
	
	# Initialize facing direction to South (looking away from the north wall)
	facing_cardinal = Cardinal.SOUTH
	rotation_degrees.y = _cardinal_to_degrees(facing_cardinal)
	
	# Set camera parameters
	camera.position.y = 0.6  # Eye level, adjusted higher
	camera.rotation_degrees.x = -5  # Slight downward angle
	
	# Make sure raycast is enabled
	raycast.enabled = true
	
	_debug_print("Player initialized at grid position: %s facing: %s" % [grid_position, _cardinal_to_string(facing_cardinal)])

func _process(delta):
	# Only accept input when not already moving or turning
	if !is_moving && !is_turning:
		_check_input()
	
	# Handle animations
	if is_moving:
		_process_movement(delta)
	elif is_turning:
		_process_rotation(delta)
		
	# Check for attack input
	if Input.is_action_just_pressed("attack") and can_attack:
		_attack()

func _process_movement(delta):
	var distance_to_target = position.distance_to(target_position)
	
	if distance_to_target > 0.05:
		# Move towards target position
		position = position.move_toward(target_position, CELL_SIZE * MOVE_SPEED * delta)
	else:
		# Snap to grid when close enough
		position = target_position
		is_moving = false
		current_action = Action.NONE
		_debug_print("Moved to grid position: %s" % grid_position)

func _process_rotation(delta):
	var current_rot_y = fmod(rotation_degrees.y, 360)
	if current_rot_y < 0:
		current_rot_y += 360
		
	var target_rot_y = fmod(target_rotation.y, 360)
	
	# Find the shortest rotation path
	var diff = target_rot_y - current_rot_y
	if abs(diff) > 180:
		diff = diff - 360 * sign(diff)
	
	# Apply rotation with a max speed
	if abs(diff) > 0.5:
		var rotation_step = sign(diff) * min(abs(diff), 90 * ROTATION_SPEED * delta)
		rotation_degrees.y += rotation_step
	else:
		# We've reached the target rotation
		rotation_degrees.y = target_rot_y
		is_turning = false
		current_action = Action.NONE
		_debug_print("Rotated to cardinal direction: %s" % _cardinal_to_string(facing_cardinal))

func _check_input():
	# WASD / Arrow key controls - First-Person Perspective:
	# W / Up Arrow: Move in the OPPOSITE direction you're facing
	# S / Down Arrow: Move in the SAME direction you're facing
	# A / Left Arrow: TURN LEFT (now actually turning clockwise)
	# D / Right Arrow: TURN RIGHT (now actually turning counter-clockwise)
	
	if Input.is_action_just_pressed("move_up"):  # W or Up Arrow
		move_forward()
	elif Input.is_action_just_pressed("move_down"):  # S or Down Arrow
		move_backward()
	elif Input.is_action_just_pressed("move_left"):  # A or Left Arrow
		turn_left()
	elif Input.is_action_just_pressed("move_right"):  # D or Right Arrow
		turn_right()

# PUBLIC METHODS - Movement controls from first-person perspective

func move_forward():
	"""Move one cell forward in the direction the player is facing."""
	if is_moving or is_turning:
		return
		
	if _can_move_backward():  # Changed to backward check
		current_action = Action.MOVE_FORWARD
		var direction_vector = _get_forward_vector()
		grid_position -= direction_vector  # Changed to subtract (backward movement)
		_update_grid_to_world_position()
		is_moving = true
		_debug_print("Moving forward (now in direction opposite of %s)" % _cardinal_to_string(facing_cardinal))

func move_backward():
	"""Move one cell backward (opposite of the direction the player is facing)."""
	if is_moving or is_turning:
		return
		
	if _can_move_forward():  # Changed to forward check
		current_action = Action.MOVE_BACKWARD
		var direction_vector = _get_forward_vector()
		grid_position += direction_vector  # Changed to add (forward movement)
		_update_grid_to_world_position()
		is_moving = true
		_debug_print("Moving backward (now in direction: %s)" % _cardinal_to_string(facing_cardinal))

func turn_left():
	"""Turn 90 degrees counter-clockwise."""
	if is_moving or is_turning:
		return
		
	current_action = Action.TURN_LEFT
	var new_cardinal = _get_right_cardinal()  # Changed to right cardinal
	# Explicitly cast to the Cardinal enum type
	facing_cardinal = Cardinal.values()[new_cardinal]
	_update_target_rotation()
	is_turning = true
	_debug_print("Turning left (now clockwise) to face: %s" % _cardinal_to_string(facing_cardinal))

func turn_right():
	"""Turn 90 degrees clockwise."""
	if is_moving or is_turning:
		return
		
	current_action = Action.TURN_RIGHT
	var new_cardinal = _get_left_cardinal()  # Changed to left cardinal
	facing_cardinal = new_cardinal  # Cardinal direction is already an integer
	_update_target_rotation()
	is_turning = true
	_debug_print("Turning right (now counter-clockwise) to face: %s" % _cardinal_to_string(facing_cardinal))

# PRIVATE METHODS - Helper functions

func _update_grid_to_world_position():
	"""Convert grid position to world position."""
	target_position = Vector3(
		grid_position.x * CELL_SIZE + CELL_SIZE / 2, 
		0.5, 
		grid_position.y * CELL_SIZE + CELL_SIZE / 2
	)

func _update_target_rotation():
	"""Set target rotation based on cardinal direction."""
	target_rotation = Vector3(0, _cardinal_to_degrees(facing_cardinal), 0)

func _cardinal_to_degrees(cardinal: int) -> float:
	"""Convert cardinal direction to rotation degrees (y-axis)."""
	match cardinal:
		Cardinal.NORTH: return 0    # Looking toward positive Z
		Cardinal.EAST:  return 90   # Looking toward positive X
		Cardinal.SOUTH: return 180  # Looking toward negative Z
		Cardinal.WEST:  return 270  # Looking toward negative X
	return 0

func _get_forward_vector() -> Vector2i:
	"""Get the movement vector for moving forward in current direction."""
	match facing_cardinal:
		Cardinal.NORTH: return Vector2i(0, 1)   # Z+ in Godot 3D
		Cardinal.EAST:  return Vector2i(1, 0)   # X+ in Godot 3D
		Cardinal.SOUTH: return Vector2i(0, -1)  # Z- in Godot 3D
		Cardinal.WEST:  return Vector2i(-1, 0)  # X- in Godot 3D
	return Vector2i(0, 0)

func _get_left_cardinal() -> int:
	"""Get the cardinal direction to the left of current facing."""
	return (facing_cardinal - 1 + 4) % 4

func _get_right_cardinal() -> int:
	"""Get the cardinal direction to the right of current facing."""
	return (facing_cardinal + 1) % 4

func _can_move_forward() -> bool:
	"""Check if moving forward is valid."""
	var new_pos = grid_position + _get_forward_vector()
	return _is_valid_position(new_pos)

func _can_move_backward() -> bool:
	"""Check if moving backward is valid."""
	var new_pos = grid_position - _get_forward_vector()
	return _is_valid_position(new_pos)

func _is_valid_position(pos: Vector2i) -> bool:
	"""Check if a grid position is valid for movement (has a floor or is a door, and no enemy is there)."""
	# Get reference to the dungeon generator
	var dungeon_scene = get_tree().current_scene
	if not dungeon_scene:
		return false
		
	var dungeon_generator = dungeon_scene.get_node("DungeonGenerator3D")
	if not dungeon_generator:
		# Fall back to old behavior if no dungeon generator found
		return pos.x >= 1 and pos.x <= 2 and pos.y >= 1 and pos.y <= 2
	
	# Check if this position is within grid bounds
	if pos.x < 0 or pos.x >= dungeon_generator.grid_width or pos.y < 0 or pos.y >= dungeon_generator.grid_height:
		return false
	
	# Check if this is a floor cell (value 1)
	var is_walkable = dungeon_generator.grid[pos.x][pos.y] == 1
	
	# Enhanced door detection and logging
	if not is_walkable:
		for door in dungeon_generator.doors:
			var door_pos = door["position"]
			var door_dir = door["direction"]
			
			# Check if this is a door position
			if door_pos.x == pos.x and door_pos.y == pos.y:
				# This is a door position
				_debug_print("=== DOOR PASSAGE ===")
				_debug_print("Door found at position: " + str(pos) + ", direction: " + door_dir)
				
				# Calculate movement direction relative to door
				var move_dir = "Unknown"
				if current_action == Action.MOVE_FORWARD:
					move_dir = "Forward (opposite facing)"
				elif current_action == Action.MOVE_BACKWARD:
					move_dir = "Backward (same as facing)"
				
				_debug_print("Player movement: " + move_dir)
				_debug_print("Player facing: " + _cardinal_to_string(facing_cardinal))
				
				# Log which room we're moving to
				for room in dungeon_generator.rooms:
					for r_door in room.get("doors", []):
						if r_door.get("connects_to") == door.get("connects_to"):
							_debug_print("Moving to room: " + str(room.get("id")))
				
				return true
	
	# Check if there's an enemy at this position
	var entities_node = dungeon_scene.find_child("Entities", true, false)
	if entities_node:
		for enemy in entities_node.get_children():
			if enemy.is_in_group("enemy") and enemy.state != "die":
				# Convert enemy position to grid position
				var enemy_grid_pos = Vector2i(
					int(enemy.global_position.x / CELL_SIZE),
					int(enemy.global_position.z / CELL_SIZE)
				)
				
				# Check if enemy is at the position we want to move to
				if enemy_grid_pos == pos:
					_debug_print("Cannot move to position " + str(pos) + " because an enemy is there")
					return false
	
	return is_walkable

func _cardinal_to_string(dir: int) -> String:
	"""Convert cardinal direction to string for debugging."""
	match dir:
		Cardinal.NORTH: return "North"
		Cardinal.EAST: return "East"
		Cardinal.SOUTH: return "South"
		Cardinal.WEST: return "West"
	return "Unknown"

func _debug_print(message: String) -> void:
	"""Print debug messages if debug output is enabled."""
	if enable_debug_output:
		print(message)

# Called when player takes damage
func take_damage(amount):
	health -= amount
	print("Player took damage: ", amount, " health remaining: ", health)
	if health <= 0:
		health = 0
		die()

# Called when player dies
func die():
	# Implement game over logic
	var game_manager = get_node("/root/GameManager")
	if game_manager:
		game_manager.game_over()
	else:
		get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")

func _attack():
	can_attack = false
	
	print("Attack action triggered!")
	
	# Check if raycast is enabled
	if not raycast.enabled:
		print("RayCast3D is disabled!")
		raycast.enabled = true
	
	# IMPORTANT: Don't override the raycast position here
	# as it would counteract the node's position in the scene
	
	# Get all enemies in the scene
	var entities_node = get_tree().current_scene.find_child("Entities", true, false)
	if entities_node:
		var closest_enemy = null
		var closest_distance = 3.0  # Max attack range
		
		# Check each enemy for distance
		for enemy in entities_node.get_children():
			if enemy.is_in_group("enemy") and enemy.state != "die":
				var distance = global_position.distance_to(enemy.global_position)
				var forward = -global_transform.basis.z  # This is the player's forward direction
				var to_enemy = (enemy.global_position - global_position).normalized()
				
				# Calculate dot product to see if enemy is in front of player
				var dot_product = forward.dot(to_enemy)
				
				print("Enemy: ", enemy.name, " distance: ", distance, " dot: ", dot_product)
				
				# If enemy is in front of player (within ~60 degree cone) and closer than previous closest
				if dot_product > 0.5 and distance < closest_distance:
					closest_enemy = enemy
					closest_distance = distance
		
		# Attack the closest enemy in front of player
		if closest_enemy:
			print("Attacking closest enemy: ", closest_enemy.name, " at distance: ", closest_distance)
			closest_enemy.take_damage(ATTACK_DAMAGE)
	else:
		print("No entities node found in scene!")
	
	# Use a direct timer instead of get_tree().create_timer
	var attack_timer = Timer.new()
	attack_timer.wait_time = ATTACK_COOLDOWN
	attack_timer.one_shot = true
	attack_timer.autostart = false
	add_child(attack_timer)
	
	# Connect the timeout signal
	attack_timer.timeout.connect(func():
		if is_instance_valid(self):
			can_attack = true
		attack_timer.queue_free()
	)
	
	# Start the timer
	attack_timer.start()