extends Node

const ETAG_STORE_PATH := "user://content_cache/.etags.json"

var _etag_store: Dictionary = {}

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
	
func download(url: String, dest_path: String) -> bool:
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
	
	return true
