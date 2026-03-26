extends VBoxContainer
class_name PlayerInventory

const EMPTY_RECT := Rect2i(0, 0, 0, 0)
const PLAYER_INVENTORY_SLOT = preload("uid://83e2sy1dg1nj")

@onready var _icon_size: Vector2i = ProjectSettings.get_setting("mirage/items/icon_size", Vector2i(32, 32))
@onready var _container: HFlowContainer = %Container

var _inventory_slots: Dictionary[int, PlayerInventorySlot] = {}

func _ready() -> void:
	SignalBus.player_inventory.connect(_player_inventory)
	SignalBus.player_inventory_update.connect(_player_inventory_update)

func _player_inventory(payload: Dictionary) -> void:
	var inventory_size: int = payload.get("size", 0)
	
	_resize_inventory(inventory_size)
	
	var slots = payload.get("slots")
	if slots is Dictionary:
		for slot_index in slots:
			var slot_data = slots[slot_index]
			if slot_data is Dictionary:
				await _update_slot(int(slot_index), slot_data)

func _player_inventory_update(payload: Dictionary) -> void:
	var slot_index: int = payload.get("slot", -1)
	if slot_index == -1:
		return
	
	var slot_data = payload.get("slot_data")
	if slot_data is Dictionary:
		await _update_slot(slot_index, slot_data)

func _resize_inventory(inventory_size: int) -> void:
	var current_inventory_size := _inventory_slots.size()
	if current_inventory_size == inventory_size:
		return
	
	if inventory_size < current_inventory_size:
		for slot_index in range(inventory_size, current_inventory_size):
			_inventory_slots[slot_index].queue_free()
			_inventory_slots.erase(slot_index)
	
	if inventory_size > current_inventory_size:
		for slot_index in range(current_inventory_size, inventory_size):
			var slot: PlayerInventorySlot = PLAYER_INVENTORY_SLOT.instantiate()
			_inventory_slots[slot_index] = slot
			_container.add_child(slot)

func _update_slot(slot_index: int, slot_data: Dictionary) -> void:
	if slot_index < 0 or slot_index >= _inventory_slots.size():
		return
	
	var slot = _inventory_slots[slot_index]
	
	var sprite_index: int = slot_data.get("sprite_index", -1)
	if sprite_index == -1:
		return
	
	var texture_path: String = slot_data.get("texture", "")
	var texture: Texture2D = await TextureLoader.get_texture(texture_path)
	if texture == null:
		return
	
	var region_rect := _get_region_rect(texture, sprite_index)
	if region_rect == EMPTY_RECT:
		return
	
	slot.texture = texture
	slot.region_rect = region_rect
	slot.quantity = slot_data.get("quantity", 0)
	slot.item_name = slot_data.get("name", "")

func _get_region_rect(texture: Texture2D, sprite_index: int) -> Rect2i:
	var width: int = texture.get_width() / _icon_size.x
	var height: int = texture.get_height() / _icon_size.y
	
	var max_sprite_index := width * height
	if sprite_index > max_sprite_index:
		return EMPTY_RECT
	
	var rx := (sprite_index % width) * _icon_size.x
	var ry := (sprite_index / width) * _icon_size.y
	
	return Rect2i(rx, ry, _icon_size.x, _icon_size.y)
