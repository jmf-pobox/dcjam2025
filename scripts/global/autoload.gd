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
var player_position: Vector3 = Vector3.ZERO
var player_grid_position: Vector2i = Vector2i.ZERO
var player_facing: int = 0  # Cardinal direction
var music_player: AudioStreamPlayer
var music_volume: float = 0.8  # Default 80%
var sfx_volume: float = 0.7    # Default 70%

# Store the previous scene when entering mini-game
var previous_scene: String = ""
var is_minigame_active: bool = false

# Dungeon state
var dungeon_data: Dictionary = {}
var active_entities: Array = []

func _ready():
	# Set up audio
	_setup_audio()
	load_game()

func _input(event):
	if event.is_action_pressed("play_minigame") and !is_minigame_active:
		print("Mini-game key pressed, current scene: ", get_tree().current_scene.scene_file_path)
		# Store current scene path before switching to mini-game
		previous_scene = get_tree().current_scene.scene_file_path
		is_minigame_active = true
		# Get the current tree
		var tree = get_tree()
		# Pause the current scene
		tree.paused = true
		# Switch to chase mini-game
		var result = get_tree().change_scene_to_file("res://scenes/minigames/chase/chase_game.tscn")
		if result != OK:
			print("Failed to switch to mini-game scene. Error code: ", result)
		# Unpause after changing scene
		tree.paused = false
	elif event.is_action_pressed("pause") and is_minigame_active:
		print("Returning to previous scene: ", previous_scene)
		# If we're in the chase game and press pause, return to previous scene
		is_minigame_active = false
		var tree = get_tree()
		tree.paused = true
		if previous_scene != "":
			var result = get_tree().change_scene_to_file(previous_scene)
			if result != OK:
				print("Failed to return to previous scene. Error code: ", result)
		else:
			# Fallback to main dungeon if no previous scene
			var result = get_tree().change_scene_to_file("res://scenes/levels/fp_dungeon.tscn")
			if result != OK:
				print("Failed to switch to fallback scene. Error code: ", result)
		tree.paused = false

# Save game state to file
func save_game() -> bool:
	var save_data = {
		"current_level": current_level,
		"player_health": player_health,
		"player_score": player_score,
		"player_max_health": player_max_health,
		"player_inventory": player_inventory,
		"player_position": {
			"x": player_position.x,
			"y": player_position.y,
			"z": player_position.z
		},
		"player_grid_position": {
			"x": player_grid_position.x,
			"y": player_grid_position.y
		},
		"player_facing": player_facing,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"dungeon_data": dungeon_data,
		"active_entities": active_entities
	}
	
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		printerr("Failed to open save file for writing: ", FileAccess.get_open_error())
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
func set_music_volume(percent: float):
	# Convert from percentage (0-100) to linear scale (0-1)
	var volume = percent / 100.0
	_set_music_volume(volume)

func set_sfx_volume(percent: float):
	# Convert from percentage (0-100) to linear scale (0-1)
	var volume = percent / 100.0
	_set_sfx_volume(volume)

# Load game state from file
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found, starting new game")
		return false
		
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		printerr("Failed to open save file for reading: ", FileAccess.get_open_error())
		return false
		
	var json_string = save_file.get_line()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		printerr("Failed to parse save file: ", json.get_error_message())
		return false
		
	var save_data = json.get_data()
	
	# Load basic player stats
	current_level = save_data.get("current_level", "level_1")
	player_health = save_data.get("player_health", 100)
	player_score = save_data.get("player_score", 0)
	player_max_health = save_data.get("player_max_health", 100)
	player_inventory = save_data.get("player_inventory", [])
	
	# Load player position
	var pos_data = save_data.get("player_position", {})
	player_position = Vector3(
		pos_data.get("x", 0.0),
		pos_data.get("y", 0.0),
		pos_data.get("z", 0.0)
	)
	
	# Load player grid position
	var grid_pos_data = save_data.get("player_grid_position", {})
	player_grid_position = Vector2i(
		grid_pos_data.get("x", 0),
		grid_pos_data.get("y", 0)
	)
	
	player_facing = save_data.get("player_facing", 0)
	
	# Load audio settings
	if save_data.has("music_volume"):
		set_music_volume(save_data["music_volume"] * 100)
	if save_data.has("sfx_volume"):
		set_sfx_volume(save_data["sfx_volume"] * 100)
	
	# Load dungeon state
	dungeon_data = save_data.get("dungeon_data", {})
	active_entities = save_data.get("active_entities", [])
	
	return true

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

# Update player position for saving
func update_player_position(pos: Vector3, grid_pos: Vector2i, facing: int) -> void:
	player_position = pos
	player_grid_position = grid_pos
	player_facing = facing

# Update dungeon state for saving
func update_dungeon_state(data: Dictionary, entities: Array) -> void:
	dungeon_data = data
	active_entities = entities

# Helper function to convert linear volume to decibels
func linear_to_db(linear: float) -> float:
	if linear <= 0:
		return -80.0  # Silence
	return 20.0 * log(linear) / log(10.0)