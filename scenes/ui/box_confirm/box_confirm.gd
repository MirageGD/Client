extends Control
class_name BoxConfirm

signal accept
signal cancel

@onready var _message: Label = %Message
@onready var _button_accept: Button = %ButtonAccept
@onready var _button_cancel: Button = %ButtonCancel

@export var text: String = ""
@export var accept_text: String = "OK"
@export var cancel_text: String = "Cancel"

func _ready() -> void:
	_message.text = text
	_button_accept.text = accept_text
	_button_cancel.text = cancel_text
	_button_cancel.grab_focus()

func _on_button_accept_pressed() -> void:
	accept.emit()
	queue_free()

func _on_button_cancel_pressed() -> void:
	cancel.emit()
	queue_free()
