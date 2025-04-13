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

# Override the base menu's main menu button handler
func _on_main_menu_button_pressed() -> void:
	print("Main menu button pressed - transitioning to main menu")
	# Unpause the game before changing scenes
	get_tree().paused = false
	# Change to the main menu scene first
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	# Then clean up this menu
	queue_free() 
