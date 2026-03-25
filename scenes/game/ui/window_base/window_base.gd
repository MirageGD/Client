extends PanelContainer
class_name WindowBase

signal close

@onready var _title_bar: PanelContainer = %Header
@onready var _title: Label = %Title
@onready var _button_close: Button = %ButtonClose

@export var title: String = "Window"
@export var closable := true

var _dragging := false
var _drag_offset := Vector2.ZERO

func _ready() -> void:
	_title.text = title
	_button_close.visible = closable

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			_dragging = false
			return
		
		var title_bar_rect := _title_bar.get_global_rect()
		if title_bar_rect.has_point(event.global_position):
			_dragging = true
			_drag_offset = global_position - event.global_position
	
	if event is InputEventMouseMotion and _dragging:
		global_position = event.global_position + _drag_offset

func _on_button_close_pressed() -> void:
	if closable:
		close.emit()
