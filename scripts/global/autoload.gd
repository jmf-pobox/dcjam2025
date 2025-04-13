extends Node

# Make the Game Manager a singleton (autoload)
# To use this, add it to your project's autoload
# Project Settings > Autoload > Add this script as "GameManager"

const SAVE_PATH = "user://settings.dat"
const MUSIC_BUS_IDX = 1
const SFX_BUS_IDX = 2

signal score_changed(new_score)
signal health_changed(new_health)

var current_level: String = "level_1"
var player_health: int = 100
var player_score: int = 0
var player_inventory = []
var player_max_health: int = 100
var player_position: Vector3 = Vector3.ZERO
var player_grid_position: Vector2i = Vector2i.ZERO
var player_facing: int = 0  # Cardinal direction
var music_player: AudioStreamPlayer
var music_volume: float = 0.8  # Default 80%
var sfx_volume: float = 0.7    # Default 70%

func _ready():
	# Set up audio
	_setup_audio()
	load_settings()

# Save settings to file
func save_settings() -> bool:
	var save_data = {
		"music_volume": music_volume,
		"sfx_volume": sfx_volume
	}
	
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		printerr("Failed to open settings file for writing: ", FileAccess.get_open_error())
		return false
		
	var json_string = JSON.stringify(save_data)
	save_file.store_line(json_string)
	return true

# Set up audio system
func _setup_audio():
	# Create audio stream player for background music
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	# Load the background music
	var music = load("res://assets/audio/music/background.wav")
	music_player.stream = music
	music_player.bus = "Music"  # Will use default bus if Music bus doesn't exist
	music_player.volume_db = linear_to_db(music_volume)
	music_player.finished.connect(_on_music_finished)
	
	# Set up audio bus volumes
	_set_music_volume(music_volume)
	_set_sfx_volume(sfx_volume)
	
	# Start playing the music
	play_music()

# Music player control
func play_music():
	if music_player and not music_player.playing:
		music_player.play()

func stop_music():
	if music_player and music_player.playing:
		music_player.stop()

# Automatically replay music when finished
func _on_music_finished():
	play_music()

# Volume control functions
func _set_music_volume(value: float):
	music_volume = value
	if music_player:
		music_player.volume_db = linear_to_db(value)
	
	# Also set the bus volume if available
	if AudioServer.bus_count > MUSIC_BUS_IDX:
		AudioServer.set_bus_volume_db(MUSIC_BUS_IDX, linear_to_db(value))

func _set_sfx_volume(value: float):
	sfx_volume = value
	# Set the SFX bus volume if available
	if AudioServer.bus_count > SFX_BUS_IDX:
		AudioServer.set_bus_volume_db(SFX_BUS_IDX, linear_to_db(value))

# Public volume control API
func set_music_volume(value: float):
	_set_music_volume(value)
	save_settings()

func set_sfx_volume(value: float):
	_set_sfx_volume(value)
	save_settings()

# Load settings from file
func load_settings():
	if FileAccess.file_exists(SAVE_PATH):
		var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if save_file == null:
			printerr("Failed to open settings file for reading: ", FileAccess.get_open_error())
			return
			
		var json_string = save_file.get_line()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.get_data()
			_set_music_volume(save_data["music_volume"])
			_set_sfx_volume(save_data["sfx_volume"])

# Helper function to convert linear volume to decibels
func linear_to_db(linear: float) -> float:
	if linear <= 0:
		return -80.0  # Silence
	return 20.0 * log(linear) / log(10.0)

# Game management functions
func change_level(level_name: String) -> void:
	current_level = level_name
	get_tree().change_scene_to_file("res://scenes/levels/" + level_name + ".tscn")

func game_over() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")

func add_item_to_inventory(item: Variant) -> void:
	player_inventory.append(item)

func update_score(points: int) -> void:
	player_score += points
	emit_signal("score_changed", player_score)

func update_health(new_health: int) -> void:
	player_health = new_health
	emit_signal("health_changed", player_health)
	
	if player_health <= 0:
		game_over()
