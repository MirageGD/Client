extends Node

const CONTENT_CACHE_DIR := "user://content_cache/"
const ETAG_STORE_PATH := "user://content_cache/.etags.json"

@onready var _cache_content: bool = ProjectSettings.get_setting("mirage/cache/cache_content", true)
@onready var _cache_ttl: float = ProjectSettings.get_setting("mirage/cache/time_to_live", 300.0)
@onready var _base_url: String = ProjectSettings.get_setting("mirage/server/address") + "content/"

var _etag_store: Dictionary = {}
var _cache: Dictionary = {}

func _ready() -> void:
	_load_etag_store()

func _load_etag_store() -> void:
	if not FileAccess.file_exists(ETAG_STORE_PATH):
		return
	
	var etags_json = FileAccess.get_file_as_string(ETAG_STORE_PATH)
	var etags = JSON.parse_string(etags_json)
	
	if etags is Dictionary:
		_etag_store = etags

func _save_etag_store() -> void:
	var file := FileAccess.open(ETAG_STORE_PATH, FileAccess.WRITE)
	if not file:
		return
		
	var etags := JSON.stringify(_etag_store)
	
	file.store_string(etags)
	file.close()

func get_local_path(source_path: String) -> String:
	return CONTENT_CACHE_DIR.path_join(source_path)

func download(source_path: String, dest_path: String) -> bool:
	var url := _base_url + source_path
	
	if _cache_content and _cache.has(url):
		var age: float = Time.get_unix_time_from_system() - _cache[url]
		if age < _cache_ttl:
			return true
	
	DirAccess.make_dir_recursive_absolute(dest_path.get_base_dir())
	
	var http := HTTPRequest.new()
	
	add_child(http)
	
	var headers: PackedStringArray = []
	if _etag_store.has(url):
		headers.append("If-None-Match: " + _etag_store[url])
	
	http.request(url, headers)
	var result = await http.request_completed
	http.queue_free()
	
	if result[0] != OK:
		push_error("[Map Loader] HTTP request failed for '%s' (error=%d)" % [url, result[0]])
		return false
	
	var status_code: int = result[1]
	if status_code == 304:
		_cache[url] = Time.get_unix_time_from_system()
		return true
	
	if status_code != 200:
		push_error("[Map Loader] HTTP request failed for '%s' (status_code=%d)" % [url, status_code])
		return false
	
	var file := FileAccess.open(dest_path, FileAccess.WRITE)
	if file == null:
		push_error("[Map Loader] unable to write to '%s'" % dest_path)
		return false
	
	file.store_buffer(result[3])
	file.close()
	
	headers = result[2]
	for header in headers:
		if header.to_lower().begins_with("etag:"):
			_etag_store[url] = header.substr(5).strip_edges()
			_save_etag_store()
			break
	
	_cache[url] = Time.get_unix_time_from_system()
	return true
