extends Control
class_name PanelVitals

@onready var _label_name: Label = %LabelName
@onready var _label_level: Label = %LabelLevel
@onready var _hp: ProgressBar = %HPProgressBar
@onready var _hp_label: Label = %HPLabel
@onready var _mp: ProgressBar = %MPProgressBar
@onready var _mp_label: Label = %MPLabel
@onready var _xp: ProgressBar = %XPProgressBar
@onready var _xp_label: Label = %XPLabel

var _player_entity_id: int = -1

func _ready() -> void:
	SignalBus.map_init.connect(_map_init)
	SignalBus.entity_joined.connect(_entity_joined)
	SignalBus.entity_health.connect(_entity_health)
	SignalBus.entity_hurt.connect(_entity_hurt)
	SignalBus.entity_leveled_up.connect(_entity_leveled_up)
	SignalBus.player_xp.connect(_player_xp)

func _map_init(payload: Dictionary) -> void:
	_player_entity_id = payload.get("player_entity_id", -1)

func _entity_joined(payload: Dictionary) -> void:
	var entity_id: int = payload.get("entity_id", -1)
	if entity_id != _player_entity_id:
		return
	
	var character_name: String = payload.get("name", "")
	var level: int = payload.get("level", 1)
	var max_health: int = payload.get("max_health", 0)
	var max_mana: int = payload.get("max_mana", 0)
	var health: int = payload.get("health", 0)
	var mana: int = payload.get("mana", 0)
	
	_label_name.text = character_name
	_label_level.text = _format_level(level)
	
	_update_health(health, max_health)
	_update_mana(mana, max_mana)

func _entity_health(payload: Dictionary) -> void:
	var entity_id: int = payload.get("entity_id", -1)
	if entity_id != _player_entity_id:
		return
	
	var max_health: int = payload.get("max_health", 0)
	var health: int = payload.get("health", 0)
	
	_update_health(health, max_health)

func _entity_hurt(payload: Dictionary) -> void:
	var entity_id: int = payload.get("entity_id", -1)
	if entity_id != _player_entity_id:
		return
	
	var max_health: int = payload.get("max_health", 0)
	var health: int = payload.get("health", 0)
	
	_update_health(health, max_health)

func _entity_leveled_up(payload: Dictionary) -> void:
	var entity_id: int = payload.get("entity_id", -1)
	if entity_id != _player_entity_id:
		return
	
	var level = payload.get("level", 1)
	var max_health: int = payload.get("max_health", 0)
	var health: int = payload.get("health", 0)
	
	_label_level.text = _format_level(level)
	
	_update_health(health, max_health)
	
func _player_xp(payload: Dictionary) -> void:
	var xp_required: int = payload.get("xp_required", 0)
	var xp: int = payload.get("xp", 0)
	
	_update_experience(xp, xp_required)

func _format_level(level: int) -> String:
	return "Lv. %d" % level

func _update_health(health: int, max_health: int) -> void:
	_hp_label.text = "%d/%d" % [health, max_health]
	_hp.max_value = max_health
	_hp.value = health

func _update_mana(mana: int, max_mana: int) -> void:
	_mp_label.text = "%d/%d" % [mana, max_mana]
	_mp.max_value = max_mana
	_mp.value = mana

func _update_experience(xp: int, xp_required: int) -> void:
	_xp_label.text = "%d/%d" % [xp, xp_required]
	_xp.max_value = xp_required
	_xp.value = xp
