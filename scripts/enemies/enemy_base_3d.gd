extends CharacterBody3D

class_name EnemyBase3D

const SPEED = 2.0
const TURN_SPEED = 1.5
const ATTACK_DAMAGE = 15
const ATTACK_COOLDOWN = 1.5

@export var max_health: int = 50
@export var damage: int = 10
@export var detection_radius: float = 5.0

var health = max_health
var player = null
var state = "idle"
var can_attack = true

@onready var animation_player = $AnimationPlayer
@onready var detection_area = $DetectionArea

var current_grid_position = Vector2i(0, 0)
var target_grid_position = Vector2i(0, 0)
var is_moving_to_grid_pos = false
var cell_size = 2.0  # Same as player's CELL_SIZE

func _ready():
	health = max_health
	# Set collision layers
	collision_layer = 2
	collision_mask = 1
	
	# Initialize grid position
	current_grid_position = Vector2i(
		int(global_position.x / cell_size),
		int(global_position.z / cell_size)
	)
	target_grid_position = current_grid_position
	
	# Make sure detection is working
	print("Enemy initialized with detection radius: ", detection_radius)
	print("Enemy initialized at position: ", global_position)
	print("Enemy grid position: ", current_grid_position)
	
	# Create a repeating timer to scan for player
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_scan_for_player)
	add_child(timer)

func _physics_process(delta):
	match state:
		"idle":
			if animation_player.has_animation("idle"):
				animation_player.play("idle")
			velocity = Vector3.ZERO
		"chase":
			if player:
				# If we're not currently moving between grid positions
				if !is_moving_to_grid_pos:
					# Calculate the player's grid position
					var player_grid_pos = Vector2i(
						int(player.global_position.x / cell_size),
						int(player.global_position.z / cell_size)
					)
					
					# Only print position update occasionally to reduce spam
					if Engine.get_frames_drawn() % 60 == 0:
						print("Enemy at grid: ", current_grid_position, " Player at grid: ", player_grid_pos)
					
					# Calculate grid-based movement direction (only move 1 cell at a time)
					var diff_x = player_grid_pos.x - current_grid_position.x
					var diff_y = player_grid_pos.y - current_grid_position.y
					
					# Determine next grid position to move to
					var next_grid_pos = current_grid_position
					
					# Prioritize moving on the axis with greater distance
					if abs(diff_x) > abs(diff_y):
						# Move horizontally first
						next_grid_pos.x += sign(diff_x)
					elif abs(diff_y) > 0:
						# Move vertically
						next_grid_pos.y += sign(diff_y)
					elif abs(diff_x) > 0:
						# Move horizontally if vertical distance is 0
						next_grid_pos.x += sign(diff_x)
					
					# Only attempt to move if the next position is different
					if next_grid_pos != current_grid_position:
						# Check if the position is valid (a floor and not occupied by the player)
						if _is_valid_grid_position(next_grid_pos):
							target_grid_position = next_grid_pos
							is_moving_to_grid_pos = true
							
							# Calculate world position for the target grid position
							var target_world_pos = Vector3(
								target_grid_position.x * cell_size + cell_size / 2,
								global_position.y,  # Keep same height
								target_grid_position.y * cell_size + cell_size / 2
							)
							
							# Set direction for rotation
							var direction = (target_world_pos - global_position).normalized()
							if direction != Vector3.ZERO:
								var target_rotation = atan2(direction.x, direction.z)
								rotation.y = lerp_angle(rotation.y, target_rotation, TURN_SPEED * delta)
						else:
							# If we can't move to the next grid position, try to find another path
							# For now, we'll just wait and try again next frame
							pass
				
				# If we're moving to a grid position
				if is_moving_to_grid_pos:
					# Calculate world position for the target grid position
					var target_world_pos = Vector3(
						target_grid_position.x * cell_size + cell_size / 2,
						global_position.y,  # Keep same height
						target_grid_position.y * cell_size + cell_size / 2
					)
					
					# Calculate distance to target
					var distance_to_target = global_position.distance_to(target_world_pos)
					
					if distance_to_target > 0.1:
						# Move towards target position
						var direction = (target_world_pos - global_position).normalized()
						velocity = direction * SPEED
						move_and_slide()
					else:
						# We've reached the target position
						global_position = target_world_pos  # Snap to grid
						current_grid_position = target_grid_position
						is_moving_to_grid_pos = false
						velocity = Vector3.ZERO
				
				# Check if we can attack the player
				var distance_to_player = global_position.distance_to(player.global_position)
				
				# Calculate player's grid position
				var player_grid_pos = Vector2i(
					int(player.global_position.x / cell_size),
					int(player.global_position.z / cell_size)
				)
				
				# Check if we're adjacent to the player (in grid terms)
				var grid_distance = abs(current_grid_position.x - player_grid_pos.x) + abs(current_grid_position.y - player_grid_pos.y)
				
				if grid_distance <= 1 and can_attack:
					print("Adjacent to player! Attacking")
					_attack_player()
			else:
				# Try to find player again
				_try_find_player()
				
				if !player:
					state = "idle"
					velocity = Vector3.ZERO
		"hurt":
			if animation_player.has_animation("hurt"):
				animation_player.play("hurt")
			else:
				state = "chase"
			velocity = Vector3.ZERO
		"attack":
			if animation_player.has_animation("attack"):
				animation_player.play("attack")
			else:
				state = "chase"
			velocity = Vector3.ZERO
		"die":
			# No movement in death state
			if animation_player.has_animation("die"):
				animation_player.play("die")
			velocity = Vector3.ZERO
			is_moving_to_grid_pos = false

func _is_valid_grid_position(grid_pos: Vector2i) -> bool:
	# Get reference to the dungeon generator
	var dungeon_scene = get_tree().current_scene
	if not dungeon_scene:
		return false
		
	var dungeon_generator = dungeon_scene.find_child("DungeonGenerator3D", true, false)
	if not dungeon_generator:
		return false
	
	# Check if the position is within bounds
	if grid_pos.x < 0 or grid_pos.x >= dungeon_generator.grid_width or grid_pos.y < 0 or grid_pos.y >= dungeon_generator.grid_height:
		return false
	
	# Check if this is a floor cell
	var is_floor = dungeon_generator.grid[grid_pos.x][grid_pos.y] == 1
	if !is_floor:
		# Check if it's a door
		for door in dungeon_generator.doors:
			var door_pos = door["position"]
			if door_pos.x == grid_pos.x and door_pos.y == grid_pos.y:
				return true
		return false
	
	# Check if the player is at this position
	var player_node = dungeon_scene.find_child("Player", true, false)
	if player_node:
		var player_grid_pos = Vector2i(
			int(player_node.global_position.x / cell_size),
			int(player_node.global_position.z / cell_size)
		)
		if player_grid_pos == grid_pos:
			return false
	
	return true

func _on_detection_area_body_entered(body):
	print("Body entered detection area: ", body.name)
	if body.is_in_group("player"):
		player = body
		state = "chase"
		print("Player detected by enemy")

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player = null
		state = "idle"
		print("Player left enemy detection area")

func _attack_player():
	if player and can_attack:
		can_attack = false
		state = "attack"
		player.take_damage(ATTACK_DAMAGE)
		print("Enemy attacked player!")
		
		# Create a timer instead of using get_tree().create_timer
		# This prevents crashes if the node is freed during the cooldown
		var cooldown_timer = Timer.new()
		cooldown_timer.wait_time = ATTACK_COOLDOWN
		cooldown_timer.one_shot = true
		cooldown_timer.autostart = false
		add_child(cooldown_timer)
		
		cooldown_timer.timeout.connect(func():
			# Check if we've been freed
			if is_instance_valid(self):
				can_attack = true
				if state == "attack":
					state = "chase"
			# Clean up the timer
			cooldown_timer.queue_free()
		)
		
		cooldown_timer.start()
	else:
		# If we somehow got here with no player reference
		state = "idle"

func take_damage(amount):
	health -= amount
	state = "hurt"
	print("Enemy took damage: ", amount, " health remaining: ", health)
	if health <= 0:
		die()

func die():
	state = "die"
	print("Enemy died!")
	# Disable collision so player can walk through
	collision_layer = 0
	collision_mask = 0
	# Make it red to show it's dead
	if has_node("MeshInstance3D"):
		var mesh = $MeshInstance3D
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.8, 0.2, 0.2, 0.5)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.set_surface_override_material(0, material)
	
	# Use a direct timer instead of get_tree().create_timer
	var death_timer = Timer.new()
	death_timer.wait_time = 1.0
	death_timer.one_shot = true
	death_timer.autostart = false
	add_child(death_timer)
	
	# Connect the timeout signal
	death_timer.timeout.connect(func():
		queue_free()
		death_timer.queue_free()
	)
	
	# Start the timer
	death_timer.start()

func _scan_for_player():
	# Manual check for player in range
	if state == "idle":
		_try_find_player()

func _try_find_player():
	# Try to find the player in the scene
	var player_node = get_tree().current_scene.find_child("Player", true, false)
	if player_node and player_node.is_in_group("player"):
		var distance = global_position.distance_to(player_node.global_position)
		if distance < detection_radius:
			print("Player found within detection radius: ", distance)
			player = player_node
			state = "chase"
			return true
	return false