extends CharacterBody2D

class_name EnemyBase

const SPEED = 100.0

@export var max_health: int = 50
@export var damage: int = 10
@export var detection_radius: float = 300.0

var health = max_health
var player = null
var state = "idle"

@onready var animation_player = $AnimationPlayer
@onready var detection_area = $DetectionArea

func _ready():
	health = max_health

# Main physics function that controls enemy behavior
func _physics_process(_delta):
	match state:
		"idle":
			if animation_player.has_animation("idle"):
				animation_player.play("idle")
			velocity = Vector2.ZERO
		"chase":
			if player:
				var direction = global_position.direction_to(player.global_position)
				velocity = direction * SPEED
				
				# Choose animation based on movement direction
				if abs(direction.x) > abs(direction.y):
					if direction.x > 0:
						if animation_player.has_animation("walk_right"):
							animation_player.play("walk_right")
					else:
						if animation_player.has_animation("walk_left"):
							animation_player.play("walk_left")
				else:
					if direction.y > 0:
						if animation_player.has_animation("walk_down"):
							animation_player.play("walk_down")
					else:
						if animation_player.has_animation("walk_up"):
							animation_player.play("walk_up")
				
				# Apply movement
				move_and_slide()
			else:
				# If player reference is lost, go back to idle state
				state = "idle"
				velocity = Vector2.ZERO
		"attack":
			if animation_player.has_animation("attack"):
				animation_player.play("attack")
			else:
				state = "chase" # Fall back to chase state if attack animation missing
		"hurt":
			if animation_player.has_animation("hurt"):
				animation_player.play("hurt")
			else:
				state = "chase" # Fall back to chase state if hurt animation missing
		"die":
			if animation_player.has_animation("die"):
				animation_player.play("die")
			else:
				queue_free() # Just remove the enemy if die animation missing

# Called when player enters detection radius
func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body
		state = "chase"
		print("Player detected by enemy")

# Called when player exits detection radius
func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player = null
		state = "idle"
		print("Player left enemy detection area")

# Called when enemy takes damage
func take_damage(amount):
	health -= amount
	state = "hurt"
	if health <= 0:
		die()

# Called when enemy dies
func die():
	state = "die"
	# Wait for death animation to complete
	await get_tree().create_timer(1.0).timeout
	queue_free()

# Called when enemy attacks player
func attack_player():
	if player and state == "chase":
		var distance = global_position.distance_to(player.global_position)
		if distance < 50:  # Attack range
			state = "attack"
			player.take_damage(damage)
			await get_tree().create_timer(1.0).timeout
			state = "chase"