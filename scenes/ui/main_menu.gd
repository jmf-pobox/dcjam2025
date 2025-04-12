extends Control

func _ready():
	# Setup UI animations or additional elements
	pass
	
# Called when options menu is closed
func _on_options_menu_closed():
	# Handle any actions needed after closing options menu
	pass

func _on_start_button_pressed():
	# Start new game (first-person dungeon)
	get_tree().change_scene_to_file("res://scenes/levels/fp_dungeon.tscn")

func _on_load_button_pressed():
	# Load saved game
	if FileAccess.file_exists("user://save_game.dat"):
		var game_manager = get_node("/root/GameManager")
		game_manager.load_game()
		get_tree().change_scene_to_file("res://scenes/levels/" + game_manager.current_level + ".tscn")

func _on_options_button_pressed():
	# Show options menu
	var options_menu_resource = load("res://scenes/ui/options_menu.tscn")
	if options_menu_resource:
		var options_menu = options_menu_resource.instantiate()
		add_child(options_menu)
		# Connect the options_closed signal
		options_menu.connect("options_closed", _on_options_menu_closed)

func _on_quit_button_pressed():
	# Quit game
	get_tree().quit()
