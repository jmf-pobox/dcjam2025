extends CharacterBody2D

const SPEED = 200.0
const MAX_HEALTH = 100

var health = MAX_HEALTH

@onready var animation_player = $AnimationPlayer

func _physics_process(_delta):
	# Get input direction
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Set velocity based on input
	if direction:
		velocity = direction * SPEED
		
		# Play movement animation
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				animation_player.play("walk_right")
			else:
				animation_player.play("walk_left")
		else:
			if direction.y > 0:
				animation_player.play("walk_down")
			else:
				animation_player.play("walk_up")
	else:
		velocity = Vector2.ZERO
		animation_player.play("idle")
	
	move_and_slide()

# Called when player takes damage
func take_damage(amount):
	health -= amount
	if health <= 0:
		health = 0
		die()

# Called when player dies
func die():
	# Return to main game via game over screen
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn") 