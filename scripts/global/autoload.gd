extends Node

# Make the Game Manager a singleton (autoload)
# To use this, add it to your project's autoload
# Project Settings > Autoload > Add this script as "GameManager"

const SAVE_PATH = "user://save_game.dat"

signal score_changed(new_score)
signal health_changed(new_health)

var current_level: String = "level_1"
var player_health: int = 100
var player_score: int = 0
var player_inventory = []
var player_max_health: int = 100

func _ready():
	load_game()

# Save game state to file
func save_game():
	var save_data = {
		"current_level": current_level,
		"player_health": player_health,
		"player_score": player_score,
		"player_max_health": player_max_health,
		"player_inventory": player_inventory
	}
	
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var json_string = JSON.stringify(save_data)
	save_file.store_line(json_string)

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