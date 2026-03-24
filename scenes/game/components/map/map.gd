extends Node2D
class_name Map

const CONTENT_URL := "http://127.0.0.1:5000/content/"
const CONTENT_CACHE_DIR := "user://content_cache/"

enum {
	TILE_PASSABLE = 0,
	TILE_BLOCKED = 1
}

signal map_loaded

@onready var _layers: Node2D = %Layers

var _tileset_cache: Dictionary = {}
var _tiles: Array[int]
var _objects: Array[MapObject]

var map_width := 0
var map_height := 0
var tile_size := Vector2i(32, 32)

func clear() -> void:
	_tiles.clear()
	_objects.clear()

func load_map(map_name: String) -> void:
	clear()
	
	var local_path := CONTENT_CACHE_DIR.path_join(map_name)
	var ok := await ContentDownloader.download(CONTENT_URL + map_name, local_path)
	if not ok:
		push_error("[Map] failed to download map '%s'" % map_name)
		return
	
	var map_data_json := FileAccess.get_file_as_string(local_path)
	var map_data: Variant = JSON.parse_string(map_data_json)
	if not map_data is Dictionary:
		push_error("[Map Loader] invalid JSON in '%s'" % local_path)
		return
	
	await _build_map(map_name.get_base_dir(), map_data)
	
	map_loaded.emit()

func _build_map(map_path: String, map_data: Dictionary) -> void:
	var gid_table := await _resolve_tilesets(map_path, map_data)
	if gid_table.is_empty():
		push_error("[Map Loader] no tilesets resolved")
		return
	
	map_width = map_data.get("width", 0)
	map_height = map_data.get("height", 0)
	
	_tiles.resize(map_width * map_height)
	
	var tile_width = map_data.get("tilewidth", 32)
	var tile_height = map_data.get("tileheight", 32)
	
	tile_size = Vector2i(tile_width, tile_height)
	
	var tile_set = _build_tile_set(gid_table)
	var layer_z_index := 0
	
	for layer_data in map_data.get("layers", []):
		match layer_data.get("type", ""):
			"tilelayer":
				var layer_name: String = layer_data.get("name", "")
				if layer_name.begins_with("@"):
					_build_meta(layer_data, gid_table)
					continue
				
				var tile_map_layer := _build_tile_layer(layer_data, tile_set, gid_table)
				tile_map_layer.z_index = layer_z_index
				_layers.add_child(tile_map_layer)
			
			"objectgroup":
				var layer_name: String = layer_data.get("name", "")
				if layer_name.to_lower() == "entities":
					layer_z_index = 50
				_load_objects(layer_data)

func _build_meta(layer_data: Dictionary, gid_table: Array[Dictionary]) -> void:
	var layer_gids: Array = layer_data.get("data", [])
	
	for i in layer_gids.size():
		var raw_gid: int = layer_gids[i]
		if raw_gid == 0:
			continue
		
		var gid := raw_gid & 0x0FFFFFFF
		
		var local_gid = _global_to_local_gid(gid, gid_table)
		if local_gid == 0:
			continue
		
		_tiles[i] = local_gid

func _load_objects(layer_data: Dictionary) -> void:
	var objects: Array = layer_data.get("objects", [])
	for object in objects:
		var type: String = object.get("type", "")
		if type.is_empty():
			continue
		
		var x = object.get("x", 0) / tile_size.x
		var y = object.get("y", 0) / tile_size.y
		var width = object.get("width", 0) / tile_size.x
		var height = object.get("height", 0) / tile_size.y
		
		var map_object := MapObject.new()
		
		map_object.type = type.to_lower()
		map_object.region_rect = Rect2i(x, y, width, height)
		
		_objects.append(map_object)

func _build_tile_set(gid_table: Array[Dictionary]) -> TileSet:
	var tileset := TileSet.new()
	
	tileset.tile_size = tile_size
	
	for entry in gid_table:
		tileset.add_source(entry.tileset_source, entry.source_id)
	
	return tileset

func _build_tile_layer(layer_data: Dictionary, tile_set: TileSet, gid_table: Array[Dictionary]) -> TileMapLayer:
	var layer := TileMapLayer.new()
	
	layer.name = layer_data.get("name", "Layer")
	layer.visible = layer_data.get("visible", true)
	layer.tile_set = tile_set
	
	var layer_width: int = layer_data.get("width", 0)
	var layer_gids: Array = layer_data.get("data", [])
	
	for i in layer_gids.size():
		var raw_gid: int = layer_gids[i]
		if raw_gid == 0:
			continue
		
		var gid := raw_gid & 0x0FFFFFFF
		
		var cell = _gid_to_cell(gid, gid_table)
		if cell.is_empty():
			continue
		
		@warning_ignore("integer_division")
		var map_coord := Vector2i(i % layer_width, i / layer_width)
		
		layer.set_cell(map_coord, cell.source_id, cell.atlas_coord)
	
	return layer

func _global_to_local_gid(gid: int, gid_table: Array[Dictionary]) -> int:
	for i in range(gid_table.size() - 1, -1, -1):
		var entry := gid_table[i]
		
		if gid >= entry.firstgid:
			var local_id: int = gid - entry.firstgid
			
			return 1 + local_id
	
	return 0

func _gid_to_cell(gid: int, gid_table: Array[Dictionary]) -> Dictionary:
	for i in range(gid_table.size() - 1, -1, -1):
		var entry := gid_table[i]
		
		if gid >= entry.firstgid:
			var local_id: int = gid - entry.firstgid
			var columns: int = entry.columns
			
			@warning_ignore("integer_division")
			return {
				"source_id": entry.source_id,
				"atlas_coord": Vector2i(local_id % columns, local_id / columns)
			}
	
	return {}

func _resolve_tilesets(map_path: String, map_data: Dictionary) -> Array[Dictionary]:
	var tilesets: Array[Dictionary] = []
	var tileset_source_id := 0
	
	for tileset_info in map_data.get("tilesets", []):
		var firstgid: int = tileset_info.get("firstgid", 1)
		var tileset_source: String = tileset_info.get("source", "")
		if tileset_source.is_empty():
			push_warning("[Map Loader] embedded tilesets not supported, skipping...")
			continue
		
		var tileset = await _get_tileset(map_path, tileset_source)
		if tileset == null:
			push_warning("[Map Loader] could not load tileset '%s', skipping..." % tileset_source)
			continue
		
		tilesets.append({
			"firstgid": firstgid,
			"columns": tileset.columns,
			"source_id": tileset_source_id,
			"tileset_source": tileset.atlas_source
		})
		
		tileset_source_id += 1
	
	return tilesets

func _get_tileset(map_path: String, tileset_source: String) -> Variant:
	if _tileset_cache.has(tileset_source):
		return _tileset_cache[tileset_source]
	
	var tileset_path := map_path.path_join(tileset_source).simplify_path()
	var tileset_local_path := CONTENT_CACHE_DIR.path_join(tileset_path)
	var ok := await ContentDownloader.download(CONTENT_URL + tileset_path, tileset_local_path)
	if not ok:
		return null
	
	var tileset_data_json := FileAccess.get_file_as_string(tileset_local_path)
	var tileset_data = JSON.parse_string(tileset_data_json)
	
	var image_name: String = tileset_data.get("image", "")
	var image_path = tileset_path.get_base_dir().path_join(image_name).simplify_path()
	var image_local_path = CONTENT_CACHE_DIR.path_join(image_path)
	
	ok = await ContentDownloader.download(CONTENT_URL + image_path, image_local_path)
	if not ok:
		return null
	
	var texture := _load_texture(image_local_path)
	if texture == null:
		return null
		
	var tile_w: int = tileset_data.get("tilewidth", 32)
	var tile_h: int = tileset_data.get("tileheight", 32)
	var columns: int = tileset_data.get("columns", 1)
	var tile_count: int = tileset_data.get("tilecount", 0)
	var margin: int = tileset_data.get("margin", 0)
	var spacing: int = tileset_data.get("spacing", 0)
	
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(tile_w, tile_h)
	source.margins = Vector2i(margin, margin)
	source.separation = Vector2i(spacing, spacing)
	
	for i in tile_count:
		@warning_ignore("integer_division")
		var coord := Vector2i(i % columns, i / columns)
		source.create_tile(coord)
	
	var entry := {
		"atlas_source": source,
		"columns": columns
	}
	
	_tileset_cache[tileset_source] = entry
	
	return entry

func _load_texture(path: String) -> ImageTexture:
	var image = Image.new()
	
	var err := image.load(path)
	if err != OK:
		push_error("[Map Loader] failed to load image '%s'" % path)
		return null
	
	return ImageTexture.create_from_image(image)

func in_bounds(coords: Vector2i) -> bool:
	return coords.x >= 0 and coords.y >= 0 and coords.x < map_width and coords.y < map_height

func get_tile_type(coords: Vector2i) -> int:
	return _tiles[coords.y * map_width + coords.x] if in_bounds(coords) else TILE_BLOCKED

func is_passable(coords: Vector2i) -> bool:
	return get_tile_type(coords) != TILE_BLOCKED

func has_object_of_type_at(type: String, tile_coords: Vector2i) -> bool:
	for object in _objects:
		if not object.region_rect.has_point(tile_coords):
			continue
		
		if object.type == type:
			return true
	
	return false
