extends Node2D
class_name ItemLayer

const EMPTY_RECT := Rect2i(0, 0, 0, 0)
const ITEM = preload("uid://c840kvw5f81r")

@onready var _icon_size: Vector2i = ProjectSettings.get_setting("mirage/items/icon_size", Vector2i(32, 32))

var _items: Dictionary[int, Item] = {}

func _ready() -> void:
	SignalBus.map_init.connect(func(data: Dictionary) -> void:
		_clear_items()
		var items: Array = data.get("items", [])
		if items and items.size() > 0:
			_load_initial_items(items))
		
	SignalBus.item_added.connect(_item_added)
	SignalBus.item_removed.connect(_item_removed)

func _load_initial_items(items: Array) -> void:
	for item in items:
		if item is Dictionary:
			_item_added(item)

func _clear_items():
	for item in _items.values():
		item.queue_free()
	_items.clear()

func _item_added(payload: Dictionary) -> void:
	var instance_id: int = payload.get("instance_id", -1)
	if instance_id == -1:
		return
	
	var sprite_index: int = payload.get("sprite_index", -1)
	if sprite_index == -1:
		return
	
	var texture_path: String = payload.get("texture", "")
	var texture: Texture2D = await TextureLoader.get_texture(texture_path)
	if texture == null:
		return
	
	var region_rect := _get_region_rect(texture, sprite_index)
	if region_rect == EMPTY_RECT:
		return
		
	var x: int = payload.get("x", -1)
	var y: int = payload.get("y", -1)
	if x == -1 or y == -1:
		return
	
	var item: Item = ITEM.instantiate()
	
	item.texture = texture
	item.region_enabled = true
	item.region_rect = region_rect
	item.position = Vector2(x * _icon_size.x, y * _icon_size.y)
	
	_items[instance_id] = item
	
	add_child(item)

func _item_removed(payload: Dictionary) -> void:
	var instance_id: int = payload.get("instance_id", -1)
	if not _items.has(instance_id):
		return
	
	_items[instance_id].queue_free()
	_items.erase(instance_id)

func _get_region_rect(texture: Texture2D, sprite_index: int) -> Rect2i:
	var width: int = texture.get_width() / _icon_size.x
	var height: int = texture.get_height() / _icon_size.y
	
	var max_sprite_index := width * height
	if sprite_index > max_sprite_index:
		return EMPTY_RECT
	
	var rx := (sprite_index % width) * _icon_size.x
	var ry := (sprite_index / width) * _icon_size.y
	
	return Rect2i(rx, ry, _icon_size.x, _icon_size.y)
