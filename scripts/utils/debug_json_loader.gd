extends Node

# Simple script to load and dump the contents of a JSON file
# Attach this to any node and it will print the contents when the scene loads

@export var json_file_path: String = "res://resources/dungeons/level_1.json"

func _ready():
	load_and_print_json()

func load_and_print_json():
	print("====== BEGIN JSON FILE DEBUG ======")
	print("Attempting to load: " + json_file_path)
	
	if ResourceLoader.exists(json_file_path):
		print("File exists in resources system")
	else:
		printerr("ERROR: File does not exist in resources system")
		
	if FileAccess.file_exists(json_file_path):
		var file = FileAccess.open(json_file_path, FileAccess.READ)
		var json_text = file.get_as_text()
		
		print("File content length: " + str(json_text.length()))
		print("File preview: " + json_text.substr(0, 100) + "...")
		
		var json = JSON.new()
		var error = json.parse(json_text)
		
		if error == OK:
			var data = json.get_data()
			print("Successfully parsed JSON")
			print("Dungeon name: " + data.get("dungeon_name", "Unknown"))
			print("Number of rooms: " + str(data.get("rooms", []).size()))
			print("Number of corridors: " + str(data.get("corridors", []).size()))
			
			# Print room IDs
			print("Room IDs:")
			for room in data.get("rooms", []):
				print("  - " + room.get("id", "unknown"))
		else:
			printerr("JSON parse error: " + str(error) + " at line " + str(json.get_error_line()))
	else:
		printerr("ERROR: File cannot be opened with FileAccess")
		
	print("====== END JSON FILE DEBUG ======")