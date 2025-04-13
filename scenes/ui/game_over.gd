extends "res://scenes/ui/base_menu.gd"

func _ready() -> void:
	super._ready()
	# Game over specific setup
	pass

func _on_retry_button_pressed() -> void:
	# Restart the game from the first-person dungeon
	get_tree().change_scene_to_file("res://scenes/levels/fp_dungeon.tscn") 