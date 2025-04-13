extends "res://scenes/ui/base_menu.gd"

signal resume_game

func _ready() -> void:
	super._ready()
	# Pause the game
	get_tree().paused = true
	# Make sure this node process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("Pause menu created and visible")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_resume_button_pressed()

func _on_resume_button_pressed() -> void:
	print("Resume button pressed")
	get_tree().paused = false
	emit_signal("resume_game")
	queue_free()

func _on_save_button_pressed() -> void:
	# Save player state
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("save_state"):
		player.save_state()
	
	# Save dungeon state
	var dungeon = get_tree().get_first_node_in_group("dungeon")
	if dungeon and dungeon.has_method("save_state"):
		dungeon.save_state()
	
	# Save game through GameManager
	var game_manager := get_node("/root/GameManager")
	if game_manager and game_manager.save_game():
		print("Game saved successfully")
	else:
		print("Failed to save game")

# Override the base menu's main menu button handler
func _on_main_menu_button_pressed() -> void:
	print("Main menu button pressed - transitioning to main menu")
	# Unpause the game before changing scenes
	get_tree().paused = false
	# Change to the main menu scene first
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	# Then clean up this menu
	queue_free() 
