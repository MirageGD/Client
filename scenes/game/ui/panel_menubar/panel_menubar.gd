extends MarginContainer
class_name PanelMenubar

signal toggle_character
signal toggle_inventory

func _on_button_character_pressed() -> void:
	toggle_character.emit()

func _on_button_inventory_pressed() -> void:
	toggle_inventory.emit()
