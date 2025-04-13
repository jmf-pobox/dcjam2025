extends "res://scenes/ui/base_menu.gd"

@onready var music_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/MusicVolume/HSlider
@onready var sfx_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/SFXVolume/HSlider

func _ready() -> void:
	super._ready()
	# Load current settings from the GameManager
	music_slider.value = GameManager.music_volume * 100
	sfx_slider.value = GameManager.sfx_volume * 100

func _on_back_button_pressed() -> void:
	# Save settings before closing
	GameManager.save_settings()
	
	emit_signal("options_closed")
	queue_free() 