extends Node

# Make the Game Manager a singleton (autoload)
# To use this, add it to your project's autoload
# Project Settings > Autoload > Add this script as "GameManager"

const SAVE_PATH = "user://save_game.dat"
const MUSIC_BUS_IDX = 1
const SFX_BUS_IDX = 2

signal score_changed(new_score)
signal health_changed(new_health)

var current_level: String = "level_1"
var player_health: int = 100
var player_score: int = 0
var player_inventory = []
var player_max_health: int = 100
var music_player: AudioStreamPlayer
var music_volume: float = 0.8  # Default 80%
var sfx_volume: float = 0.7    # Default 70%

func _ready():
	# Set up audio
	_setup_audio()
	load_game()

# Save game state to file
func save_game():
	var save_data = {
		"current_level": current_level,
		"player_health": player_health,
		"player_score": player_score,
		"player_max_health": player_max_health,
		"player_inventory": player_inventory,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume
	}
	
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var json_string = JSON.stringify(save_data)
	save_file.store_line(json_string)

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
func set_music_volume(percent: float):
	# Convert from percentage (0-100) to linear scale (0-1)
	var volume = percent / 100.0
	_set_music_volume(volume)

func set_sfx_volume(percent: float):
	# Convert from percentage (0-100) to linear scale (0-1)
	var volume = percent / 100.0
	_set_sfx_volume(volume)

# Load game state from file
func load_game():
	if FileAccess.file_exists(SAVE_PATH):
		var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var json_string = save_file.get_line()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.get_data()
			
			current_level = save_data["current_level"]
			player_health = save_data["player_health"]
			player_score = save_data["player_score"]
			player_max_health = save_data["player_max_health"]
			player_inventory = save_data["player_inventory"]
			
			# Load audio settings if available
			if save_data.has("music_volume"):
				set_music_volume(save_data["music_volume"] * 100)
			if save_data.has("sfx_volume"):
				set_sfx_volume(save_data["sfx_volume"] * 100)

# Change to a new level
func change_level(level_name):
	current_level = level_name
	get_tree().change_scene_to_file("res://scenes/levels/" + level_name + ".tscn")

# Game over function
func game_over():
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")

# Add item to player inventory
func add_item_to_inventory(item):
	player_inventory.append(item)

# Update player score
func update_score(points):
	player_score += points
	emit_signal("score_changed", player_score)

# Update player health
func update_health(new_health):
	player_health = new_health
	emit_signal("health_changed", player_health)
	
	if player_health <= 0:
		game_over()