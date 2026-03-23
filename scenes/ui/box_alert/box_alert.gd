extends Control
class_name BoxAlert

@onready var _message: Label = %Message
@onready var _button: Button = %Button

@export var text: String = ""

func _ready() -> void:
	_message.text = text
	_button.grab_focus()

func _on_button_pressed() -> void:
	queue_free()
