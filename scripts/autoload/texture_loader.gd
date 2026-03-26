extends Node

@onready var _cache_textures: bool = ProjectSettings.get_setting("mirage/cache/cache_textures", true)
@onready var _cache_ttl: float = ProjectSettings.get_setting("mirage/cache/time_to_live", 300.0)

var _textures: Dictionary[String, Texture2D] = {}
var _texure_time: Dictionary[String, float] = {}

func get_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	
	if _cache_textures and _textures.has(path):
		return _get_texture_from_cache(path)
	
	var local_path := ContentDownloader.get_local_path(path)
	
	var ok: bool = await ContentDownloader.download(path, local_path)
	if not ok:
		push_error("[Item] failed to download items texture '%s'" % path)
		return null
	
	return _load_texture(path)

func _get_texture_from_cache(path: String) -> Texture2D:
	var age: float = Time.get_unix_time_from_system() - _texure_time[path]
	if age < _cache_ttl:
		return _textures[path]
	
	return _load_texture(path)

func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	
	var local_path := ContentDownloader.get_local_path(path)
	
	var err := image.load(local_path)
	if err != OK:
		push_error("[Item] failed to load items texture '%s'" % path)
		return null
	
	var texture := ImageTexture.create_from_image(image)
	
	_textures[path] = texture
	_texure_time[path] = Time.get_unix_time_from_system()
	
	return texture
