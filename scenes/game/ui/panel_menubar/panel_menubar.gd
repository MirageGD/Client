extends MarginContainer
class_name PanelMenubar

signal toggle_character

func _on_button_character_pressed() -> void:
	toggle_character.emit()
