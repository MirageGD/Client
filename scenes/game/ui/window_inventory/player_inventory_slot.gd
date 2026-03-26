extends PanelContainer
class_name PlayerInventorySlot

@onready var _texture_rect: TextureRect = %Texture
@onready var _quantity_label: Label = %Quantity

var texture: Texture2D: set = set_texture, get = get_texture
var region_rect: Rect2i: set = set_region_rect, get = get_region_rect
var quantity := 0: set = set_quantity
var item_name: String: get = get_item_name, set = set_item_name

var _atlas_texture := AtlasTexture.new()

func _ready() -> void:
	_texture_rect.texture = _atlas_texture

func set_texture(new_texture: Texture2D) -> void:
	_atlas_texture.atlas = new_texture

func get_texture() -> Texture2D:
	return _atlas_texture.atlas

func set_region_rect(new_region_rect: Rect2i) -> void:
	_atlas_texture.region = new_region_rect

func get_region_rect() -> Rect2i:
	return _atlas_texture.region

func set_quantity(new_quantity: int) -> void:
	quantity = new_quantity
	
	_quantity_label.text = str(new_quantity)
	_quantity_label.visible = new_quantity > 0

func set_item_name(new_item_name: String) -> void:
	tooltip_text = new_item_name

func get_item_name() -> String:
	return tooltip_text
