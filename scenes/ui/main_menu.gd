extends "res://scenes/ui/base_menu.gd"

func _ready() -> void:
	super._ready()
	# Main menu specific setup
	pass

func _on_start_button_pressed() -> void:
	# Start new game (first-person dungeon)
	get_tree().change_scene_to_file("res://scenes/levels/fp_dungeon.tscn")

func _on_options_button_pressed() -> void:
	# Show options menu
	var options_menu_resource := load("res://scenes/ui/options_menu.tscn")
	if options_menu_resource:
		var options_menu: Control = options_menu_resource.instantiate()
		add_child(options_menu)
		# Connect the menu_closed signal
		options_menu.connect("menu_closed", _on_options_menu_closed)

func _on_options_menu_closed() -> void:
	# Handle any actions needed after closing options menu
	pass

func _on_quit_button_pressed():
	# Quit game
	get_tree().quit()
