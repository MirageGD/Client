extends Node2D

const ENTITY = preload("uid://bpot3paunt5r")

@onready var _map: Map = %Map
@onready var _gui: CanvasLayer = $GUI

var _player_entity_id: int = -1
var _entities: Dictionary[int, Entity]

func is_tile_occupied(coords: Vector2i) -> bool:
	for entity in _entities.values():
		if entity.current_tile == coords:
			return true
	return false

func _ready() -> void:
	SignalBus.map_init.connect(_map_init)
	
	SignalBus.entity_joined.connect(_entity_joined)
	SignalBus.entity_left.connect(_entity_left)
	SignalBus.entity_moved.connect(_entity_moved)
	SignalBus.entity_attack.connect(_entity_attack)
	SignalBus.entity_hurt.connect(_entity_hurt)
	SignalBus.entity_leveled_up.connect(_entity_leveled_up)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var focus_owner := get_viewport().gui_get_focus_owner()
		if focus_owner != null:
			focus_owner.release_focus()

func _map_init(payload: Dictionary) -> void:
	for entity_id in _entities:
		_entities[entity_id].queue_free()
	
	_entities.clear()
	_player_entity_id = payload.get("player_entity_id", -1)
	
	var map_path: String = payload.get("map_path", "")
	if map_path.is_empty():
		return
	
	await _map.load_map(map_path)
	
	for entity_id in _entities:
		_entities[entity_id].map = _map
		_entities[entity_id].tile_checker = Callable(self, "is_tile_occupied")
	
	var entities = payload.get("entities", [])
	if entities is Array:
		for entity in entities:
			_entity_joined(entity)

func _entity_joined(payload: Dictionary) -> void:
	var entity_id: int = payload.get("entity_id", -1)
	if entity_id == -1:
		return
	
	var x: int = payload.get("x", 0)
	var y: int = payload.get("y", 0)
	
	var entity: Entity = ENTITY.instantiate()
	
	entity.position = Vector2(x * 32, y * 32)
	entity.entity_name = payload.get("name", "")
	entity.current_direction = payload.get("direction", "down")
	entity.current_tile = Vector2i(x, y)
	entity.map = _map
	entity.tile_checker = Callable(self, "is_tile_occupied")
	entity.sprite_path = payload.get("sprite", "")
	
	if entity_id == _player_entity_id:
		entity.is_local_player = true
	
	_entities[entity_id] = entity
	
	add_child(entity)

func _entity_left(payload: Dictionary) -> void:
	var entity_id: int = payload.get("entity_id", -1)
	if entity_id == -1:
		return
	
	if _entities.has(entity_id):
		var entity := _entities[entity_id]
		_entities.erase(entity_id)
		entity.queue_free()

func _entity_moved(payload: Dictionary) -> void:
	var entity_id: int = payload.get("entity_id", -1)
	if entity_id == -1 || entity_id == _player_entity_id:
		return
	
	var source_x: int = payload.get("source_x", 0)
	var source_y: int = payload.get("source_y", 0)
	
	var direction: String = payload.get("direction", "")
	if direction.is_empty():
		return
	
	if _entities.has(entity_id):
		_entities[entity_id].move(Vector2i(source_x, source_y), direction)

func _entity_direction(payload: Dictionary) -> void:
	var entity_id: int = payload.get("entity_id", -1)
	if entity_id == -1 || entity_id == _player_entity_id:
		return
	
	var direction: String = payload.get("direction", "")
	if direction.is_empty():
		return
	
	if _entities.has(entity_id):
		_entities[entity_id].change_direction(direction)

func _entity_attack(payload: Dictionary) -> void:
	var entity_id: int = payload.get("entity_id", -1)
	if entity_id == -1 || entity_id == _player_entity_id:
		return
		
	var direction: String = payload.get("direction", "")
	if direction.is_empty():
		return
	
	if _entities.has(entity_id):
		_entities[entity_id].attack(direction)

func _entity_hurt(payload: Dictionary) -> void:
	var entity_id: int = payload.get("entity_id", -1)
	if entity_id == -1:
		return
	
	var damage: int = payload.get("damage", 0)
	
	if _entities.has(entity_id):
		_entities[entity_id].hurt(damage)

func _entity_leveled_up(payload: Dictionary) -> void:
	var entity_id: int = payload.get("entity_id", -1)
	if entity_id == -1:
		return
	
	var level: int = payload.get("level", 0)
	
	if _entities.has(entity_id):
		_entities[entity_id].level_up(level)

@onready var _win_character: WindowBase = %WindowCharacter

func _on_panel_menubar_toggle_character() -> void:
	_win_character.visible = not _win_character.visible

func _on_window_character_close() -> void:
	_win_character.visible = false
