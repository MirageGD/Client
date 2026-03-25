extends VBoxContainer
class_name PlayerStats

@onready var _label_strength: Label = %LabelStrength
@onready var _label_stamina: Label = %LabelStamina
@onready var _label_intelligence: Label = %LabelIntelligence
@onready var _label_stat_points: Label = %LabelStatPoints
@onready var _button_strength: Button = %ButtonStrength
@onready var _button_stamina: Button = %ButtonStamina
@onready var _button_intelligence: Button = %ButtonIntelligence

func _ready() -> void:
	SignalBus.player_stats.connect(_player_stats)

func _player_stats(payload: Dictionary) -> void:
	var strength: int = payload.get("strength", 0)
	var stamina: int = payload.get("stamina", 0)
	var intelligence: int = payload.get("intelligence", 0)
	var stat_points: int = payload.get("stat_points", 0)
	
	_label_strength.text = str(strength)
	_label_stamina.text = str(stamina)
	_label_intelligence.text = str(intelligence)
	
	_show_stat_points(stat_points)

func _set_stat_buttons_state(has_stat_points: bool) -> void:
	_button_strength.disabled = not has_stat_points
	_button_stamina.disabled = not has_stat_points
	_button_intelligence.disabled = not has_stat_points

func _show_stat_points(stat_points: int) -> void:
	var has_stat_points := stat_points > 0
	
	_set_stat_buttons_state(has_stat_points)
	_label_stat_points.visible = has_stat_points
	
	if has_stat_points:
		var s := "point" if stat_points == 1 else "points"
		
		_label_stat_points.text = "You have %d %s to distribute" % [stat_points, s]

func _on_button_strength_pressed() -> void:
	Network.send_use_stat_point("strength")

func _on_button_stamina_pressed() -> void:
	Network.send_use_stat_point("stamina")

func _on_button_intelligence_pressed() -> void:
	Network.send_use_stat_point("intelligence")
