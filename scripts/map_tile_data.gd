extends Resource
class_name MapTileData

var width: int
var height: int

var _tiles: Array[int]

enum {
	TILE_PASSABLE = 0,
	TILE_BLOCKED = 1
}

func _init(map_width: int, map_height: int, tiles: Array[int]) -> void:
	width = map_width
	height = map_height
	
	_tiles = tiles
	
	var expected_tiles := map_width * map_height
	var actual_tiles := len(tiles)
	
	if actual_tiles != expected_tiles:
		push_error("[Map Tile Data] mismatch tile count %d where %d expected" % [actual_tiles, expected_tiles])

func in_bounds(coords: Vector2i) -> bool:
	return coords.x >= 0 and coords.y >= 0 and coords.x < width and coords.y < height

func get_tile_type(coords: Vector2i) -> int:
	return _tiles[coords.y * height + coords.x] if in_bounds(coords) else TILE_BLOCKED

func is_passable(coords: Vector2i) -> bool:
	return get_tile_type(coords) != TILE_BLOCKED
