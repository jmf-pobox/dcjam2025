extends CharacterBody2D

class_name GridPlayer

# Grid-based movement constants
const CELL_SIZE = 64
const MOVE_SPEED = 3.0 # Cells per second

# Player properties
const MAX_HEALTH = 100

# Player state
var health = MAX_HEALTH
var current_direction = Vector2.DOWN  # Initial facing direction
var target_position = Vector2.ZERO    # Target grid position
var is_moving = false                 # Currently moving between grid cells
var grid_position = Vector2.ZERO      # Current grid position

# Node references
@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D

# Movement direction enum for clarity
enum Direction { UP, RIGHT, DOWN, LEFT }
var current_direction_enum = Direction.DOWN

func _ready():
	# Initialize position to grid alignment
	position = position.snapped(Vector2(CELL_SIZE, CELL_SIZE)) + Vector2(CELL_SIZE/2, CELL_SIZE/2)
	target_position = position
	grid_position = Vector2(round(position.x / CELL_SIZE), round(position.y / CELL_SIZE))
	print("Player initialized at grid position: ", grid_position)

func _process(delta):
	# Handle movement animation and transitions
	if position.distance_to(target_position) > 1:
		# Move towards target position
		position = position.move_toward(target_position, CELL_SIZE * MOVE_SPEED * delta)
		is_moving = true
	else:
		# Snap to grid when close enough
		position = target_position
		is_moving = false
		
	# Update animation based on current direction and movement state
	_update_animation()

func _physics_process(_delta):
	if is_moving:
		return
	
	# Only handle input when not currently moving
	if Input.is_action_just_pressed("move_up"):
		if current_direction_enum == Direction.UP:
			# Move forward
			_try_move(Vector2.UP)
		else:
			# Turn to face up
			current_direction_enum = Direction.UP
			current_direction = Vector2.UP
	
	elif Input.is_action_just_pressed("move_down"):
		if current_direction_enum == Direction.DOWN:
			# Move forward
			_try_move(Vector2.DOWN)
		else:
			# Turn to face down
			current_direction_enum = Direction.DOWN
			current_direction = Vector2.DOWN
	
	elif Input.is_action_just_pressed("move_left"):
		if current_direction_enum == Direction.LEFT:
			# Move forward
			_try_move(Vector2.LEFT)
		else:
			# Turn to face left
			current_direction_enum = Direction.LEFT
			current_direction = Vector2.LEFT
	
	elif Input.is_action_just_pressed("move_right"):
		if current_direction_enum == Direction.RIGHT:
			# Move forward
			_try_move(Vector2.RIGHT)
		else:
			# Turn to face right
			current_direction_enum = Direction.RIGHT
			current_direction = Vector2.RIGHT

# Try to move in the given direction
func _try_move(dir: Vector2):
	var new_grid_pos = grid_position + dir
	
	# Check if movement is valid (not outside dungeon bounds)
	if _is_valid_move(new_grid_pos):
		# Update grid position
		grid_position = new_grid_pos
		# Set target position for smooth movement
		target_position = Vector2(grid_position.x * CELL_SIZE, grid_position.y * CELL_SIZE) + Vector2(CELL_SIZE/2, CELL_SIZE/2)
		
		print("Moving to grid position: ", grid_position)

# Check if a move to the given grid position is valid
func _is_valid_move(grid_pos: Vector2) -> bool:
	# Check bounds of the 2x2 room
	return grid_pos.x >= 0 and grid_pos.x < 2 and grid_pos.y >= 0 and grid_pos.y < 2

# Update the player's visual based on direction and movement
func _update_animation():
	# Update sprite rotation/flip based on direction
	match current_direction_enum:
		Direction.UP:
			sprite.rotation_degrees = 0
			sprite.flip_h = false
			if is_moving:
				if animation_player.has_animation("walk_up"):
					animation_player.play("walk_up")
				else:
					animation_player.play("idle")
			else:
				animation_player.play("idle")
		
		Direction.RIGHT:
			sprite.rotation_degrees = 90
			sprite.flip_h = false
			if is_moving:
				if animation_player.has_animation("walk_right"):
					animation_player.play("walk_right")
				else:
					animation_player.play("idle")
			else:
				animation_player.play("idle")
		
		Direction.DOWN:
			sprite.rotation_degrees = 180
			sprite.flip_h = false
			if is_moving:
				if animation_player.has_animation("walk_down"):
					animation_player.play("walk_down")
				else:
					animation_player.play("idle")
			else:
				animation_player.play("idle")
		
		Direction.LEFT:
			sprite.rotation_degrees = 270
			sprite.flip_h = false
			if is_moving:
				if animation_player.has_animation("walk_left"):
					animation_player.play("walk_left")
				else:
					animation_player.play("idle")
			else:
				animation_player.play("idle")

# Called when player takes damage
func take_damage(amount):
	health -= amount
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
