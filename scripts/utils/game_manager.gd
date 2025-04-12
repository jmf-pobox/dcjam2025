extends Node

# Singleton for managing game state

const SAVE_PATH = "user://save_game.dat"

var current_level: String = "level_1"
var player_health: int = 100
var player_score: int = 0
var player_inventory = []

func _ready():
	load_game()

# Save game state to file
func save_game():
	var save_data = {
		"current_level": current_level,
		"player_health": player_health,
		"player_score": player_score,
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
