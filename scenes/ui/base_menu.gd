extends Control

# Common signals for all menus
signal menu_closed
signal return_to_main_menu
signal quit_game

# Common menu functions
func _ready() -> void:
	# Setup UI animations or additional elements
	pass

func _on_back_button_pressed() -> void:
	emit_signal("menu_closed")
	queue_free()

func _on_main_menu_button_pressed() -> void:
	# Save game if needed
	var game_manager := get_node("/root/GameManager")
	if game_manager:
		game_manager.save_game()
	
	emit_signal("return_to_main_menu")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_quit_button_pressed() -> void:
	# Save game if needed
	var game_manager := get_node("/root/GameManager")
	if game_manager:
		game_manager.save_game()
	
	emit_signal("quit_game")
	get_tree().quit()

# Audio settings functions
func _on_music_slider_value_changed(value: float) -> void:
	GameManager.set_music_volume(value)

func _on_sfx_slider_value_changed(value: float) -> void:
	GameManager.set_sfx_volume(value) 