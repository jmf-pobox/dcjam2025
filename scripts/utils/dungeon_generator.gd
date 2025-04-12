extends Node

class_name DungeonGenerator

# Room dimensions (in grid cells)
const ROOM_WIDTH = 2
const ROOM_HEIGHT = 2
const CELL_SIZE = 64

# Tilemap tile indices
enum TileType {
	FLOOR = 0,
	WALL = 1,
	WALL_TOP = 2,
	CEILING = 3
}

# Generate a simple 2x2 room with walls, floor and ceiling
static func generate_room(tilemap: TileMap):
	var floor_layer = 0
	var wall_layer = 1
	var ceiling_layer = 2
	
	# Clear the tilemap
	tilemap.clear()
	
	# Generate floor (2x2 grid)
	for x in range(ROOM_WIDTH):
		for y in range(ROOM_HEIGHT):
			tilemap.set_cell(floor_layer, Vector2i(x, y), 0, Vector2i(0, 0), TileType.FLOOR)
	
	# Generate walls (surrounding the floor)
	# Left wall
	for y in range(ROOM_HEIGHT):
		tilemap.set_cell(wall_layer, Vector2i(-1, y), 0, Vector2i(0, 0), TileType.WALL)
	
	# Right wall
	for y in range(ROOM_HEIGHT):
		tilemap.set_cell(wall_layer, Vector2i(ROOM_WIDTH, y), 0, Vector2i(0, 0), TileType.WALL)
	
	# Top wall
	for x in range(ROOM_WIDTH):
		tilemap.set_cell(wall_layer, Vector2i(x, -1), 0, Vector2i(0, 0), TileType.WALL_TOP)
	
	# Bottom wall
	for x in range(ROOM_WIDTH):
		tilemap.set_cell(wall_layer, Vector2i(x, ROOM_HEIGHT), 0, Vector2i(0, 0), TileType.WALL)
	
	# Generate ceiling
	for x in range(ROOM_WIDTH):
		for y in range(ROOM_HEIGHT):
			tilemap.set_cell(ceiling_layer, Vector2i(x, y), 0, Vector2i(0, 0), TileType.CEILING)
	
	# Convert grid coordinates to world coordinates
	return {
		"width": ROOM_WIDTH * CELL_SIZE,
		"height": ROOM_HEIGHT * CELL_SIZE,
		"center": Vector2(ROOM_WIDTH * CELL_SIZE / 2, ROOM_HEIGHT * CELL_SIZE / 2)
	}